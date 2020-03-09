
YB_VERSION ?= 2.1.0.0
TAR_NAME = yugabyte-$(YB_VERSION)-linux.tar.gz
DOWNLOAD_URL = "https://downloads.yugabyte.com/$(TAR_NAME)"

YB_SERVER_RPM_REVISION = 1
YB_CLIENT_RPM_REVISION = 1
YB_SERVER_DEB_REVISION = 1
YB_CLIENT_DEB_REVISION = 1

ARCH = x86_64
EL_VERSION = 7
RPM_PACKAGE_PATH = build/yum/el$(EL_VERSION)-$(ARCH)/
DEB_PACKAGE_PATH = build/apt/

download:
	@echo "Downloading YugaByte release tar for the version $(YB_VERSION)"
	wget --directory-prefix "build" $(DOWNLOAD_URL)

prepare:
	@echo "Extracting the release tar '$(TAR_NAME)'"
	mkdir -p $(RPM_PACKAGE_PATH)
	mkdir -p $(DEB_PACKAGE_PATH)
	tar -xvzf build/$(TAR_NAME) -C build

# prepare_server: prepare
# 	@echo "Preparing for server package."
# 	# cp -r server/etc build/yugabyte-$(YB_VERSION)/

rpm: prepare
	@echo "Building RPM package for yugabytedb version '$(YB_VERSION)', revision '$(YB_SERVER_RPM_REVISION)'"
	fpm \
	    --input-type "dir" \
	    --output-type "rpm" \
	    --name "yugabytedb" \
	    --version "$(YB_VERSION)" \
	    --before-upgrade "server/before_upgrade.sh" \
	    --after-upgrade "server/after_upgrade.sh" \
	    --after-install "server/after_install.sh" \
	    --before-remove "server/rpm_before_remove.sh" \
	    --after-remove "server/after_remove.sh" \
	    --url "https://www.yugabyte.com/" \
	    --maintainer "YugaByte" \
	    --iteration "$(YB_SERVER_RPM_REVISION)" \
	    --rpm-rpmbuild-define "_build_id_links none" \
	    --package "$(RPM_PACKAGE_PATH)" \
	    --architecture "$(ARCH)" \
	    --config-files "/etc/yugabytedb/yugabytedb.conf" \
	    "build/yugabyte-$(YB_VERSION)/=/opt/yugabytedb" \
	    "server/yugabytedb.conf=/etc/yugabytedb/" \
	    "server/yugabyted.service=/lib/systemd/system/"

# prepare_client_rpm: prepare
# 	@echo "Preparing for client package."

client_rpm: prepare
	@echo "Building RPM package for yugabytedb-client version '$(YB_VERSION)', revision '$(YB_SERVER_RPM_REVISION)'"
	fpm \
	    --input-type "dir" \
	    --output-type "rpm" \
	    --name "yugabytedb-client" \
	    --version "$(YB_VERSION)" \
	    --before-upgrade "client/before_upgrade.sh" \
	    --after-upgrade "client/after_upgrade.sh" \
	    --after-install "client/after_install.sh" \
	    --after-remove "client/after_remove.sh" \
	    --url "https://www.yugabyte.com/" \
	    --maintainer "YugaByte" \
	    --iteration "$(YB_CLIENT_RPM_REVISION)" \
	    --rpm-rpmbuild-define "_build_id_links none" \
	    --package "$(RPM_PACKAGE_PATH)" \
	    --architecture "$(ARCH)" \
	    "build/yugabyte-$(YB_VERSION)/=/opt/yugabytedb-client"

test_rpm:
	@echo "Running tests for RPM. This may take upto 20 minutes."
	time bash tests/test_rpm_packages.sh \
            -v "$(YB_VERSION)" \
            -s "$(YB_SERVER_RPM_REVISION)" \
            -c "$(YB_CLIENT_RPM_REVISION)"

deb: prepare
	@echo "Building Debian package for yugabytedb version '$(YB_VERSION)', revision '$(YB_SERVER_DEB_REVISION)'"
	fpm \
	    --input-type "dir" \
	    --output-type "deb" \
	    --name "yugabytedb" \
	    --version "$(YB_VERSION)" \
	    --before-upgrade "server/before_upgrade.sh" \
	    --after-upgrade "server/deb_after_upgrade.sh" \
	    --after-install "server/after_install.sh" \
	    --after-remove "server/after_remove.sh" \
	    --deb-systemd "server/yugabyted.service" \
	    --url "https://www.yugabyte.com/" \
	    --maintainer "YugaByte" \
	    --iteration "$(YB_SERVER_DEB_REVISION)" \
	    --package "$(DEB_PACKAGE_PATH)" \
	    --architecture "$(ARCH)" \
	    --config-files "/etc/yugabytedb/yugabytedb.conf" \
	    "build/yugabyte-$(YB_VERSION)/=/opt/yugabytedb" \
	    "server/yugabytedb.conf=/etc/yugabytedb/"

# Debian client uses after_install.sh for both install and upgrade
# scenarios
client_deb: prepare
	@echo "Building Debian package for yugabytedb-client version '$(YB_VERSION)', revision '$(YB_CLIENT_DEB_REVISION)'"
	fpm \
	    --input-type "dir" \
	    --output-type "deb" \
	    --name "yugabytedb-client" \
	    --version "$(YB_VERSION)" \
	    --before-upgrade "client/before_upgrade.sh" \
	    --after-upgrade "client/after_install.sh" \
	    --after-install "client/after_install.sh" \
	    --after-remove "client/after_remove.sh" \
	    --url "https://www.yugabyte.com/" \
	    --maintainer "YugaByte" \
	    --iteration "$(YB_CLIENT_DEB_REVISION)" \
	    --package "$(DEB_PACKAGE_PATH)" \
	    --architecture "$(ARCH)" \
	    "build/yugabyte-$(YB_VERSION)/=/opt/yugabytedb-client"

test_deb:
	@echo "Running tests for Debian. This may take upto 20 minutes."
	time bash tests/test_deb_packages.sh \
            -v "$(YB_VERSION)" \
            -s "$(YB_SERVER_DEB_REVISION)" \
            -c "$(YB_CLIENT_DEB_REVISION)"
