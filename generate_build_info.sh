#!/usr/bin/env bash


echo "export TEST1=TESTVAL1"



# if [[ "${DRONE_BRANCH}" == "master" && ${DRONE_PULL_REQUEST} == "" ]]; then
#   echo -n "latest" > .tags
#   echo -n ",stable" >> .tags
#   echo -n ",builddate-$(date +%Y-%m-%d)" >> .tags
# elif [[ ${DRONE_PULL_REQUEST} != "" ]]; then
#   echo -n "latest" > .tags
#   echo -n ",testing" >> .tags
#   echo -n ",pr-${DRONE_PULL_REQUEST}-build-${DRONE_BUILD_NUMBER}" >> .tags
# else
#   echo -n "latest" > .tags
#   echo -n ",dev" >> .tags
#   echo -n ",branch-${DRONE_BRANCH}-build-${DRONE_BUILD_NUMBER}"
# fi
