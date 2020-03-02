#!/bin/bash
set -e -x
if [ -d "/opt/yugabyte/" ]; then
  if [ -L "/usr/bin/cqlsh" ] && [ -L "/usr/bin/ysqlsh" ]; then
    rm -f /usr/bin/ysqlsh
    rm -f /usr/bin/cqlsh
    cd /opt/yugabyte-client/ || exit 1
    ./bin/post_install.sh
    ln -s /opt/yugabyte-client/bin/cqlsh /usr/bin/cqlsh
    ln -s /opt/yugabyte-client/postgres/bin/ysqlsh /usr/bin/ysqlsh
  else
    cd /opt/yugabyte-client/ || exit 1
    ./bin/post_install.sh
    ln -s /opt/yugabyte-client/bin/cqlsh /usr/bin/cqlsh
    ln -s /opt/yugabyte-client/postgres/bin/ysqlsh /usr/bin/ysqlsh
  fi
else
  cd /opt/yugabyte-client/ || exit 1
  ./bin/post_install.sh
  ln -s /opt/yugabyte-client/bin/cqlsh /usr/bin/cqlsh
  ln -s /opt/yugabyte-client/postgres/bin/ysqlsh /usr/bin/ysqlsh
fi
