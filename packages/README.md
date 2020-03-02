### This directory contains all types of yugabyte packages.

# How to build Deb and RPM package.

To build the deb and rpm package we are using a command-line utility called `fpm` which is designed to help us to build a different kind of packages.

- Installing `fpm` utility on Debian-derived systems (Debian, Ubuntu, etc). 
   - Install pre required packages.
        ```
        $ apt-get install ruby ruby-dev rubygems build-essential
        ```
   - Install `fpm` utility.
        ```
        $ gem install --no-document fpm
        ```
   - Check `fpm` version
        ```
        $ fpm --version
        ```

- To create server Deb package for yugabyte 
  - First we will get the Yugabyte latest relese from its download [link](https://download.yugabyte.com/)
   - Now extract the downloaded package.
        ``` 
        $ tar xvf yugabyte-2.0.8.0-linux.tar.gz
        ```
   - Add some script required to configure yugabyte.
        ```
        $ cp script/install.sh yugabyte/
        $ cp script/uninstall.sh yugabyte/
        $ cp script/yugabyte yugabyte/
        $ cp -r script/etc yugabyte/
        ```
   - Now use the `fpm` comand line utiliy to create a deb package. 
        ```
        $ fpm -s dir -t deb -n yugabyte -v 2.0.5.2 --after-install yugabyte-2.0.5.2/install.sh --after-remove yugabyte-2.0.5.2/uninstall.sh --deb-init yugabyte-2.0.5.2/yugabyte --url https://www.yugabyte.com/ -m yugabye yugabyte-2.0.5.2=/opt
        ```
- TO create server rpm package for yugabyte
  - Extract the downloaded package.
        ``` 
        $ tar xvf yugabyte-2.0.8.0-linux.tar.gz
        ```
   - Add some script required to configure yugabyte.
        ```
        $ cp install.sh yugabyte/
        $ cp uninstall.sh yugabyte/
        ```
   - Now use the `fpm` comand line utiliy to create a deb package. 
        ```
        $ fpm --verbose -s dir -t rpm -n yugabytedb -v 2.0.8.0 --after-upgrade yugabyte/install.sh --before-upgrade upgrade.sh --after-install yugabyte/install.sh --after-remove yugabyte/uninstall.sh --url https://www.yugabyte.com/ -m Yugabyte yugabyte=/opt
        ```
- Convert deb package to rpm package.
   - To convert deb package to rpm package we will use `fpm` command.
        ```
        $ fpm --verbose -s deb -t rpm yugabyte_2.0.8.0_amd64.deb
        ```
   - To copnvert rpm to deb package 
        ```
        $ fpm --verbose -s rpm -t deb yugabyte_2.0.8.0_amd64.rpm
        ```
