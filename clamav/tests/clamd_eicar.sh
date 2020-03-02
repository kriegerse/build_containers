#!/usr/bin/env bash

echo "=== clamd EICAR testing ==="

echo -e "\n* Installing helper dependencies"
zypper --quiet -n --gpg-auto-import-keys refresh
zypper --quiet -n in curl socat

echo -e "\n* Waiting for clamd port ready"

COUNT=1
MAXCOUNT=60
SLEEPTIME=5

while [ ${COUNT} -lt $MAXCOUNT ]; do
  RESULT=$(echo 'PING' | socat - tcp4:"${CLAMAV_PORT_3310_TCP_ADDR}":"${CLAMAV_PORT_3310_TCP_PORT}")

  if [[ "${RESULT}" == "PONG" ]]; then
    echo "Reached CLAMAV on ${CLAMAV_PORT_3310_TCP_ADDR}:${CLAMAV_PORT_3310_TCP_PORT}"
    echo "ANSWER: $RESULT"
    break
  elif [[ "${COUNT}" -eq "${MAXCOUNT}" ]]; then
    echo "Did no reach CLAMAV on ${CLAMAV_PORT_3310_TCP_ADDR}:${CLAMAV_PORT_3310_TCP_PORT}"
    echo "after $(( MAXCOUNT * SLEEPTIME )) seconds!"
    echo "FAILED!"
    exit 1
  else
    echo "Waiting for CLAMAV on ${CLAMAV_PORT_3310_TCP_ADDR}:${CLAMAV_PORT_3310_TCP_PORT}"
  fi

  COUNT=$(( COUNT + 1 ))
  sleep ${SLEEPTIME}
done


echo -e "\n* Writing clamdscan config"

pushd clamav/tests > /dev/null
REMOTE_CONF='clamd.remote.conf'
echo "TCPSocket ${CLAMAV_PORT_3310_TCP_PORT}" | tee -a ${REMOTE_CONF}
echo "TCPAddr ${CLAMAV_PORT_3310_TCP_ADDR}" | tee -a ${REMOTE_CONF}

# all eicar cases have to alert a virus!
echo -e "\n* Testing EICAR patterns"
for i in eicar.com eicar.com.txt eicar_com.zip eicarcom2.zip; do
  curl --silent -o "${i}" "https://secure.eicar.org/${i}"

  echo -e "\nScan local file ${i}"
  clamdscan -c ${REMOTE_CONF} "${i}"
  RESULT_CODE=$?

  if [[ "${RESULT_CODE}" -eq 1 ]]; then
    echo "OKAY: VIRUS FOUND"
  elif [[ "${RESULT_CODE}" -eq 0 ]]; then
    echo "ERROR: NO VIRUS FOUND!"
    exit 1
  else
    echo "ERROR: clamd reported error"
    exit 2
  fi


  echo -e "\nStreaming file ${i}"
  clamdscan -c ${REMOTE_CONF} --stream "${i}"
  RESULT_CODE=$?

  if [ "${RESULT_CODE}" -eq 1 ]; then
    echo "OKAY: VIRUS FOUND"
  elif [ "${RESULT_CODE}" -eq 0 ]; then
    echo "ERROR: NO VIRUS FOUND!"
    exit 1
  else
    echo "ERROR: clamd reported error"
    exit 2
  fi

  rm $i
done

# no VIRUS shall being reported!
echo -e "\n* Testing random NONE EICAR pattern"
RANDFILE=$(mktemp -p .)
dd if=/dev/urandom of="${RANDFILE}" count=2 bs=1M status=none

echo -e "\nScan local file ${RANDFILE}"
clamdscan -c ${REMOTE_CONF} "${RANDFILE}"
RESULT_CODE=$?

if [[ ${RESULT_CODE} -eq 1 ]]; then
  echo "ERROR: VIRUS FOUND!"
  exit 1
elif [[ ${RESULT_CODE} -eq 0 ]]; then
  echo "OKAY: NO VIRUS FOUND!"
else
  echo "ERROR: clamd reported error"
  exit 2
fi

echo -e "\nStreaming file ${RANDFILE}"
clamdscan -c ${REMOTE_CONF} --stream "${RANDFILE}"
RESULT_CODE=$?

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
