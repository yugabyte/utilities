#!/usr/bin/env bash

script_name="$0"
script_basename="$(basename "${script_name}")"
script_dirname="$(dirname "${script_name}")"

source "${script_dirname}/utils.sh"

packagedir="$(pwd)/build/yum/el7-x86_64"

# remove uninstalls given package
# argument 1: package: should be either 'server' or 'client'
remove() {
  package="$1"
  info "remove: removing '${package}' package."
  if [[ "${package}" == "server" ]]; then
    sudo yum remove yugabytedb -y
  elif [[ "${package}" == "client" ]]; then
    sudo yum remove yugabytedb-client -y
  else
    echo "Invalid argument. Must be either 'server' or 'client'" 1>&2
    exit 1
  fi
  info "remove: removed '${package}' package."
}

# cleanup removes both client and server packages. It removes data,
# log as well as configuration directories. Deletes yugabyte_user
cleanup() {
  info "Running cleanup. This will remove client, server packages and other directories"
  remove "server"
  remove "client"
  sudo rm -rf "${datadir}"
  sudo rm -rf "${logdir}"
  sudo rm -rf "${configdir}"
  sudo userdel yugabyte
  info "cleanup: completed."
}

# install installs server or client package based on the global
# version, revision combination
# argument 1: package: should be either 'server' or 'client'
install(){
  package="$1"
  if [[ "${package}" == "server" ]]; then
    package_name="yugabytedb-${yugabytedb_version}-${yb_server_revision}.x86_64.rpm"
  elif [[ "${package}" == "client" ]]; then
    package_name="yugabytedb-client-${yugabytedb_client_version}-${yb_client_revision}.x86_64.rpm"
  else
    echo "install: Invalid argument. Must be either 'server' or 'client'" 1>&2
    exit 1
  fi
  info "install: installing '${package}: ${package_name}'."
  sudo yum install "${packagedir}/${package_name}" -y
  info "install: installed '${package}: ${package_name}'."
}


while getopts "V:v:s:c:h" opt; do
  case "${opt}" in
    V)
      yugabytedb_version="${OPTARG}"
      ;;
    v)
      yugabytedb_client_version="${OPTARG}"
      ;;
    s)
      yb_server_revision="${OPTARG}"
      ;;
    c)
      yb_client_revision="${OPTARG}"
      ;;
    h)
      usage
      exit
      ;;
    \?)
      usage
      exit
      ;;
  esac
done

if [[ -z "${yugabytedb_version}" || -z "${yugabytedb_client_version}" \
      || -z "${yb_server_revision}" || -z "${yb_client_revision}" ]]; then
  usage "Any of the 'yugabytedb_version', 'yugabytedb_client_version', \
'server_revision', 'client_revision' cannot be blank."
  exit 1
fi

cleanup

# START of test 1, 3, 5
install "server"
check_ownership
check_symlinks "server"
check_systemd_service
check_ui
check_ysqlsh

install "client"
check_ownership
check_symlinks "client"
check_systemd_service
check_ui
check_ysqlsh

remove "server" "--purge"
check_symlinks "client_only"
cleanup
# END of test 1, 3, 5

# START of test 2, 4, 6
install "client"
check_symlinks "client_only"

install "server"
check_ownership
check_symlinks "client"
check_systemd_service
check_ui
check_ysqlsh

remove "client" "--purge"
check_ownership
check_symlinks "server"
check_systemd_service
check_ui
check_ysqlsh
cleanup
# END of test 2, 4, 6

echo -e "Total tests passed: '${Gre}${pass_count}${RCol}'"
echo -e "Total tests failed: '${Red}${fail_count}${RCol}'"

if [[ "${fail_count}" -gt "0" ]]; then
  exit 1
else
  exit 0
fi

