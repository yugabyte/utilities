#!/usr/bin/env bash

yugabytedb_path="/opt/yugabytedb"
yugabytedb_client_path="/opt/yugabytedb-client"

${yugabytedb_client_path}/bin/post_install.sh

# TODO: changing ownership of the files and creating the yugabyte user
# symlinks to client binaries
# Check if symlinks are pointing to binaries from yugabytedb package
if [ "$(readlink '/usr/bin/cqlsh')" = "${yugabytedb_path}/bin/cqlsh" ] \
   && [ "$(readlink '/usr/bin/ysqlsh')" = "${yugabytedb_path}/postgres/bin/ysqlsh" ]; then
  echo "cqlsh and ysqlsh will be pointing to binaries from yugabytedb-client package now."
  rm /usr/bin/cqlsh
  rm /usr/bin/ysqlsh
fi
# cqlsh can be present as part of Cassandra package
if [ -x "/usr/bin/cqlsh" ] && [ ! -L "/usr/bin/cqlsh" ]; then
  echo "Not replacing existing cqlsh" 1>&2
else
  ln -s "${yugabytedb_client_path}/bin/cqlsh" "/usr/bin/cqlsh"
fi
ln -s "${yugabytedb_client_path}/postgres/bin/ysqlsh" "/usr/bin/ysqlsh"
