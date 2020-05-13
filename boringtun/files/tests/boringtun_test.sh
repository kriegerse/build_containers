#!/usr/bin/env bash


# HELPER VARS
SCRIPT=$(readlink -f $0)
SCRIPTPATH=$(dirname $SCRIPT)
WG0="boringtun-node1"
WG1="boringtun-node2"
WGNETWORK="boringtun_nw"
WGVOLUME="boringtun_vol"
WGVOLUMEMNT="/etc/wireguard"
DOCKER_IMAGE="boringtun-stage"

# If not in CI use latest from production
if [[ ! "${CI}" == "true"  ]]; then
  docker_username="kriegerse"
  DOCKER_IMAGE="boringtun"
  BUILD_PRIMARY_TAG="latest"
fi


# fetch docker images
echo "========================================================================="
echo "Pulling docker image(s)"
echo "========================================================================="
echo "* Image: ${docker_username}/${DOCKER_IMAGE}:${BUILD_PRIMARY_TAG}"
docker pull ${docker_username}/${DOCKER_IMAGE}:${BUILD_PRIMARY_TAG}


echo "========================================================================="
echo "Create network ${WGNETWORK} for boringtun communication"
echo "========================================================================="
docker network create ${WGNETWORK}
docker network ls

echo "========================================================================="
echo "Create shared docker volume ${WGVOLUME} for data exchange"
echo "========================================================================="
docker volume create ${WGVOLUME}
docker volume ls

echo "========================================================================="
echo "Bootstrap ${WG0}"
echo "========================================================================="

echo "* Start Node ${WG0}"
docker run --rm -v ${WGVOLUME}:${WGVOLUMEMNT} \
   -v ${SCRIPTPATH}/boringtun_genconfig.sh:/usr/local/bin/boringtun_genconfig.sh \
   --hostname ${WG0} \
   --name ${WG0} \
   -e ${!WG0@}=${WG0} \
   -e ${!WG1@}=${WG1} \
   -e ${!WGVOLUMEMNT@}=${WGVOLUMEMNT} \
   --network ${WGNETWORK} \
   --cap-add=NET_ADMIN \
   --device /dev/net/tun:/dev/net/tun \
   -dt ${docker_username}/${DOCKER_IMAGE}:${BUILD_PRIMARY_TAG}\
   /bin/bash

echo "* Generating configs in ${WG0}"
docker exec -t ${WG0} /usr/local/bin/boringtun_genconfig.sh


echo "========================================================================="
echo "Bootstrap ${WG1}"
echo "========================================================================="

echo "* Start Node ${WG1}"
docker run --rm -v ${WGVOLUME}:${WGVOLUMEMNT} \
   --hostname ${WG1} \
   --name ${WG1} \
   --network ${WGNETWORK} \
   --cap-add=NET_ADMIN \
   --device /dev/net/tun:/dev/net/tun \
   -dt ${docker_username}/${DOCKER_IMAGE}:${BUILD_PRIMARY_TAG}\
   /bin/bash


echo "========================================================================="
echo "Installing testing tools"
echo "========================================================================="

echo "* Install netcat iputils tar on ${WG0}"
docker exec -t ${WG0} zypper -n ref
docker exec -t ${WG0} zypper -v -n in iputils netcat tar

echo "* Install netcat iputils tar on ${WG1}"
docker exec -t ${WG1} zypper -n ref
docker exec -t ${WG1} zypper -v -n in iputils netcat tar


echo "========================================================================="
echo "Starting boringtun"
echo "========================================================================="

echo "* Starting boringtun on ${WG0}"
docker exec -t ${WG0} wg-quick up wg0

echo "* Starting boringtun on ${WG1}"
docker exec -t ${WG1} wg-quick up wg1

echo "* Waiting for establishing tunnel (sleep 15 seconds)"
docker exec -t ${WG1} /bin/sleep 15


################################################################################
echo "========================================================================="
echo "TEST: ping ${WG0} from ${WG1}"
echo "========================================================================="

docker exec -t ${WG1} ping -W10 -c10 10.0.0.1
RESCODE=$?

if [ $RESCODE -eq 0 ]; then
  echo OKAY: Reached ${WG0} from ${WG1}.""
