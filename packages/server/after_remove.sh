#!/usr/bin/env bash

yugabytedb_path="/opt/yugabytedb"

# Delete the symlinks to client binaries only if those are point to
# server package

# cqlsh can be present as part of Cassandra package
if [ -x "/usr/bin/cqlsh" ] && [ ! -L "/usr/bin/cqlsh" ]; then
  echo "Not deleting existing cqlsh" 1>&2
elif [ "$(readlink '/usr/bin/cqlsh')" = "${yugabytedb_path}/bin/cqlsh" ]; then
  rm -f /usr/bin/cqlsh
fi

if [ "$(readlink '/usr/bin/ysqlsh')" = "${yugabytedb_path}/postgres/bin/ysqlsh" ]; then
  rm -f /usr/bin/ysqlsh
fi

rm -rf "${yugabytedb_path}"
rm -f /usr/bin/yugabyted
