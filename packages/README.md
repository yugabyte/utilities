### This directory contains all types of YugabyteDB packages.

# How to build Deb and RPM package.

## Installing `fpm`
To build the deb and rpm package we are using a command-line utility
called `fpm` which is designed to help us to build a different kind of
packages.

### Debian / Ubuntu
To install `fpm` utility on a Debian-derived systems (Debian, Ubuntu,
etc)
- Install required packages
  ```console
  $ sudo apt install rubygems ruby-dev gcc make
  ```
- Add environment variables to `~/.bashrc`
  ```console
  $ echo 'export GEM_HOME="${HOME}/.ruby/"' >> "${HOME}/.bashrc"
  $ echo 'export PATH="$PATH:${HOME}/.ruby/bin"' >> "${HOME}/.bashrc"
  $ source "${HOME}/.bashrc"
  ```
- Install `fpm` utility
  ```console
  $ gem install --no-document fpm
  ```
- Check fpm version
  ```console
  $ fpm --version
  ```

### Fedora / CentOS
To install `fpm` utility on a RPM based systems (Fedora, CentOS, RHEL
etc)
- Install required packages
  ```console
  $ sudo yum install rubygems ruby-devel gcc redhat-rpm-config make rpm-build git
  ```
- Add environment variables to `~/.bashrc`
  ```console
  $ echo 'export PATH="$PATH:${HOME}/bin"' >> "${HOME}/.bashrc"
  $ source "${HOME}/.bashrc"
  ```
- Install `fpm` utility
  ```console
  $ gem install --no-document fpm
  ```
- Check fpm version
  ```console
  $ fpm --version
  ```

## Building the packages
> Note: We are building Debian packages on Debian systems and RPM
> packages on RPM based systems

To create the packages for YugabyteDB as well client
- Download the releases tar by running
  ```console
  $ make download
  ```

  It's possible to download specific version by exporting the variable
  `YB_VERSION` with desired version.
  ```console
  $ export YB_VERSION="2.0.11.0"
  $ make download
  …
  ```

### Debian packages
- Build the Debian packages for both server and client
     ```console
     $ make deb client_deb
     ```
  Packages should get created in the directory `build/apt/`.

### RPM packages
- Build the RPM packages for both server and client
     ```console
     $ make rpm client_rpm
     ```
  Packages should get created in the directory
  `build/yum/el7-x86_64/`.

## Creating the repositories out of packages
This section covers details about creating own package repositories
for above packages.

### Hosting RPM packages
- Install the createrepo tool
  ```console
  $ sudo yum install createrepo
  ```
- Run the createrepo inside build directory where all the `.rpm` files
  are present
  ```console
  $ ls -1 build/yum/el7-x86_64/
  yugabytedb-2.0.11.0-28.x86_64.rpm
  yugabytedb-2.0.11.0-29.x86_64.rpm
  yugabytedb-2.1.0.0-1.x86_64.rpm
  yugabytedb-client-2.0.11.0-10.x86_64.rpm
  yugabytedb-client-2.1.0.0-1.x86_64.rpm

  # Build the repository metadata
  $ createrepo build/yum/el7-x86_64/
  Directory walk started
  Directory walk done - 5 packages
  Loaded information about 5 packages
  Temporary output repo path: build/yum/el7-x86_64/.repodata/
  Preparing sqlite DBs
  Pool started (with 5 workers)
  Pool finished
  ```
- The whole `build/yum` directory can be synced with S3 or any other
  hosting. Make sure all the packages including the old ones are
  present in the `build/yum/el7-x86_64/` directory when running the
  `createrepo` command next time.
- To enable the newly created repository on a machine run the
  following command on the target machine.
  ```sh
  $ sudo tee -a /etc/yum.repos.d/yugabyte.repo << EOF
  [yugabyte]
  name=YugaByte
  baseurl=https://link-to-host.domain/yum/el7-x86_64
  enabled=1
  gpgcheck=0
  repo_gpgcheck=0
  EOF
  ```

### Hosting Debian packages
- Install the reprepro tool
  ```console
  $ sudo apt install reprepro
  ```
- Create a directory where the package repository will be created
  ```console
  $ mkdir -p build/apt/repo
  ```
- Create the repository configuration file
  ```console
  # Create the configuration directory
  $ mkdir -p build/apt/repo/conf
  ```
  ```sh
  # Create the configuration file
  $ cat << EOF > build/apt/repo/conf/distributions
  Origin: yugabyte
  Label: yugabyte
  Codename: yugabyte
  Architectures: amd64
  Components: main
  Description: Yugabyte APT repository
  EOF
  ```
- Run reprepro to include a `.deb` file to the APT repository
  directory i.e. `build/apt/repo/`
  ```console
  $ cd build/apt
  $ ls -1
  yugabytedb_2.1.2.0-4_amd64.deb
  …

  # Add the .deb file to the repository
  $ reprepro --basedir repo includedeb yugabyte yugabytedb_2.1.2.0-4_amd64.deb
  Exporting indices...

  $ ls -1 repo
  conf
  db
  dists
  pool
  ```
- The whole `build/apt/repo` directory can be synced with S3 or any
  other hosting. Make sure the `conf`, `db` and `dists` directories
  are present in `build/apt/repo` directory when running the `reprepro
  includedeb …` command on a new `.deb` file next time.
- To enable the newly created repository on a machine run the
  following command on the target machine.
  ```sh
  $ sudo tee -a /etc/apt/sources.list.d/yugabyte.list << EOF
  deb [trusted=yes] https://link-to-host.domain/apt yugabyte main
  EOF
  ```

## Updating the version and revision of a package
This section explains how to update package version as well as
revision in case of a new release. This applies to both Debian and RPM
packages.

### yugabytedb package
Variables from [`Makefile`](./Makefile) for server package
(`yugabytedb`),
- `YB_VERSION`: Version of YugabyteDB.
- `YB_SERVER_RPM_REVISION`: Revision for the RPM package.
- `YB_SERVER_DEB_REVISION`: Revision for the Debian package.

Updating the version or revision,
- Change in YugabyteDB version
  - Set the `YB_VERSION` from `Makefile` to the version of YugabyteDB.
  - Reset the revision of packages. Set value of
    `YB_SERVER_RPM_REVISION` and `YB_SERVER_DEB_REVISION` to `1`.
- Change in files from the [`server/`](./server/) directory
  - If the change is related both Debian and RPM packages, then
    increase the revision for both by one.
  - If the change affects only one of the Debian or RPM, then increase
    the respective revision value only.

### yugabytedb-client package
Variables from [`Makefile`](./Makefile) for client package
(`yugabytedb-client`),
- `YB_CLIENT_VERSION`: Version of YugabyteDB client tar.
- `YB_CLIENT_RPM_REVISION`: Revision for the RPM package.
- `YB_CLIENT_DEB_REVISION`: Revision for the Debian package.

Updating the version or revision,
- Change in YugabyteDB client tar version
  - Set the `YB_CLIENT_VERSION` from `Makefile` to the version of
    YugabyteDB client tar.
  - Reset the revision of packages. Set value of
    `YB_CLIENT_RPM_REVISION` and `YB_CLIENT_DEB_REVISION` to `1`.
- Change in files from the [`client/`](./client/) directory
  - If the change is related both Debian and RPM packages, then
    increase the revision for both by one.
  - If the change affects only one of the Debian or RPM, then increase
    the respective revision value only.
- New client tar with same version
  - Increase the revision for both Debian and RPM packages by one.
