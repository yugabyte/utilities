# Test scenarios for the packages

This document contains the list of scenarios and validation checks
which are implemented by the test scripts present in this
directory. Files with name `test_*.sh` are the test scripts.

### Validation checks
Validation checks are,
1. `check_symlinks`: checks if the symlinks from `/usb/bin` are
   pointing to crrect binaries from `/opt/`.
2. `check_ownership`: checks the group and user ownership of the
   various directories like data, log and configuration directories.
3. `check_systemd_service`: checks if systemd service of yugabyted is
   enabled and active.
4. `check_ysqlsh`: checks if data insertion and retrieval works. Uses
   `yugabyted demo` command.
5. `check_ui`: checks if UI returns HTTP response 200.

### List of tests
Each of the following test is followed by some or all validation
checks from above list.
- test 1
  install server

- test 2
  install client

- test 3
  install server
  install client

- test 4
  install client
  install server

- test 5
  install server
  install client
  remove server

- test 6
  install server
  install client
  remove client

It's possible to combine above tests while implementing (saves ~25m of
time)

- test 1, 3 and 5 can be combined
  install server -> test 1
  install client -> test 3
  remove server  -> test 5

- test 2, 4, 6 can be combined
  install client -> test 2
  install server -> test 4
  remove client  -> test 6

## How to run the tests
Make sure you follow the steps given
[here](../README.md#installing-fpm) to install `fpm` on your system.

### Debian packages
To run the tests on a Debian-derived system
- Install packages required for tests
  ```console
  $ sudo apt install wget curl time which
  ```
- Build the packages and run the tests
  ```console
  $ make download
  $ make deb client_deb
  $ make test_deb
  ```

### RPM packages
To run the tests on a RPM based system
- Install packages required for tests
  ```console
  $ sudo yum install wget curl time which
  ```
- Build the packages and run the tests
  ```console
  $ make download
  $ make rpm client_rpm
  $ make test_rpm
  ```
