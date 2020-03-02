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


echo "* Docker: waiting for clamd port ready"

count=0
while [ $count -lt 6 ]; do
  count=$(( $count + 1 ))
  docker exec -i clamav-stage_$BUILD_PRIMARY_TAG  supervisorctl status
  echo "** PING clamav port ${CLAMAV_PORT_3310_TCP_ADDR}:${CLAMAV_PORT_3310_TCP_PORT}"
  echo 'PING' | nc ${CLAMAV_PORT_3310_TCP_ADDR} ${CLAMAV_PORT_3310_TCP_PORT}
  sleep 10
done


# - docker ps -a
# - docker port clamav-stage_$BUILD_PRIMARY_TAG 3310/tcp
# - netstat -tulpn
# - which nc
# - ip a
# - export docker_port=$(docker port clamav-stage_$BUILD_PRIMARY_TAG
#   3310/tcp | cut -d ':' -f 2)
