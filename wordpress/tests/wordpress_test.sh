#!/usr/bin/env bash


# HELPER VARS
SCRIPT=$(readlink -f $0)
DOCKER_IMAGE="wordpress-stage"

# If not in CI use latest from production
if [[ ! "${CI}" == "true"  ]]; then
  docker_username="kriegerse"
  DOCKER_IMAGE="wordpress"
  BUILD_PRIMARY_TAG="latest"
fi

echo "========================================================================="
echo "Pulling docker images"
echo "========================================================================="
echo "* Image: ${docker_username}/${DOCKER_IMAGE}:${BUILD_PRIMARY_TAG}"
docker pull ${docker_username}/${DOCKER_IMAGE}:${BUILD_PRIMARY_TAG}


echo
echo "========================================================================="
echo "Starting wordpress "
echo "========================================================================="
docker run --rm -P \
    --hostname wp-testing \
    --name wp-testing \
    -dt ${docker_username}/${DOCKER_IMAGE}:${BUILD_PRIMARY_TAG}


echo
echo "========================================================================="
echo "Waiting for wordpress service port ready"
echo "========================================================================="
COUNT=1
MAXCOUNT=60
SLEEPTIME=5
COMMAND="docker exec -t wp-testing  curl -s --fail -w %{http_code}  http://127.0.0.1:80"

while [ ${COUNT} -le $MAXCOUNT ]; do
  RESULT="$(${COMMAND})"
  if [[ ${RESULT} != '000' ]]; then
    echo "Reached wordpress"
    echo "ANSWER: ${RESULT}"
    break
  elif [[ "${COUNT}" -eq "${MAXCOUNT}" ]]; then
    echo "Did no reach wordpress"
    echo "after $(( MAXCOUNT * SLEEPTIME )) seconds!"
    echo "FAILED!"
    exit 1
  else
    echo "Waiting for wordpress"
    COUNT=$(( COUNT + 1 ))
    sleep ${SLEEPTIME}
  fi
done


echo
echo "========================================================================="
echo "Checking for wordpress index page"
echo "========================================================================="
COMMAND="docker exec -t wp-testing  curl -s -L http://127.0.0.1:80/index.php"
RESULT="$(${COMMAND})"

if [[ ${RESULT} != "" ]]; then
  echo "Got index page"
else
  echo "Got none index page"
  echo "ANSWER: ${RESULT}"
  echo "FAILED!"
  exit 1
fi

echo
echo "========================================================================="
echo "Checking for CRON process"
echo "========================================================================="
COMMAND="docker exec -t wp-testing pgrep -fc busybox.*crond"
RESULT="$(${COMMAND} | tr -d '\r')"

if [ ${RESULT} -ge 1 ]; then
  echo "Found cron process(es) - Number: ${RESULT}"
else
  echo "Couldn't find cron process"
  echo "ANSWER: ${RESULT}"
  echo "FAILED!"
  exit 1
fi

echo
echo "========================================================================="
echo "Stoping wordpress container"
echo "========================================================================="
docker stop wp-testing
