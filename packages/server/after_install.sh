#!/usr/bin/env bash

# Create an user for yugabytedb
yugabyte_user="yugabyte"
user_entry="$(getent passwd ${yugabyte_user})"
if [ -z "${user_entry}" ]; then
  useradd --system yugabyte
fi

yugabytedb_path="/opt/yugabytedb"
yugabytedb_client_path="/opt/yugabytedb-client"
logdir="/var/log/yugabytedb"
datadir="/var/lib/yugabytedb"
configdir="/etc/yugabytedb"

chown -R "${yugabyte_user}:${yugabyte_user}" "${yugabytedb_path}"
${yugabytedb_path}/bin/post_install.sh

# create /var/log/yugabytedb
mkdir -p "${logdir}"
chown "${yugabyte_user}:${yugabyte_user}" "${logdir}"

# create /var/lib/yugabytedb
mkdir -p "${datadir}"
chown "${yugabyte_user}:${yugabyte_user}" "${datadir}"

# config file from /etc
chown -R "${yugabyte_user}:${yugabyte_user}" "${configdir}"

# create symlink /usr/bin/yugabyted
ln -s "${yugabytedb_path}/bin/yugabyted" "/usr/bin/yugabyted"

# symlinks to client binaries
if [ "$(readlink '/usr/bin/cqlsh')" = "${yugabytedb_client_path}/bin/cqlsh" ] \
   && [ "$(readlink '/usr/bin/ysqlsh')" = "${yugabytedb_client_path}/postgres/bin/ysqlsh" ]; then
  echo "cqlsh and ysqlsh already exist and are poinint to binaries from yugabytedb-client package" 1>&2
else
  # cqlsh can be present as part of Cassandra package
  if [ -x "/usr/bin/cqlsh" ] && [ ! -L "/usr/bin/cqlsh" ]; then
    echo "Not replacing existing cqlsh" 1>&2
  else
    ln -s "${yugabytedb_path}/bin/cqlsh" "/usr/bin/cqlsh"
  fi
  ln -s "${yugabytedb_path}/postgres/bin/ysqlsh" "/usr/bin/ysqlsh"
fi

# systemd unit section for rpm
# can be removed once https://github.com/jordansissel/fpm/issues/1163
# is closed
systemctl --system daemon-reload
if [ "$(systemctl is-enabled yugabyted)" = "disabled" ]; then
  systemctl enable yugabyted
  systemctl start yugabyted
fi
