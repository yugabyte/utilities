
YB_RELEASE ?= 2.11.0.0-b7
YB_VERSION = $(word 1, $(subst -b, ,$(YB_RELEASE)))
YB_BUILD_NO = $(word 2, $(subst -b, ,$(YB_RELEASE)))
YB_CLIENT_VERSION ?= 2.6
ARCH ?= x86_64
SERVER_TAR_NAME = yugabyte-$(YB_VERSION)-b$(YB_BUILD_NO)-linux-$(ARCH).tar.gz
CLIENT_TAR_NAME = yugabyte-client-$(YB_CLIENT_VERSION)-linux.tar.gz
DOWNLOADS_BASE = https://downloads.yugabyte.com
SERVER_URL = $(DOWNLOADS_BASE)/releases/$(YB_VERSION)/$(SERVER_TAR_NAME)
CLIENT_URL = $(DOWNLOADS_BASE)/$(CLIENT_TAR_NAME)

YB_SERVER_RPM_REVISION = 2
YB_CLIENT_RPM_REVISION = 2
YB_SERVER_DEB_REVISION = 2
YB_CLIENT_DEB_REVISION = 2

EL_VERSION = 7
RPM_PACKAGE_PATH = build/yum/el$(EL_VERSION)-$(ARCH)/
DEB_PACKAGE_PATH = build/apt/

download:
	@echo "Downloading YugaByte release tars for the version $(YB_VERSION)"
	wget --progress "dot:giga" --directory-prefix "build" $(SERVER_URL)
	wget --progress "dot:giga" --directory-prefix "build" $(CLIENT_URL)

prepare:
	@echo "Creating target directories for the packages."
	mkdir -p $(RPM_PACKAGE_PATH)
	mkdir -p $(DEB_PACKAGE_PATH)

prepare_server: prepare
	@echo "Extracting the release tar '$(SERVER_TAR_NAME)' for server package."
	mkdir -p build/server-$(YB_VERSION)
	tar -xzf build/$(SERVER_TAR_NAME) -C build/server-$(YB_VERSION) --strip-components 1

rpm: prepare_server
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
	    --depends "python" \
	    --depends "procps-ng" \
	    --depends "java-headless = 1:1.8.0" \
	    "build/server-$(YB_VERSION)/=/opt/yugabytedb" \
	    "server/yugabytedb.conf=/etc/yugabytedb/" \
	    "server/yugabyted.service=/lib/systemd/system/"

prepare_client: prepare
	@echo "Extracting the release tar '$(CLIENT_TAR_NAME)' for client package."
	mkdir -p build/client-$(YB_CLIENT_VERSION)
	tar -xzf build/$(CLIENT_TAR_NAME) -C build/client-$(YB_CLIENT_VERSION) --strip-components 1

client_rpm: prepare_client
	@echo "Building RPM package for yugabytedb-client version '$(YB_CLIENT_VERSION)', revision '$(YB_CLIENT_RPM_REVISION)'"
	fpm \
	    --input-type "dir" \
	    --output-type "rpm" \
	    --name "yugabytedb-client" \
	    --version "$(YB_CLIENT_VERSION)" \
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
	    --depends "python" \
	    "build/client-$(YB_CLIENT_VERSION)/=/opt/yugabytedb-client"

test_rpm:
	@echo "Running tests for RPM. This may take upto 20 minutes."
	time bash tests/test_rpm_packages.sh \
            -V "$(YB_VERSION)" \
            -v "$(YB_CLIENT_VERSION)" \
            -s "$(YB_SERVER_RPM_REVISION)" \
            -c "$(YB_CLIENT_RPM_REVISION)"

deb: prepare_server
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
	    --depends "python" \
	    --depends "procps" \
	    --depends "default-jre" \
	    "build/server-$(YB_VERSION)/=/opt/yugabytedb" \
	    "server/yugabytedb.conf=/etc/yugabytedb/"

# Debian client uses after_install.sh for both install and upgrade
# scenarios
client_deb: prepare_client
	@echo "Building Debian package for yugabytedb-client version '$(YB_CLIENT_VERSION)', revision '$(YB_CLIENT_DEB_REVISION)'"
	fpm \
	    --input-type "dir" \
	    --output-type "deb" \
	    --name "yugabytedb-client" \
	    --version "$(YB_CLIENT_VERSION)" \
	    --before-upgrade "client/before_upgrade.sh" \
	    --after-upgrade "client/after_install.sh" \
	    --after-install "client/after_install.sh" \
	    --after-remove "client/after_remove.sh" \
	    --url "https://www.yugabyte.com/" \
	    --maintainer "YugaByte" \
	    --iteration "$(YB_CLIENT_DEB_REVISION)" \
	    --package "$(DEB_PACKAGE_PATH)" \
	    --architecture "$(ARCH)" \
	    --depends "python" \
	    "build/client-$(YB_CLIENT_VERSION)/=/opt/yugabytedb-client"

test_deb:
	@echo "Running tests for Debian. This may take upto 20 minutes."
	time bash tests/test_deb_packages.sh \
            -V "$(YB_VERSION)" \
            -v "$(YB_CLIENT_VERSION)" \
            -s "$(YB_SERVER_DEB_REVISION)" \
            -c "$(YB_CLIENT_DEB_REVISION)"
