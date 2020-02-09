### This directory contains all types of YugabyteDB packages.

# How to build Deb and RPM package.

## Installing `fpm`
To build the deb and rpm package we are using a command-line utility
called `fpm` which is designed to help us to build a different kind of
packages.

### Debian
To install `fpm` utility on a Debian-derived systems (Debian, Ubuntu,
etc)
- Install required packages
  ```
  $ sudo apt install rubygems ruby-dev gcc make
  ```
- Add environment variables to .bashrc
  ```
  echo 'export GEM_HOME="${HOME}/.ruby/"' >> "${HOME}/.bashrc"
  echo 'export PATH="$PATH:${HOME}/.ruby/bin"' >> "${HOME}/.bashrc"
  source "${HOME}/.bashrc"
  ```
- Install `fpm` utility
  ```
  $ gem install --no-document fpm
  ```
- Check fpm version
  ```
  $ fpm --version
  ```

### Fedora / CentOS and friends
To install `fpm` utility on a RPM based systems (Fedora, CentOS, RHEL
etc)
- Install required packages
  ```
  $ sudo yum install rubygems ruby-devel gcc redhat-rpm-config make rpm-build git
  ```
- Add environment variables to .bashrc
  ```
  echo 'export PATH="$PATH:${HOME}/bin"' >> "${HOME}/.bashrc"
  source "${HOME}/.bashrc"
  ```
- Install `fpm` utility
  ```
  $ gem install --no-document fpm
  ```
- Check fpm version
  ```
  $ fpm --version
  ```

## Building the packages
> Note: We are building Debian packages on Debian systems and RPM
> packages on RPM based systems

### Debian packages
To create Debian packages for YugabyteDB as well client
- Download the releases tar by running
  ```
  $ make download
  ```

  It's possible to download specific version by exporting the variable
  `YB_VERSION` with desired version.
  ```
  $ export YB_VERSION="2.0.11.0"
  $ make download
  …
  ```
 - Build the Debian packages for both server and client
	  ```
	  $ make deb client_deb
	  ```
   Packages should get created in the current directory.

### RPM packages
To create RPM packages for YugabyteDB as well client
- Download the releases tar by running
  ```
  $ make download
  ```

  It's possible to download specific version by exporting the variable
  `YB_VERSION` with desired version.
  ```
  $ export YB_VERSION="2.0.11.0"
  $ make download
  …
  ```
 - Build the RPM packages for both server and client
	  ```
	  $ make rpm client_rpm
	  ```
   Packages should get created in the current directory.
