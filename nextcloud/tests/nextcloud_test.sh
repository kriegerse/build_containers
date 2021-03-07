#!/usr/bin/env bash

set -x

# HELPER VARS
SCRIPT=$(readlink -f $0)
DOCKER_IMAGE="nextcloud-stage"

BUILD_PRIMARY_TAG="commit-92d89100"

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


# echo
# echo "========================================================================="
# echo "Detecting nextcloud service port"
# echo "========================================================================="
# NC_PORT=$(docker port nc-testing 80/tcp | cut -d ':' -f2)
# echo "Found: ${NC_PORT}"

echo
echo "========================================================================="
echo "Waiting for nextcloud service port ready"
echo "========================================================================="
COUNT=1
MAXCOUNT=60
SLEEPTIME=5
COMMAND="docker exec -t nc-testing  curl -s --fail -w %{http_code}  http://127.0.0.1:80"

while [ ${COUNT} -le $MAXCOUNT ]; do
  RESULT="$(${COMMAND})"
  if [[ ${RESULT} != '000' ]]; then
    echo "Reached nextcloud"
    echo "ANSWER: ${RESULT}"
    break
  elif [[ "${COUNT}" -eq "${MAXCOUNT}" ]]; then
    echo "Did no reach nextcloud"
    echo "after $(( MAXCOUNT * SLEEPTIME )) seconds!"
    echo "FAILED!"
    exit 1
  else
    echo "Waiting for nextcloud"
    COUNT=$(( COUNT + 1 ))
    sleep ${SLEEPTIME}
  fi
done


echo
echo "========================================================================="
echo "Checking for nextcloud status page"
echo "========================================================================="
COMMAND="docker exec -t nc-testing curl -s -L http://127.0.0.1:80/status.php"
RESULT="$(${COMMAND})"

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
COMMAND="docker exec -t nc-testing  curl -s -L http://127.0.0.1:80/index.php"
RESULT="$(${COMMAND})"

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
