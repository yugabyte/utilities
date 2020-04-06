#!/usr/bin/env bash

set -x -o pipefail -o errexit

yum install wget curl sudo which -y
yum install rubygems ruby-devel gcc redhat-rpm-config make rpm-build -y

echo 'export PATH="$PATH:${HOME}/bin"' >> "${HOME}/.bashrc"
source "${HOME}/.bashrc"

gem install --no-document fpm
fpm --version
