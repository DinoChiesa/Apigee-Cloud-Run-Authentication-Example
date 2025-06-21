#!/bin/bash
# -*- mode:shell-script; coding:utf-8; -*-

source ./lib/utils.sh

check_required_commands curl
printf "\nThis script installs (or re-installs) apigeecli into \$HOME/.apigeecli/bin...\n"

curl -s https://raw.githubusercontent.com/apigee/apigeecli/main/downloadLatest.sh | bash
#export PATH=$PATH:$HOME/.apigeecli/bin
