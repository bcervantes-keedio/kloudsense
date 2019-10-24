#!/bin/bash

KS_HOME="."
source config/kloudsense.properties


INV_FILE=$KS_DCOS_INVENTORY_FILE


hosts=$(grep -v -e "^$" -e "^\[.*$" -e ".*ansible_connection.*" $INV_FILE | sort | uniq)

for host in ${hosts[@]}; do
  echo "Installing SSH-KEY in: $1@$host"
  ssh-copy-id -i ~/.ssh/id_rsa.pub $1@$host
  ssh-keyscan -H $host >> ~/.ssh/known_hosts
done
