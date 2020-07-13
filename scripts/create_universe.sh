#!/bin/bash

###############################################################################
#
# This script configures a list of nodes and creates a universe.
#
# Usage:
#   create_universe.sh <cloud_name> <region> <rf> <config ips> <ssh ips> \
#     <zones> <ssh user> <ssh-key file>
#       <config ips> : space separated set of ips the nodes should use to talk to
#                      each other
#       <ssh ips>    : space separated set of ips used to ssh to the nodes in
#                      order to configure them
#
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

# Get the list of ips to ssh to the corresponding nodes.
SSH_IPS=$5
echo "Connecting to nodes with ips: [$SSH_IPS]"

# Get the list of AZs for the nodes.
ZONES=$6
IFS=" " read -r -a zone_array <<< "$ZONES"
ZONES=$(echo "${ZONES}" | tr ' ' '\n' | sort -u | tr '\n' ' ')
echo "Using zones: [ $ZONES ] and zone_array [ ${zone_array[*]} ]"

# Get the credentials to connect to the nodes.
SSH_USER=$7
SSH_KEY_PATH=$8
YB_HOME=/home/${SSH_USER}/yugabyte-db
YB_MASTER_ADDRESSES=""

num_zones="$( (IFS=$'\n';sort <<< "${zone_array[*]}") | uniq -c | wc -l )"
IFS=" " read -r -a SSH_IPS_array <<< "$SSH_IPS"

