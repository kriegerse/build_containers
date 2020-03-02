#!/usr/bin/env bash


echo "=== clamd EICAR testing ==="

echo "* Docker: pull image $docker_username/clamav-stage:$BUILD_PRIMARY_TAG"
docker pull $docker_username/clamav-stage:$BUILD_PRIMARY_TAG

echo "* Docker start clamav-stage_$BUILD_PRIMARY_TAG"
docker run -d -P --name clamav-stage_$BUILD_PRIMARY_TAG $docker_username/clamav-stage:$BUILD_PRIMARY_TAG

echo "* Docker: get clamd port mapping"
export clamd_map_port=$(docker port clamav-stage_$BUILD_PRIMARY_TAG 3310/tcp | cut -d ':' -f 2)
echo "port is ${clamd_map_port}"


echo "* Docker: waiting for clamd port ready"

ip a
hostname
docker info
docker network ls

count=0
while [ $count -lt 6 ]; do
  count=$(( $count + 1 ))
  docker exec -i clamav-stage_$BUILD_PRIMARY_TAG  supervisorctl status
  echo "PING localhost"
  echo "PING" | nc localhost ${clamd_map_port}
  echo "PING $HOSTNAME"
  echo "PING" | nc $HOSTNAME ${clamd_map_port}
  echo "PING dind-service"
  echo "PING" | nc dind-service ${clamd_map_port}
  sleep 10
done


# - docker ps -a
# - docker port clamav-stage_$BUILD_PRIMARY_TAG 3310/tcp
# - netstat -tulpn
# - which nc
# - ip a
# - export docker_port=$(docker port clamav-stage_$BUILD_PRIMARY_TAG
#   3310/tcp | cut -d ':' -f 2)
