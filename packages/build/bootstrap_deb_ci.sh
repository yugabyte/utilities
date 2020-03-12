#!/usr/bin/env bash

set -x -o pipefail -o errexit

apt update
apt install wget curl time sudo -y
apt install rubygems ruby-dev gcc make -y

echo 'export GEM_HOME="${HOME}/.ruby/"' >> "${HOME}/.bashrc"
echo 'export PATH="$PATH:${HOME}/.ruby/bin"' >> "${HOME}/.bashrc"
source "${HOME}/.bashrc"

gem install --no-document fpm
fpm --version
