#!/usr/bin/env ash


if [[ "${DRONE_BRANCH}" == "master" ]]; then
  echo -n "latest" > .tags
  echo -n ",stable" >> .tags
  echo -n ",builddate-$(date +%Y-%m-%d)" >> .tags
elif [[ ${DRONE_PULL_REQUEST} != "" ]]; then
  echo -n "latest" > .tags
  echo -n ",testing" >> .tags
  echo -n ",pr-${DRONE_PULL_REQUEST}-build-${DRONE_BUILD_NUMBER}" >> .tags
fi
