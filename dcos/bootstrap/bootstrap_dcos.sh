#!/bin/bash

# CrateDB Configuration
COUNTER=0
CRATE_ENDPOINT="127.0.0.1"
CRATE_PORT="4200"

while :
do
  curl --silent http://$CRATE_ENDPOINT:$CRATE_PORT -o /dev/null
  RETVAL=$?
  [[ $RETVAL -eq 0 ]] && { break; }
  [[ $COUNTER -eq 60 ]] && { exit 1; } || { COUNTER=$(($COUNTER + 1)); }
  sleep 1
done

curl -sS -H 'Content-Type: application/json' \
    -X POST "$CRATE_ENDPOINT:$CRATE_PORT/_sql" \
    -d @./dcos/bootstrap/cratedb_prometheus_metrics_table_query.json \
    -o /dev/null

[[ $? -eq 0 ]] && { exit 0; } || { exit 1; }
