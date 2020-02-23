#!/usr/bin/env bash

echo -n "build-${DRONE_BUILD_NUMBER}" > .tags

if [[ "${DRONE_BRANCH}" == "master" ]]; then
  echo -n ",latest" > .tags
  echo -n ",builddate-$(date +%Y-%m-%d)" >> .tags
elif [[ ${DRONE_PULL_REQUEST} != "" ]]; then
  echo -n ",PR-${DRONE_PULL_REQUEST}" >> .tags
else
  echo -n ",branch-${DRONE_BRANCH}" >> .tags
fi
