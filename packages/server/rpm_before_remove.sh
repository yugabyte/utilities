#!/usr/bin/env bash

# systemd unit section for rpm
# can be removed once https://github.com/jordansissel/fpm/issues/1163
# is closed
if [ "$(systemctl is-enabled yugabyted)" = "enabled" ]; then
  systemctl stop yugabyted
  systemctl disable yugabyted
  systemctl --system daemon-reload
fi
