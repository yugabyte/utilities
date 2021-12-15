#!/usr/bin/env bash

set -x -o pipefail -o errexit

yum install wget curl sudo which -y
yum install rubygems ruby-devel gcc redhat-rpm-config make rpm-build -y

echo 'export PATH="$PATH:${HOME}/bin"' >> "${HOME}/.bashrc"
source "${HOME}/.bashrc"

gem install --no-document git:'<1.8.0' fpm
fpm --version
