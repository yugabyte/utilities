#!/usr/bin/env bash

yugabyte_user="yugabyte"
yugabytedb_path="/opt/yugabytedb"

chown -R "${yugabyte_user}:${yugabyte_user}" "${yugabytedb_path}"
# post_install.sh is required after upgrade of the package
if [ -f "${yugabytedb_path}/.post_install.sh.completed" ]; then
  rm "${yugabytedb_path}/.post_install.sh.completed"
fi
${yugabytedb_path}/bin/post_install.sh

# systemd unit section for rpm
# can be removed once https://github.com/jordansissel/fpm/issues/1163
# is closed
systemctl --system daemon-reload
if [ "$(systemctl is-enabled yugabyted)" = "enabled" ]; then
  systemctl restart yugabyted
fi
