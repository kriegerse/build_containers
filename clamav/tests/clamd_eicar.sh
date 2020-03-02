#!/bin/bash
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
zypper --quiet -n --gpg-auto-import-keys refresh
zypper --quiet -n in curl socat

echo -e "\n* Waiting for clamd port ready"

COUNT=1
MAXCOUNT=60
SLEEPTIME=5

while [ ${COUNT} -lt $MAXCOUNT ]; do
  RESULT=$(echo 'PING' | socat - tcp4:${CLAMAV_PORT_3310_TCP_ADDR}:${CLAMAV_PORT_3310_TCP_PORT})

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


pushd clamav/tests > /dev/null

REMOTE_CONF='clamd.remote.conf'
echo -e "\n* Writing clamdscan config"
echo "TCPSocket ${CLAMAV_PORT_3310_TCP_PORT}" | tee -a ${REMOTE_CONF}
echo "TCPAddr ${CLAMAV_PORT_3310_TCP_ADDR}" | tee -a ${REMOTE_CONF}


echo -e "\n* Testing EICAR patterns"

# all eicar cases have to alert a virus!
for i in eicar.com eicar.com.txt eicar_com.zip eicarcom2.zip; do
  curl --silent -o "${i}" "https://secure.eicar.org/${i}"

  echo -e "\nScan local file ${i}"
  clamdscan -c ${REMOTE_CONF} "${i}"
  RESULT_CODE=$0

  if [ ${RESULT_CODE} -eq 1 ]; then
    echo "OKAY: VIRUS FOUND"
  elif [ ${RESULT_CODE} -eq 0 ]; then
    echo "ERROR: NO VIRUS FOUND!"
    exit 1
  else
    echo "ERROR: clamd reported error"
    exit 2
  fi


  echo -e "\nStreaming file ${i}"
  clamdscan -c ${REMOTE_CONF} --stream "${i}"
  RESULT_CODE=$0

  if [ ${RESULT_CODE} -eq 1 ]; then
    echo "OKAY: VIRUS FOUND"
  elif [ ${RESULT_CODE} -eq 0 ]; then
    echo "ERROR: NO VIRUS FOUND!"
    exit 1
  else
    echo "ERROR: clamd reported error"
    exit 2
  fi

  rm $i
done


echo -e "\n* Testing random NONE EICAR pattern"
# no VIRUS shall being reported!
RANDFILE=$(mktemp -p .)
dd if=/dev/urandom of=${RANDFILE} count=2 bs=1M status=none

echo -e "\nScan local file ${RANDFILE}"
clamdscan -c ${REMOTE_CONF} ${RANDFILE}

if [[ ${RESULT_CODE} -eq 1 ]]; then
  echo "ERROR: VIRUS FOUND!"
  exit 1
elif [[ ${RESULT_CODE} -eq 0 ]]; then
  echo "OKAY: NO VIRUS FOUND!"
else
  echo "ERROR: clamd reported error"
  exit 2
fi

popd > /dev/null
