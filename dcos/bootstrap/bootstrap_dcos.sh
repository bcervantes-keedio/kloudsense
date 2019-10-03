#!/bin/bash

# CrateDB Configuration
source $KS_HOME/ks_shell/environment
COUNTER=0
CRATE_ENDPOINT="127.0.0.1"
CRATE_PORT="4200"

_ks_info_msg "Creating CrateDB Data Tables"
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
    -d @./dcos/bootstrap/cratedb/tables/cratedb_prometheus_metrics_table_query.json \
    -o /dev/null
[[ $? -ne 0 ]] && { _ks_err_msg "Error while creating Prometheus Metrics Table"; exit 1; }



curl -sS -H 'Content-Type: application/json' \
    -X POST "$CRATE_ENDPOINT:$CRATE_PORT/_sql" \
    -d @./dcos/bootstrap/cratedb/tables/cratedb_syslog_system_messages_table_query.json \
    -o /dev/null
[[ $? -ne 0 ]] && { _ks_err_msg "Error while creating Syslog System Messages Tables"; exit 1; }



curl -sS -H 'Content-Type: application/json' \
    -X POST "$CRATE_ENDPOINT:$CRATE_PORT/_sql" \
    -d @./dcos/bootstrap/cratedb/tables/cratedb_syslog_system_messages_properties_table_query.json \
    -o /dev/null
[[ $? -ne 0 ]] && { _ks_err_msg "Error while creating Syslog System Messages Properties Table"; exit 1; }



curl -sS -H 'Content-Type: application/json' \
    -X POST "$CRATE_ENDPOINT:$CRATE_PORT/_sql" \
    -d @./dcos/bootstrap/cratedb/tables/cratedb_dcos_container_logs_table_query.json \
    -o /dev/null
[[ $? -ne 0 ]] && { _ks_err_msg "Error while creating DC/OS Containers Logs Table"; exit 1; }

_ks_ok_msg "CrateDB Tables created"
exit 0
