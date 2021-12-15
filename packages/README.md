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
  $ export YB_RELEASE="2.11.0.0-b7"
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
