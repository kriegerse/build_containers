#!/usr/bin/env bash

echo "=== clamd EICAR testing ==="

# echo "* Docker: pull image $docker_username/clamav-stage:$BUILD_PRIMARY_TAG"
# #docker pull $docker_username/clamav-stage:$BUILD_PRIMARY_TAG
#
# echo "* Docker start clamav-stage_$BUILD_PRIMARY_TAG"
# #docker run --network=bridge -d -P --name clamav-stage_$BUILD_PRIMARY_TAG $docker_username/clamav-stage:$BUILD_PRIMARY_TAG
#
# echo "* Docker: get clamd port mapping"
# export clamd_map_port=$(docker port clamav-stage_$BUILD_PRIMARY_TAG 3310/tcp | cut -d ':' -f 2)
# echo "port is ${clamd_map_port}"


echo -e "\n* Installing helper dependencies"
zypper -n --gpg-auto-import-keys refresh
zypper -n in curl socat

echo -e "\n* Waiting for clamd port ready"

COUNT=1
MAXCOUNT=60
SLEEPTIME=5

while [ ${COUNT} -lt $MAXCOUNT ]; do
  RESULT=$(echo 'PING' | socat - tcp4:${CLAMAV_PORT_3310_TCP_ADDR}:${CLAMAV_PORT_3310_TCP_PORT})
  # nc -n ${CLAMAV_PORT_3310_TCP_ADDR}:${CLAMAV_PORT_3310_TCP_PORT}


  if [[ "${RESULT}" == "PONG" ]]; then
    echo "Reached CLAMAV on ${CLAMAV_PORT_3310_TCP_ADDR}:${CLAMAV_PORT_3310_TCP_PORT}"
    echo "ANSWER: $RESULT"
    break
  elif [[ ${COUNT} -eq ${MAXCOUNT} ]]; then
    echo "Did no reach CLAMAV on ${CLAMAV_PORT_3310_TCP_ADDR}:${CLAMAV_PORT_3310_TCP_PORT}"
    echo "after $(( ${MAXCOUNT} * ${SLEEPTIME} )) seconds!"
    echo "FAILED!"
    exit 1
  else
    echo "Waiting for CLAMAV on ${CLAMAV_PORT_3310_TCP_ADDR}:${CLAMAV_PORT_3310_TCP_PORT}"
  fi

  COUNT=$(( $COUNT + 1 ))
  sleep ${SLEEPTIME}
done



# - docker ps -a
# - docker port clamav-stage_$BUILD_PRIMARY_TAG 3310/tcp
# - netstat -tulpn
# - which nc
# - ip a
# - export docker_port=$(docker port clamav-stage_$BUILD_PRIMARY_TAG
#   3310/tcp | cut -d ':' -f 2)
