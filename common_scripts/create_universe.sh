#!/bin/bash

###############################################################################
#
# This script configures a list of nodes and creates a universe.
#
# Usage:
#   create_universe.sh <cloud_name> <region> <rf> <config ips> <zones> \
#     <instance zone> <user>
#       <config ips> : space separated set of ips the nodes should use to talk
#                      to each other
###############################################################################


# Get the name of the cloud
CLOUD_NAME=$1

# Get the region name
REGION=$2

# Get the replication factor.
RF=$3
echo "Replication factor: $RF"

# Get the list of nodes (ips) used for intra-cluster communication.
NODES=$4
echo "Creating universe with nodes: [$NODES]"
IFS=" " read -r -a node_array <<< "$NODES"

if [[ "${CLOUD_NAME}" == "AWS" ]]; then
  # Get the AZ for the nodes.
  ZONES=$5
  echo "Creating universe in AZ's: [$ZONES]"
  IFS=" " read -r -a zone_array <<< "$ZONES"
  
  ZONES=$(echo "${ZONES}" | tr ' ' '\n' | sort -u | tr '\n' ' ')
  echo "Using zones: [ $ZONES ] and zone_array [ ${zone_array[*]} ]"
  
  INSTANCE_ZONE=${6}
  SSH_USER=${7}
else 
  INSTANCE_ZONE=${5}
  SSH_USER=${6}
fi

case "${CLOUD_NAME}" in

  'AWS')
    NODEIP="$(curl http://169.254.169.254/latest/meta-data/local-ipv4)"
    ;;

  'Azure')
    NODEIP="$(curl -H Metadata:true "http://169.254.169.254/metadata/instance/network/interface/0/ipv4/ipAddress/0/privateIpAddress?api-version=2017-08-01&format=text")"
    ;;

  'GCP')
    NODEIP="$(curl http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/ip -H "Metadata-Flavor: Google")"
    ;;

  *)
    echo "Invalid Cloud Name"
    exit 1
    ;;
esac

YB_HOME="/home/$SSH_USER/yugabyte-db"
YB_MASTER_ADDRESSES=""

idx=0
declare -a master_ips
###############################################################################
# Pick the masters as per the replication factor.
###############################################################################
used_zones=""

function add_master_ip() {
  if [ -n "${YB_MASTER_ADDRESSES}" ]; then
    YB_MASTER_ADDRESSES="$YB_MASTER_ADDRESSES,"
  fi
  YB_MASTER_ADDRESSES="$YB_MASTER_ADDRESSES${node_array[$1]}:7100"
  master_ips+=(${node_array[$1]})
}

if [[ "${CLOUD_NAME}" == "AWS" ]]; then
  # Pick node's IP from every zone to ensure a master per zone
  # Necessary Condition for a master per zone
  # 1. RF must be greater than or equal to Zones.
  for node_index in "${!zone_array[@]}"; do
    if (( idx < RF )); then
      if [[ "${used_zones}" == *"${zone_array[$node_index]}"* ]]; then
        continue
      fi
  
      add_master_ip "${node_index}"
  
      idx=$(( idx + 1 ))
      used_zones="$used_zones ${zone_array[$node_index]}"
    fi
  done
  
  # Pick node's IP and add, to ensure RF = Number of master
  # If RF > Number of Zones
  while (( RF - idx > 0 ))
  do
    for node_index in "${!node_array[@]}"; do
      if ! [[ "${master_ips[*]}" == *"${node_array[$node_index]}"* ]]; then
        add_master_ip "${node_index}"
        break
      fi
    done
  
    idx=$(( idx + 1 ))
  done
else
  for node_index in "${!node_array[@]}"; do
    if (( idx < RF )); then
      add_master_ip "${node_index}"
    fi
    idx=$(( idx + 1 ))
  done
fi

echo "Master addresses: $YB_MASTER_ADDRESSES"


###############################################################################
# Setup master addresses across all the nodes.
###############################################################################
echo "Finalizing configuration..."
echo "--master_addresses=${YB_MASTER_ADDRESSES}" >> "${YB_HOME}/master/conf/server.conf"
echo "--tserver_master_addrs=${YB_MASTER_ADDRESSES}" >> "${YB_HOME}/tserver/conf/server.conf"
echo "--replication_factor=${RF}" >> "${YB_HOME}/master/conf/server.conf"
echo "--replication_factor=${RF}" >> "${YB_HOME}/tserver/conf/server.conf"
echo "--default_memory_limit_to_ram_ratio=0.35" >> "${YB_HOME}/master/conf/server.conf"
echo "--default_memory_limit_to_ram_ratio=0.6" >> "${YB_HOME}/tserver/conf/server.conf"

