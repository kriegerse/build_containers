#!/usr/bin/env bash

set -x

# HELPER VARS
SCRIPT=$(readlink -f $0)
DOCKER_IMAGE="squid-stage"

# If not in CI use latest from production
if [[ ! "${CI}" == "true"  ]]; then
  docker_username="kriegerse"
  DOCKER_IMAGE="squid"
  BUILD_PRIMARY_TAG="latest"
fi


# fetch docker images
echo "========================================================================="
echo "Pulling docker images"
echo "========================================================================="
echo "* Image: ${docker_username}/${DOCKER_IMAGE}:${BUILD_PRIMARY_TAG}"
docker pull ${docker_username}/${DOCKER_IMAGE}:${BUILD_PRIMARY_TAG}
echo "* Image: nginx:stable"
docker pull nginx:stable


echo "========================================================================="
echo "Create network for squid proxy communication"
echo "========================================================================="
docker network create squid
docker network ls


echo "========================================================================="
echo "Starting squid proxy"
echo "========================================================================="
docker run --rm -P \
    --hostname squid \
    --name squid \
    --network squid \
    -dt ${docker_username}/${DOCKER_IMAGE}:${BUILD_PRIMARY_TAG}


echo "========================================================================="
echo "Detecting squid proxy port"
echo "========================================================================="
PROXY_PORT=$(docker port squid 3128/tcp | cut -d ':' -f2)
echo "Found: $PROXY_PORT"

sleep 5

echo "========================================================================="
echo "Starting nginx webserver"
echo "========================================================================="
docker run  --rm -P \
    --hostname nginx \
    --name nginx \
    --network squid \
    -dt nginx:stable

sleep 5

echo "========================================================================="
echo "Generating random file"
echo "========================================================================="
docker exec -t nginx  /bin/bash -c "dd if=/dev/urandom of=/usr/share/nginx/html/randfile bs=1M count=10"
RESCODE=$?

if [ $RESCODE -eq 0 ]; then
  echo "OKAY: Generated random data /usr/share/nginx/html/randfile on nginx webserver."
else
  echo "ERROR: Couldn't generate random data on nginx webserver."
  exit 1
fi

echo "* Get checksum from random data on nginx webserver."
# RANDCHKSUM=$(docker exec -t nginx /bin/bash -c "md5sum /usr/share/nginx/html/randfile | cut -d ' ' -f1 | tr -d '\w' ")
RANDCHKSUM=$(docker exec -t nginx md5sum /usr/share/nginx/html/randfile | cut -d ' ' -f1)
RESCODE=$?

if [ $RESCODE -eq 0 ]; then
  echo "OKAY: Get checksum ${RANDCHKSUM} from /usr/share/nginx/html/randfile on nginx webserver."
else
  echo "ERROR: Couldn't get checksum from /usr/share/nginx/html/randfile on nginx webserver."
  exit 1
fi


echo "========================================================================="
echo "Downloading randfile through squid proxy"
echo "========================================================================="
echo "* Downloading randfile"
DLCHKSUM=$(curl -vvv -L --proxy localhost:${PROXY_PORT} 'http://nginx/randfile' | md5sum | cut -d ' ' -f1)
RESCODE=$?

if [ $RESCODE -eq 0 ]; then
  echo "OKAY: Successfully download randfile via squid proxy."
else
  echo "ERROR: Couldn't download randfile via squid proxy."
  exit 1
fi


echo "* Comparing checksums"
if [[ "${RANDCHKSUM}" == "${DLCHKSUM}" ]]; then
  echo "OKAY: Successfully compared checksums: ORIGIN: ${RANDCHKSUM}, DOWNLOAD: ${DLCHKSUM}"
else
  echo "ERROR: Different checksums found: ORIGIN: ${RANDCHKSUM}, DOWNLOAD: ${DLCHKSUM}"
  exit 1
fi


echo "========================================================================="
echo "Stoping containers nginx + squid"
echo "========================================================================="

docker stop nginx squid
docker volume prune -f
docker network prune -f
