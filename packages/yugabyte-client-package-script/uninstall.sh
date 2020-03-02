#!/bin/bash
set -e -x
if [ "$(readlink -- "/usr/bin/cqlsh")" = /opt/yugabyte-client/bin/cqlsh ] || [ "$(readlink -- "/usr/bin/ysqlsh")" = /opt/yugabyte-client/postgres/bin/ysqlsh ] ; then
  if [ -d "/opt/yugabyte/" ]; then
     echo "You have installed Yugabyte Server Please uninstall it."
     rm /usr/bin/cqlsh
     rm /usr/bin/ysqlsh
     ln -s /opt/yugabyte/bin/cqlsh /usr/bin/cqlsh
     ln -s /opt/yugabyte/postgres/bin/ysqlsh /usr/bin/ysqlsh
   else
     rm /usr/bin/cqlsh
     rm /usr/bin/ysqlsh
   fi
fi