# Error out if we do not have sufficient nodes.
if (( ${#SSH_IPS_array[@]} < RF )); then
  echo "Error: insufficient nodes: got ${#SSH_IPS_array[@]} node(s) but rf=$RF"
  exit 1
fi

idx=0
master_ips=""
###############################################################################
# Pick the masters as per the replication factor.
###############################################################################

used_zones=""
IFS=" " read -r -a node_array <<< "$NODES"

function add_master_ip() {
  if [ -n "${YB_MASTER_ADDRESSES}" ]; then
    YB_MASTER_ADDRESSES="$YB_MASTER_ADDRESSES,"
  fi
  YB_MASTER_ADDRESSES="$YB_MASTER_ADDRESSES${node_array[$1]}:7100"
  SSH_MASTER_IPS="$SSH_MASTER_IPS ${SSH_IPS_array[$1]}"
  master_ips="$master_ips ${node_array[$1]}"
}

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
    if ! [[ "${SSH_MASTER_IPS}" == *"${SSH_IPS_array[$node_index]}"* ]]; then
      add_master_ip "${node_index}"
      break
    fi
  done

  idx=$(( idx + 1 ))
done

echo "Master addresses: $YB_MASTER_ADDRESSES"
IFS=" " read -r -a MASTER_ADDR_ARRAY <<< "$master_ips"

# Error out if number of AZ's is not 1 but not equal to RF
if (( num_zones > 1 )); then
  echo "Multi AZ placement detected. Nodes in ${zone_array[*]}"
else
  echo "Single AZ placement detected - all nodes in ${zone_array[0]}"
fi

###############################################################################
# Setup master addresses across all the nodes.
###############################################################################
echo "Finalizing configuration..."
TIMESTAMP=$(date +%s)
ARCHIVE_MASTER_CONF="mv ${YB_HOME}/master/conf/server.conf ${YB_HOME}/master/conf/server.conf.${TIMESTAMP}"
ARCHIVE_TSERVER_CONF="mv ${YB_HOME}/tserver/conf/server.conf ${YB_HOME}/tserver/conf/server.conf.${TIMESTAMP}"
MASTER_DATA_DIRS_CMD="echo '--fs_data_dirs=${YB_HOME}/data/disk0,${YB_HOME}/data/disk1' >> ${YB_HOME}/master/conf/server.conf"
TSERVER_DATA_DIRS_CMD="echo '--fs_data_dirs=${YB_HOME}/data/disk0,${YB_HOME}/data/disk1' >> ${YB_HOME}/tserver/conf/server.conf"
MASTER_CONF_CMD="echo '--master_addresses=${YB_MASTER_ADDRESSES}' >> ${YB_HOME}/master/conf/server.conf"
TSERVER_CONF_CMD="echo '--tserver_master_addrs=${YB_MASTER_ADDRESSES}' >> ${YB_HOME}/tserver/conf/server.conf"
MASTER_CONF_RF_CMD="echo '--replication_factor=${RF}' >> ${YB_HOME}/master/conf/server.conf"
TSERVER_CONF_RF_CMD="echo '--replication_factor=${RF}' >> ${YB_HOME}/tserver/conf/server.conf"
MASTER_CONF_DB_INIT_CMD="echo '--use_initial_sys_catalog_snapshot' >> ${YB_HOME}/master/conf/server.conf"
MASTER_CONF_MEM_CMD="echo '--default_memory_limit_to_ram_ratio=0.35' >> ${YB_HOME}/master/conf/server.conf"
TSERVER_CONF_MEM_CMD="echo '--default_memory_limit_to_ram_ratio=0.6' >> ${YB_HOME}/tserver/conf/server.conf"

for node in $SSH_IPS; do
  ssh -q -o "StrictHostKeyChecking no" -i "${SSH_KEY_PATH}" \
    "${SSH_USER}"@"${node}" "$ARCHIVE_MASTER_CONF ; $ARCHIVE_TSERVER_CONF; \
    $MASTER_DATA_DIRS_CMD; $MASTER_CONF_CMD ; $TSERVER_DATA_DIRS_CMD; \
    $TSERVER_CONF_CMD ; $MASTER_CONF_RF_CMD ; $TSERVER_CONF_RF_CMD; \
    $MASTER_CONF_DB_INIT_CMD; $MASTER_CONF_MEM_CMD; $TSERVER_CONF_MEM_CMD;"
done

###############################################################################
# Setup placement information if multi-AZ
###############################################################################

echo "Adding placement flag information ... number of zones = ${num_zones}"

MASTER_CONF_CLOUDNAME="echo '--placement_cloud=${CLOUD_NAME}' >> ${YB_HOME}/master/conf/server.conf"
TSERVER_CONF_CLOUDNAME="echo '--placement_cloud=${CLOUD_NAME}' >> ${YB_HOME}/tserver/conf/server.conf"
MASTER_CONF_REGIONNAME="echo '--placement_region=${REGION}' >> ${YB_HOME}/master/conf/server.conf"
TSERVER_CONF_REGIONNAME="echo '--placement_region=${REGION}' >> ${YB_HOME}/tserver/conf/server.conf"
MASTER_CONF_INIT_DB="echo '--use_initial_sys_catalog_snapshot' >> ${YB_HOME}/master/conf/server.conf"
if [[ "${num_zones}" -eq  1 ]]; then
  MASTER_CONF_ZONENAME="echo '--placement_zone=${zone_array[0]}' >> ${YB_HOME}/master/conf/server.conf"
  TSERVER_CONF_ZONENAME="echo '--placement_zone=${zone_array[0]}' >> ${YB_HOME}/tserver/conf/server.conf"
fi

idx=0
for node in $SSH_IPS; do
  if [[ "${num_zones}" -gt 1 ]]; then
    echo "Using zone ${zone_array[idx]} for node $node"
    MASTER_CONF_ZONENAME="echo '--placement_zone=${zone_array[idx]}' >> ${YB_HOME}/master/conf/server.conf"
    TSERVER_CONF_ZONENAME="echo '--placement_zone=${zone_array[idx]}' >> ${YB_HOME}/tserver/conf/server.conf"
  fi
  ssh -q -o "StrictHostKeyChecking no" -i "${SSH_KEY_PATH}" \
    "${SSH_USER}"@"${node}" "$MASTER_CONF_CLOUDNAME ; $TSERVER_CONF_CLOUDNAME ; \
    $MASTER_CONF_REGIONNAME ; $TSERVER_CONF_REGIONNAME ; $MASTER_CONF_ZONENAME ; \
    $TSERVER_CONF_ZONENAME ; $MASTER_CONF_INIT_DB"
  idx=$(( idx + 1 ))
done

###############################################################################
# Setup YSQL proxies across all nodes
###############################################################################
echo "Enabling YSQL..."
TSERVER_YSQL_PROXY_CMD="echo '--start_pgsql_proxy' >> ${YB_HOME}/tserver/conf/server.conf"
node_idx=0
for node_idx in "${!SSH_IPS_array[@]}"; do
  TSERVER_PGSQL_PROXY="echo '--pgsql_proxy_bind_address=0.0.0.0:5433' >> ${YB_HOME}/tserver/conf/server.conf"
  TSERVER_CQL_PROXY="echo '--cql_proxy_bind_address=0.0.0.0:9042' >> ${YB_HOME}/tserver/conf/server.conf"
  ssh -q -o "StrictHostKeyChecking no" -i "${SSH_KEY_PATH}" \
    "${SSH_USER}"@"${SSH_IPS_array[$node_idx]}" "$TSERVER_YSQL_PROXY_CMD ; $TSERVER_PGSQL_PROXY ; $TSERVER_CQL_PROXY"
  node_idx=$(( node_idx + 1 ))
done

###############################################################################
# Setup rpc_bind_addresses across all the nodes.
###############################################################################
echo "Setting RPC Bind Address..."
node_idx=0
for node_idx in "${!SSH_IPS_array[@]}"; do
  MASTER_RPC_BINDADDR_CMD="echo '--rpc_bind_addresses=${node_array[$node_idx]}:7100' >> ${YB_HOME}/master/conf/server.conf"
  TSERVER_RPC_BINDADDR_CMD="echo '--rpc_bind_addresses=${node_array[$node_idx]}:9100' >> ${YB_HOME}/tserver/conf/server.conf"
  ssh -q -o "StrictHostKeyChecking no" -i "${SSH_KEY_PATH}" \
    "${SSH_USER}"@"${SSH_IPS_array[$node_idx]}" "$MASTER_RPC_BINDADDR_CMD ; $TSERVER_RPC_BINDADDR_CMD ; "
  node_idx=$(( node_idx + 1 ))
done


###############################################################################
# Start the masters.
###############################################################################
echo "Starting masters..."
MASTER_EXE=${YB_HOME}/master/bin/yb-master
MASTER_OUT=${YB_HOME}/master/master.out
MASTER_ERR=${YB_HOME}/master/master.err
MASTER_START_CMD="nohup ${MASTER_EXE} --flagfile ${YB_HOME}/master/conf/server.conf >>${MASTER_OUT} 2>>${MASTER_ERR} </dev/null &"
for node in $SSH_MASTER_IPS; do
  ssh -o "StrictHostKeyChecking no" -i "${SSH_KEY_PATH}" \
    "${SSH_USER}"@"${node}" "$MASTER_START_CMD"
  MASTER_CRON_OK="##";
  MASTER_CRON_OK+=$( ssh -o "StrictHostKeyChecking no" -i "${SSH_KEY_PATH}" "${SSH_USER}"@"${node}" 'crontab -l' );
  MASTER_CRON_PATTERN="start_master.sh"
  if [[ "$MASTER_CRON_OK" == *${MASTER_CRON_PATTERN}* ]]; then
     echo "Found master crontab entry at [$node]"
  else
     ssh -q -o "StrictHostKeyChecking no" -i "${SSH_KEY_PATH}" \
      "${SSH_USER}"@"${node}" "crontab -l | { cat; echo '*/3 * * * * /home/${SSH_USER}/start_master.sh > /dev/null 2>&1'; } | crontab - "
     echo "Created master crontab entry at [$node]"
  fi
done

###############################################################################
# Multi-AZ placement information.
###############################################################################
if [[ "${num_zones}" -gt 1 ]]; then
  echo "Modifying placement information to ensure 1 master per AZ..."
  PLACEMENT=""
  for zone_name in $ZONES; do
    if [ -n "${PLACEMENT}" ]; then
  	  PLACEMENT="$PLACEMENT,"
    fi
    PLACEMENT="${PLACEMENT}${CLOUD_NAME}.${REGION}.$zone_name"
    echo "Placement is $PLACEMENT"
  done
  echo "Setting placement to $PLACEMENT"
  PLACEMENT_CMD="${YB_HOME}/master/bin/yb-admin --master_addresses ${YB_MASTER_ADDRESSES} modify_placement_info ${PLACEMENT} ${RF}"
  ssh -q -o "StrictHostKeyChecking no" -i "${SSH_KEY_PATH}" \
    "${SSH_USER}"@"${SSH_IPS_array[0]}" "$PLACEMENT_CMD"
  echo "Placement modification complete."
fi

###############################################################################
# Start the tservers.
###############################################################################
echo "Starting tservers..."
TSERVER_YB_MASTER_ENV="echo 'export YB_MASTER_ADDRESSES=${YB_MASTER_ADDRESSES}' >> ${YB_HOME}/.yb_env.sh"
TSERVER_EXE=${YB_HOME}/tserver/bin/yb-tserver
TSERVER_OUT=${YB_HOME}/tserver/tserver.out
TSERVER_ERR=${YB_HOME}/tserver/tserver.err
TSERVER_START_CMD="nohup ${TSERVER_EXE} --flagfile ${YB_HOME}/tserver/conf/server.conf >>${TSERVER_OUT} 2>>${TSERVER_ERR} </dev/null &"
echo "Setting LANG and LC_* environment variables on all nodes"
TSERVER_SET_ENV_CMD="echo -e 'export LC_ALL=en_US.utf-8 \nexport LANG=en_US.utf-8' > ~/env; sudo mv ~/env /etc/environment; sudo chown root:root /etc/environment; sudo chmod 0644 /etc/environment"

for node in $SSH_IPS; do
  ssh -q -o "StrictHostKeyChecking no" -i "${SSH_KEY_PATH}" \
    "${SSH_USER}"@"${node}" "$TSERVER_SET_ENV_CMD"
  ssh -q -o "StrictHostKeyChecking no" -i "${SSH_KEY_PATH}" \
    "${SSH_USER}"@"${node}" "$TSERVER_YB_MASTER_ENV ; $TSERVER_START_CMD"
  TSERVER_CRON_OK="##";
  TSERVER_CRON_OK+=$( ssh -o "StrictHostKeyChecking no" -i "${SSH_KEY_PATH}" "${SSH_USER}"@"${node}" 'crontab -l' );
  TSERVER_CRON_PATTERN="start_tserver.sh"
  if [[ "$TSERVER_CRON_OK" == *${TSERVER_CRON_PATTERN}* ]]; then
    echo "Found tserver crontab entry at [$node]"
  else
    ssh -q -o "StrictHostKeyChecking no" -i "${SSH_KEY_PATH}" \
      "${SSH_USER}"@"${node}" "crontab -l | { cat; echo '*/3 * * * * /home/${SSH_USER}/start_tserver.sh > /dev/null 2>&1'; } | crontab - "
    echo "Created tserver crontab entry at [$node]"
  fi
done
