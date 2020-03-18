yugabytedb_path="/opt/yugabytedb"
yugabytedb_client_path="/opt/yugabytedb-client"
yugabyte_user="yugabyte"
file_owner_string="${yugabyte_user} ${yugabyte_user}"
logdir="/var/log/yugabytedb"
datadir="/var/lib/yugabytedb"
configdir="/etc/yugabytedb"
ui_endpoint="http://localhost:7200"

Red="\e[31m"
Gre="\e[32m"
Blu="\e[34m"
RCol="\e[0m"

pass_count="0"
fail_count="0"

pass() {
  echo -e "${Gre}[PASS]${RCol} $@"
  ((pass_count++))
}

fail() {
  echo -e "${Red}[FAIL]${RCol} $@"
  ((fail_count++))
}

info() {
  echo -e "${Blu}[INFO]${RCol} $@"
}

# check_symlinks checks if the symlinks yugabyted, ysqlsh and cqlsh
# are pointing to correct locations
# argument 1: should_point_to: should be either 'server', 'client' or 'client_only'
#   'server': expects all the binaries to point to yugabytedb_path
#   'client': expects ysqlsh and cqlsh files to point to
#             yugabytedb_client_path and yugabyted to yugabytedb_path
#   'client_only': same as above but skips the check for yugabyted
check_symlinks() {
  should_point_to="$1"
  if [[ "${should_point_to}" == "server" ]]; then
    should_point_to_base="${yugabytedb_path}"
  elif [[ "${should_point_to}" == "client" || "${should_point_to}" == "client_only" ]]; then
    should_point_to_base="${yugabytedb_client_path}"
  else
    echo "check_symlinks: Invalid argument. Must be one of the 'server', 'client' or 'client_only'" 1>&2
    exit 1
  fi

  ysqlsh_path="$(which ysqlsh)"
  if [[ -n "${ysqlsh_path}" ]]; then
    ysqlsh_link="$(readlink ${ysqlsh_path})"
    if [[ "${ysqlsh_link}" != "${should_point_to_base}/postgres/bin/ysqlsh" ]]; then
      fail "check_symlinks: the symlink 'ysqlsh' points to '${ysqlsh_link}' instead of '${should_point_to_base}/postgres/bin/ysqlsh'."
    else
      pass "check_symlinks: the symlink 'cqlsh' points to '${should_point_to_base}/bin/cqlsh'."
    fi
  else
    fail "check_symlinks: the symlink 'ysqlsh' doesn't exist or isn't in the PATH."
  fi

  cqlsh_path="$(which cqlsh)"
  if [[ -n "${cqlsh_path}" ]]; then
    cqlsh_link="$(readlink ${cqlsh_path})"
    if [[ "${cqlsh_link}" != "${should_point_to_base}/bin/cqlsh" ]]; then
      fail "check_symlinks: the symlink 'cqlsh' points to '${cqlsh_link}' instead of '${should_point_to_base}/bin/cqlsh'."
    else
      pass "check_symlinks: the symlink 'cqlsh' points to '${should_point_to_base}/bin/cqlsh'."
    fi
  else
    fail "check_symlinks: the symlink 'cqlsh' doesn't exist or isn't in the PATH."
  fi

  if [[ "${should_point_to}" == "client_only" ]]; then
    info "check_symlinks: skipping check for 'yugabyted' as the input is client_only"
    return
  fi

  yugabyted_path="$(which yugabyted)"
  if [[ -n "${yugabyted_path}" ]]; then
    yugabyted_link="$(readlink ${yugabyted_path})"
    if [[ "${yugabyted_link}" != "${yugabytedb_path}/bin/yugabyted" ]]; then
      fail "check_symlinks: the symlink 'yugabyted' points to '${yugabyted_link}' instead of '${yugabytedb_path}/bin/yugabyted'."
    else
      pass "check_symlinks: the symlink 'yugabyted' points to '${yugabytedb_path}/bin/yugabyted'."
    fi
  else
    fail "check_symlinks: the symlink 'yugabyted' doesn't exist or isn't in the PATH."
  fi
}


# check_ownership checks file ownership for server package. This
# includes data, log and configuration directories
# TODO: should we have the client package's ownership check here?
check_ownership() {
  file_list="${yugabytedb_path} ${logdir} ${datadir} ${configdir} ${configdir}/yugabytedb.conf"
  for file in ${file_list}; do
    current_owner_string="$(stat -c "%U %G" "${file}")"
    if [[ "${current_owner_string}" == "${file_owner_string}" ]]; then
      pass "check_ownership: ${file}: user and group of the file are '${current_owner_string}'."
    else
      fail "check_ownership: ${file}: user and group of the file are '${current_owner_string}'. It must be '${file_owner_string}'."
    fi
  done
}

# check_systemd_service checks if the systemd service for yugabyted is
# enabled and active (running)
check_systemd_service() {
  is_enabled="$(systemctl is-enabled yugabyted)"
  if [[ "${is_enabled}" != "enabled" ]]; then
    fail "check_systemd_service: yugabyted service is '${is_enabled}'."
  else
    pass "check_systemd_service: yugabyted service is '${is_enabled}'."
  fi

  is_active="$(systemctl is-active yugabyted)"
  if [[ "${is_active}" != "active" ]]; then
    fail "check_systemd_service: yugabyted service is '${is_active}'."
  else
    pass "check_systemd_service: yugabyted service is '${is_active}'."
  fi
}

# check_ui queries UI endpoint and checks if it retruns 200 HTTP
# status code
check_ui() {
  info "check_ui: querying UI endpoint: '${ui_endpoint}'"
  curl_output_file="$(pwd)/check_ui-$(date +%s)"
  info "check_ui: writing the response body to '${curl_output_file}'"
  response="$(
    curl \
      --write-out %{http_code} \
      --silent --show-error \
      --output ${curl_output_file} \
      ${ui_endpoint}
  )"
  if [[ "${response}" == "200" ]]; then
    pass "check_ui: UI endpoint '${ui_endpoint}' returned: '${response}'."
  else
    fail "check_ui: UI endpoint '${ui_endpoint}' returned: '${response}', expected: '200'."
  fi
  if [[ -f "${curl_output_file}" ]]; then
    info "check_ui: contents of the response body:"
    cat "${curl_output_file}"
  fi
}

# usage prints the help text for the test script. This assumes that
# the only inputs are yugabytedb_version, server_revision,
# client_revision
# all arguments: message to user (optional): given arguments are printed as extra message for user
usage() {
  cat <<USAGE
$@

Usage ${script_name} -v yugabytedb_version -s server_revision -c client_revision

Run tests for given package. Options:
  -v: Version of YugabyteDB.
    Example: "-v 2.0.1.0"

  -s: Build revision of server package.
    Example: "-s 1", "-s 13"

  -c: Build revision of client package.
    Example: "-c 1", "-c 12"

  -h: Print help message.

USAGE

}

