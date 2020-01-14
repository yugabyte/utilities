#!/bin/bash
set -e -x
cd /opt/
rm -rf ./yugabyte/bin
rm -rf ./yugabyte/lib
rm -rf ./yugabyte/linuxbrew
rm -rf ./yugabyte/postgres
rm -rf ./yugabyte/pylib
rm -rf ./yugabyte/share
rm -rf ./yugabyte/ui
rm -rf ./yugabyte/www
rm -f ./yugabyte/yugabyted
rm -f /usr/bin/yugabyted
rm -f ./yugabyte/.post_install.sh.completed
if [ -L "/usr/bin/cqlsh" ] && [ -L "/usr/bin/ysqlsh" ]; then
    rm -f /usr/bin/cqlsh
    rm -f /usr/bin/ysqlsh
fi
