#!/usr/bin/env bash

# kill subsequent processes if the shell script is stopped
trap "kill -- -$$" EXIT

# Extract real clamav name in case the process is suffixed with _init
CLAM_NAME="${SUPERVISOR_PROCESS_NAME%_*}"

# check for check for individual user config in /data/conf/
if [[ -f "/data/conf/${CLAM_NAME}.conf" ]]; then
  echo "starting ${CLAM_NAME} with user config /data/conf/${CLAM_NAME}.conf"
  CLAM_CONFIG_PARAM="--config-file=/data/conf/${CLAM_NAME}.conf"
fi


# start the program
case "${SUPERVISOR_PROCESS_NAME}" in
  "freshclam_init")
    /usr/bin/freshclam --foreground "${CLAM_CONFIG_PARAM}"
    supervisorctl start clamav:*
    ;;
  "freshclam")
    /usr/bin/freshclam --daemon --foreground "${CLAM_CONFIG_PARAM}"
    ;;
  "clamd")
    /usr/sbin/clamd --foreground "${CLAM_CONFIG_PARAM}"
    ;;
esac
