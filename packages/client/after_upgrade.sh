#!/usr/bin/env bash

yugabytedb_client_path="/opt/yugabytedb-client"

# TODO: changing ownership of the files? check post_install.sh as well
# post_install.sh is required after upgrade of the package
if [ -f "${yugabytedb_client_path}/.post_install.sh.completed" ]; then
  rm "${yugabytedb_client_path}/.post_install.sh.completed"
fi

${yugabytedb_client_path}/bin/post_install.sh
