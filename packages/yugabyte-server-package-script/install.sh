#!/bin/bash
set -x
USER=$(getent passwd yugabyte)

if [ "$USER" ]; then
  echo "Yugabyte user exists"
else
  useradd -r yugabyte
fi

set -e

if [ "$(readlink -- "/usr/bin/cqlsh")" = /opt/yugabyte-client/bin/cqlsh ] || [ "$(readlink -- "/usr/bin/ysqlsh")" = /opt/yugabyte-client/postgres/bin/ysqlsh ] ; then 
  if [ -d "/opt/yugabyte-cli/" ];then
    cd /opt
    chmod -R 775 ./yugabyte
    chown -R yugabyte:yugabyte ./yugabyte
    cd /opt/yugabyte/ || exit 1
    ./bin/post_install.sh
    mkdir -p /var/log/yugabyte/
    if [ ! -d "/etc/yugabyte" ]; then 
      mv /opt/yugabyte/etc/yugabyte /etc/
    else
      cd /opt/yugabyte && rm -rf etc
    fi
    ln -s /opt/yugabyte/yugabyted /usr/bin/yugabyted
  else
    cd /opt
    chmod -R 775 ./yugabyte
    chown -R yugabyte:yugabyte ./yugabyte
    cd /opt/yugabyte/ || exit 1
    ./bin/post_install.sh
    mkdir -p /var/log/yugabyte/
    if [ ! -d "/etc/yugabyte" ]; then 
      mv /opt/yugabyte/etc/yugabyte /etc/
    else
      cd /opt/yugabyte && rm -rf etc
    fi
    if [ -L "/usr/bin/yugabyted" ]; then 
      rm -f /usr/bin/yugabyted
    fi
    ln -s /opt/yugabyte/bin/yugabyted /usr/bin/yugabyted
    if [ -L "/usr/bin/cqlsh" ] && [ -L "/usr/bin/ysqlsh" ]; then
      rm -f /usr/bin/cqlsh
      rm -f /usr/bin/ysqlsh
    fi
    ln -s /opt/yugabyte/bin/cqlsh /usr/bin/cqlsh
    ln -s /opt/yugabyte/postgres/bin/ysqlsh /usr/bin/ysqlsh  
  fi
else
  cd /opt
  chmod -R 775 ./yugabyte
  chown -R yugabyte:yugabyte ./yugabyte
  cd /opt/yugabyte/ || exit 1
  ./bin/post_install.sh
  mkdir -p /var/log/yugabyte/
  if [ ! -d "/etc/yugabyte" ]; then 
    mv /opt/yugabyte/etc/yugabyte /etc/
  else
    cd /opt/yugabyte && rm -rf etc
  fi
  if [ -L "/usr/bin/yugabyted" ]; then 
    rm -f /usr/bin/yugabyted
  fi
  ln -s /opt/yugabyte/bin/yugabyted /usr/bin/yugabyted
  if [ -L "/usr/bin/cqlsh" ] && [ -L "/usr/bin/ysqlsh" ]; then
    rm -f /usr/bin/cqlsh
    rm -f /usr/bin/ysqlsh
  fi
  ln -s /opt/yugabyte/bin/cqlsh /usr/bin/cqlsh
  ln -s /opt/yugabyte/postgres/bin/ysqlsh /usr/bin/ysqlsh
fi