###############################################################################
# Setup placement information if multi-AZ
###############################################################################

echo "Adding placement flag information ..."

echo "--placement_cloud=${CLOUD_NAME}" >> "${YB_HOME}/master/conf/server.conf"
echo "--placement_cloud=${CLOUD_NAME}" >> "${YB_HOME}/tserver/conf/server.conf"
echo "--placement_region=${REGION}" >> "${YB_HOME}/master/conf/server.conf"
echo "--placement_region=${REGION}" >> "${YB_HOME}/tserver/conf/server.conf"
echo "--placement_zone=${INSTANCE_ZONE}" >> "${YB_HOME}/master/conf/server.conf"
echo "--placement_zone=${INSTANCE_ZONE}" >> "${YB_HOME}/tserver/conf/server.conf"
echo "--use_initial_sys_catalog_snapshot" >> "${YB_HOME}/master/conf/server.conf"

###############################################################################
# Setup rpc_bind_addresses across all the nodes.
###############################################################################
echo "--rpc_bind_addresses=${NODEIP}:7100" >> "${YB_HOME}/master/conf/server.conf"
echo "--rpc_bind_addresses=${NODEIP}:9100" >> "${YB_HOME}/tserver/conf/server.conf"

###############################################################################
# Setup YSQL proxies across all nodes
###############################################################################
echo "Enabling YSQL..."
echo '--start_pgsql_proxy' >> "${YB_HOME}/tserver/conf/server.conf"
echo "--pgsql_proxy_bind_address=${NODEIP}:5433" >> "${YB_HOME}/tserver/conf/server.conf"

###############################################################################
# Start the masters.
###############################################################################
if [[ "${master_ips[*]}" == *"${NODEIP}"* ]]; then
  echo "Starting masters...${NODEIP}"
  MASTER_EXE=${YB_HOME}/master/bin/yb-master
  MASTER_OUT=${YB_HOME}/master/master.out
  MASTER_ERR=${YB_HOME}/master/master.err
  nohup "${MASTER_EXE}" --flagfile "${YB_HOME}/master/conf/server.conf" >>"${MASTER_OUT}" 2>>"${MASTER_ERR}" </dev/null &
    MASTER_CRON_OK="##";
    MASTER_CRON_OK+="$(crontab -l)";
    MASTER_CRON_PATTERN="start_master.sh"
    if [[ "$MASTER_CRON_OK" == *${MASTER_CRON_PATTERN}* ]]; then
      echo "Found master crontab entry at [${NODEIP}]"
    else
      crontab -l | { cat; echo "*/3 * * * * /home/${SSH_USER}/start_master.sh > /dev/null 2>&1"; } | crontab - 
      echo "Created master crontab entry at [${NODEIP}]"
    fi
fi

###############################################################################
# Start the tservers.
###############################################################################
echo "Starting tservers..."
echo "export YB_MASTER_ADDRESSES=${YB_MASTER_ADDRESSES}" >> "${YB_HOME}/.yb_env.sh"
TSERVER_EXE=${YB_HOME}/tserver/bin/yb-tserver
TSERVER_OUT=${YB_HOME}/tserver/tserver.out
TSERVER_ERR=${YB_HOME}/tserver/tserver.err

echo "Setting LANG and LC_* environment variables on all nodes"
echo -e 'export LC_ALL=en_US.utf-8 \nexport LANG=en_US.utf-8' > ~/env 
sudo mv ~/env /etc/environment
sudo chown root:root /etc/environment
sudo chmod 0644 /etc/environment
nohup "${TSERVER_EXE}" --flagfile "${YB_HOME}/tserver/conf/server.conf" >>"${TSERVER_OUT}" 2>>"${TSERVER_ERR}" </dev/null &

  TSERVER_CRON_OK="##";
  TSERVER_CRON_OK+="$(crontab -l)";
  TSERVER_CRON_PATTERN="start_tserver.sh"
  if [[ "$TSERVER_CRON_OK" == *${TSERVER_CRON_PATTERN}* ]]; then
     echo "Found tserver crontab entry at [${NODEIP}]"
  else
     crontab -l | { cat; echo "*/3 * * * * /home/${SSH_USER}/start_tserver.sh > /dev/null 2>&1"; } | crontab - 
     echo "Created tserver crontab entry at [${NODEIP}]"
  fi


