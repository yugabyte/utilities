#!/bin/bash

###############################################################################
#
# This is a simple script to install yugabyte-db software on a machine.
#
###############################################################################

YB_VERSION=$1
YB_HOME=/home/${USER}/yugabyte-db
YB_PACKAGE_URL="https://downloads.yugabyte.com/yugabyte-${YB_VERSION}-linux.tar.gz"
YB_PACKAGE_NAME="${YB_PACKAGE_URL##*/}"

###############################################################################
# Create the necessary directories.
###############################################################################
mkdir -p "${YB_HOME}/yb-software"
mkdir -p "${YB_HOME}/master"
mkdir -p "${YB_HOME}/tserver"

# Save the current directory.
pushd "${YB_HOME}"

###############################################################################
# Set appropriate ulimits according to https://docs.yugabyte.com/latest/deploy/manual-deployment/system-config/#setting-ulimits
###############################################################################
echo "Setting appropriate YB ulimits.."

cat > /tmp/99-yugabyte-limits.conf <<EOF
${USER}    soft    core      unlimited
${USER}    hard    core      unlimited
${USER}    soft    data      unlimited
${USER}    hard    data      unlimited
${USER}    soft    priority  0
${USER}    hard    priority  0
${USER}    soft    fsize	 unlimited
${USER}    hard    fsize	 unlimited
${USER}    soft    sigpending	119934
${USER}    hard    sigpending	119934
${USER}    soft    memlock	 64
${USER}    hard    memlock	 64
${USER}    soft    nofile	 1048576
${USER}    hard    nofile	 1048576
${USER}    soft    stack	 8192
${USER}    hard    stack	 8192
${USER}    soft    rtprio	 0
${USER}    hard    rtprio	 0
${USER}    soft    nproc	 12000
${USER}    hard    nproc	 12000
EOF

sudo cp /tmp/99-yugabyte-limits.conf /etc/security/limits.d/99-yugabyte-limits.conf

cat > /tmp/new-system-limits.conf <<EOF
*    soft    core      unlimited
*    hard    core      unlimited
*    soft    data      unlimited
*    hard    data      unlimited
*    soft    priority  0
*    hard    priority  0
*    soft    fsize     unlimited
*    hard    fsize     unlimited
*    soft    sigpending  119934
*    hard    sigpending  119934
*    soft    memlock   64
*    hard    memlock   64
*    soft    nofile    1048576
*    hard    nofile    1048576
*    soft    stack     8192
*    hard    stack     8192
*    soft    rtprio    0
*    hard    rtprio    0
*    soft    nproc     12000
*    hard    nproc     12000
EOF

sudo cp /tmp/new-system-limits.conf /etc/security/limits.conf

###############################################################################
# Download and install the software.
###############################################################################
echo "Fetching package $YB_PACKAGE_URL..."
wget -q "$YB_PACKAGE_URL"

echo "Extracting package..."
tar zxvf "${YB_PACKAGE_NAME}" > /dev/null

echo "Installing..."
mv "yugabyte-${YB_VERSION}" yb-software
yb-software/"yugabyte-${YB_VERSION}"/bin/post_install.sh 2>&1 > /dev/null


###############################################################################
# Install master.
###############################################################################
pushd master
for i in ../yb-software/"yugabyte-${YB_VERSION}"/*
do
  YB_TARGET_FILE="${i#../yb-software/yugabyte-${YB_VERSION}/}"
  if [[ ! -L "${YB_TARGET_FILE}" ]]; then
    ln -s "$i" > /dev/null
  else
    echo "rm -f ${YB_TARGET_FILE}" >> .master_relink
    echo "ln -s $i" >> .master_relink
  fi
done
mkdir -p conf
popd


###############################################################################
# Install tserver.
###############################################################################
pushd tserver
for i in ../yb-software/"yugabyte-${YB_VERSION}"/*
do
  YB_TARGET_FILE="${i#../yb-software/yugabyte-${YB_VERSION}/}"
  if [[ ! -L "${YB_TARGET_FILE}" ]]; then
    ln -s "$i" > /dev/null
  else
    echo "rm -f ${YB_TARGET_FILE}" >> .tserver_relink
    echo "ln -s $i" >> .tserver_relink
  fi
done
mkdir -p conf
popd


###############################################################################
# Create the data drives.
###############################################################################
# AWS: Available on the instances with NVMe based instance store
# disks. Example, m5d, i3.
if [[ -d "${YB_HOME}/data/ephemeral-nvme0" ]]; then
  data_dirs_list=""
  for data_dir in "${YB_HOME}/data/ephemeral-nvme"*; do
    if [[ -z "${data_dirs_list}" ]]; then
      data_dirs_list="${data_dir}"
    else
      data_dirs_list="${data_dirs_list},${data_dir}"
    fi
  done
else
  mkdir -p "${YB_HOME}/data/disk0"
  mkdir -p "${YB_HOME}/data/disk1"
  data_dirs_list="${YB_HOME}/data/disk0,${YB_HOME}/data/disk1"
fi

if [[ ! -f master/conf/server.conf ]]; then
  echo "--fs_data_dirs=${data_dirs_list}" >> master/conf/server.conf
fi
if [[ ! -f tserver/conf/server.conf ]]; then
  echo "--fs_data_dirs=${data_dirs_list}" >> tserver/conf/server.conf
fi
# Restore the original directory.
popd

###############################################################################
# Create an environment file
###############################################################################
echo "YB_HOME=${YB_HOME}" >> "${YB_HOME}/.yb_env.sh"
echo "export PATH=$PATH:${YB_HOME}/master/bin:${YB_HOME}/tserver/bin" >> "${YB_HOME}/.yb_env.sh"
echo "export YB_EDITION=${YB_VERSION}" >> "${YB_HOME}/.yb_env.sh"
echo "source ${YB_HOME}/.yb_env.sh" >> "/home/${USER}/.bash_profile"
chmod 755 "${YB_HOME}/.yb_env.sh"