else
  echo "ERROR: Couldn't reach ${WG0} from ${WG1}."
  exit 1
fi

echo "========================================================================="
echo "TEST: ping ${WG1} from ${WG0}"
echo "========================================================================="

docker exec -t ${WG0} ping -W10 -c10 10.0.0.2
RESCODE=$?

if [ $RESCODE -eq 0 ]; then
  echo OKAY: Reached ${WG1} from ${WG0}.""
else
  echo "ERROR: Couldn't reach ${WG1} from ${WG0}."
  exit 1
fi


echo "========================================================================="
echo "TEST: Simple file transfer with netcat from ${WG1} to ${WG0}"
echo "========================================================================="

echo "* Generating random data on ${WG1}"
docker exec -t ${WG1} dd if=/dev/urandom of=/tmp/${WG1}_randfile bs=1M count=10
RESCODE=$?

if [ $RESCODE -eq 0 ]; then
  echo "OKAY: Generated random data /tmp/${WG1}_randfile on ${WG1}."
else
  echo "ERROR: Couldn't generate random data on ${WG1}."
  exit 1
fi

echo "* Get checksum from random data on ${WG1}"
WG1CHKSUM=$(docker exec -t ${WG1} /bin/bash -c "md5sum /tmp/${WG1}_randfile | cut -d ' ' -f1 ")
RESCODE=$?

if [ $RESCODE -eq 0 ]; then
  echo "OKAY: Get checksum ${WG1CHKSUM} from /tmp/${WG1}_randfile on ${WG1}."
else
  echo "ERROR: Couldn't get checksum from /tmp/${WG1}_randfile on ${WG1}."
  exit 1
fi

echo "* Staring receiving netcat on ${WG0}"
docker exec -t ${WG0} /bin/bash -c "nc -l 10.0.0.1 -p 1234 | tar -P -xf - " &
RESCODE=$?

if [ $RESCODE -eq 0 ]; then
  echo "OKAY: Started netcat on ${WG0}."
else
  echo "ERROR: Couldn't start netcat on ${WG0}."
  exit 1
fi

echo "* Transfer /tmp/${WG1}_randfile from ${WG1} to ${WG0}"
docker exec -t ${WG1} /bin/bash -c "tar -P -cf - /tmp/${WG1}_randfile | nc 10.0.0.1 1234"
RESCODE=$?

if [ $RESCODE -eq 0 ]; then
  echo "OKAY: Transfered /tmp/${WG1}_randfile from ${WG1} to ${WG0}."
else
  echo "ERROR: Failed to transfer /tmp/${WG1}_randfile from ${WG1} to ${WG0}."
  exit 1
fi


echo "* Get checksum from transfered file on ${WG0}"
WG0CHKSUM=$(docker exec -t ${WG0} /bin/bash -c "md5sum /tmp/${WG1}_randfile | cut -d ' ' -f1 ")
RESCODE=$?

if [ $RESCODE -eq 0 ]; then
  echo "OKAY: Get checksum ${WG1CHKSUM} from /tmp/${WG1}_randfile on ${WG0}."
else
  echo "ERROR: Couldn't get checksum from /tmp/${WG1}_randfile on ${WG0}."
  exit 1
fi


echo "* Compare checksums"
if [ "${WG1CHKSUM}" == "${WG0CHKSUM}" ]; then
  echo "OKAY: Checksum ${WG1CHKSUM} on ${WG1} is the same as ${WG0CHKSUM} on ${WG0}."
else
  echo "ERROR: Checksum ${WG1CHKSUM} on ${WG1} is NOT the same as ${WG0CHKSUM} on ${WG0}."
  exit 1
fi

################################################################################
echo "========================================================================="
echo "Stats from boringtun"
echo "========================================================================="

echo "* Stats from ${WG0}"
docker exec -t ${WG0} wg
docker exec -t ${WG0} wg show wg0 transfer

echo "* Stats from ${WG1}"
docker exec -t ${WG1} wg
docker exec -t ${WG1} wg show wg1 transfer


echo "========================================================================="
echo "Stoping boringtun containers ${WG0} + ${WG1}"
echo "========================================================================="

docker stop ${WG0} ${WG1}
docker volume prune -f
docker network prune -f
