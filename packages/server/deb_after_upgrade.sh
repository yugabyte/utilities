#!/usr/bin/env bash

yugabyte_user="yugabyte"
yugabytedb_path="/opt/yugabytedb"

chown -R "${yugabyte_user}:${yugabyte_user}" "${yugabytedb_path}"
# post_install.sh is required after upgrade of the package
if [ -f "${yugabytedb_path}/.post_install.sh.completed" ]; then
  rm "${yugabytedb_path}/.post_install.sh.completed"
fi
${yugabytedb_path}/bin/post_install.sh

# Handling the case where package is removed without --purge
## BEGIN
user_entry="$(getent passwd ${yugabyte_user})"
if [ -z "${user_entry}" ]; then
  useradd --system yugabyte
fi

yugabytedb_client_path="/opt/yugabytedb-client"
logdir="/var/log/yugabytedb"
datadir="/var/lib/yugabytedb"
configdir="/etc/yugabytedb"

# create /var/log/yugabytedb
mkdir -p "${logdir}"
chown "${yugabyte_user}:${yugabyte_user}" "${logdir}"

# create /var/lib/yugabytedb
mkdir -p "${datadir}"
chown "${yugabyte_user}:${yugabyte_user}" "${datadir}"

# config file from /etc
chown -R "${yugabyte_user}:${yugabyte_user}" "${configdir}"

# create symlink /usr/bin/yugabyted
if [ ! -L "/usr/bin/yugabyted" ]; then
  ln -s "${yugabytedb_path}/bin/yugabyted" "/usr/bin/yugabyted"
fi

# symlinks to client binaries
if [ "$(readlink '/usr/bin/cqlsh')" = "${yugabytedb_client_path}/bin/cqlsh" ] \
   && [ "$(readlink '/usr/bin/ysqlsh')" = "${yugabytedb_client_path}/postgres/bin/ysqlsh" ]; then
  echo "cqlsh and ysqlsh already exist and are poinint to binaries from yugabytedb-client package" 1>&2
else
  # cqlsh can be present as part of Cassandra package
  if [ -x "/usr/bin/cqlsh" ] && [ ! -L "/usr/bin/cqlsh" ]; then
    echo "Not replacing existing cqlsh" 1>&2
  elif [ ! -L "/usr/bin/cqlsh" ]; then
    ln -s "${yugabytedb_path}/bin/cqlsh" "/usr/bin/cqlsh"
  fi
  if [ ! -L "/usr/bin/ysqlsh" ]; then
    ln -s "${yugabytedb_path}/postgres/bin/ysqlsh" "/usr/bin/ysqlsh"
  fi
fi
## END
