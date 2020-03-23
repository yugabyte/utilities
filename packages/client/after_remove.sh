#!/usr/bin/env bash

yugabytedb_path="/opt/yugabytedb"
yugabytedb_client_path="/opt/yugabytedb-client"

# cqlsh can be present as part of Cassandra package
if [ -x "/usr/bin/cqlsh" ] && [ ! -L "/usr/bin/cqlsh" ]; then
  echo "Not removing cqlsh as it seems to be part of some other package" 1>&2
else
  rm "/usr/bin/cqlsh"
fi
rm "/usr/bin/ysqlsh"

if [ -x "${yugabytedb_path}/bin/cqlsh" ] && [ -x "${yugabytedb_path}/postgres/bin/ysqlsh" ]; then
  # cqlsh can be present as part of Cassandra package
  if [ -x "/usr/bin/cqlsh" ] && [ ! -L "/usr/bin/cqlsh" ]; then
    echo "Not replacing existing cqlsh" 1>&2
  else
    ln -s "${yugabytedb_path}/bin/cqlsh" "/usr/bin/cqlsh"
  fi
  ln -s "${yugabytedb_path}/postgres/bin/ysqlsh" "/usr/bin/ysqlsh"
fi

# Clean up whole yugabytedb_client_path directory
rm -rf "${yugabytedb_client_path}"
