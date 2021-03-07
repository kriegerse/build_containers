#!/usr/bin/env bash

# HELPER VARS
SCRIPT=$(readlink -f $0)
DOCKER_IMAGE="nextcloud-stage"

# If not in CI use latest from production
if [[ ! "${CI}" == "true"  ]]; then
  docker_username="kriegerse"
  DOCKER_IMAGE="nextcloud"
  BUILD_PRIMARY_TAG="latest"
fi


# fetch docker images
echo "========================================================================="
echo "Pulling docker images"
echo "========================================================================="
echo "* Image: ${docker_username}/${DOCKER_IMAGE}:${BUILD_PRIMARY_TAG}"
docker pull ${docker_username}/${DOCKER_IMAGE}:${BUILD_PRIMARY_TAG}


echo
echo "========================================================================="
echo "Starting nextcloud SQLite Instance"
echo "========================================================================="
docker run --rm -P \
    --hostname nc-testing \
    --name nc-testing \
    -e SQLITE_DATABASE=nc_sqlite_db \
    -e NEXTCLOUD_ADMIN_USER=admin \
    -e NEXTCLOUD_ADMIN_PASSWORD=verysecret \
    -dt ${docker_username}/${DOCKER_IMAGE}:${BUILD_PRIMARY_TAG}


echo
echo "========================================================================="
echo "Detecting nextcloud service port"
echo "========================================================================="
NC_PORT=$(docker port nc-testing 80/tcp | cut -d ':' -f2)
echo "Found: ${NC_PORT}"

echo
echo "========================================================================="
echo "Waiting for nextcloud service port ready"
echo "========================================================================="
COUNT=1
MAXCOUNT=60
SLEEPTIME=5

while [ ${COUNT} -lt $MAXCOUNT ]; do
  RESULT=$(curl -s --fail -w "%{http_code}"  http://127.0.0.1:${NC_PORT})

  if [[ "${RESULT}" != "000" ]]; then
    echo "Reached nextcloud on port ${NC_PORT}"
    echo "ANSWER: ${RESULT}"
    break
  elif [[ "${COUNT}" -eq "${MAXCOUNT}" ]]; then
    echo "Did no reach nextcloud on port ${NC_PORT}"
    echo "after $(( MAXCOUNT * SLEEPTIME )) seconds!"
    echo "FAILED!"
    exit 1
  else
    echo "Waiting for nextcloud on port ${NC_PORT}"
  fi
  COUNT=$(( COUNT + 1 ))
  sleep ${SLEEPTIME}
done

echo
echo "========================================================================="
echo "Checking for nextcloud status page"
echo "========================================================================="
RESULT=$(curl -s http://127.0.0.1:${NC_PORT}/status.php -L)

if echo ${RESULT} | jq '.' > /dev/null ; then
  echo "Got valid JSON from status page"
  echo "ANSWER:"
  echo "${RESULT}" | jq '.'
else
  echo "Got invalid JSON from status page"
  echo "ANSWER: ${RESULT}"
  echo "FAILED!"
  exit 1
fi

echo
echo "========================================================================="
echo "Checking for nextcloud index page"
echo "========================================================================="
RESULT=$(curl -s http://127.0.0.1:${NC_PORT}/index.php -L)

if [[ ${RESULT} != "" ]]; then
  echo "Got index page"
  echo "ANSWER: ${RESULT}"
else
  echo "Got none index page"
  echo "ANSWER: ${RESULT}"
  echo "FAILED!"
  exit 1
fi

echo
echo "========================================================================="
echo "Stoping nextcloud container"
echo "========================================================================="
docker stop nginx nc-testing
