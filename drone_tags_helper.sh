#!/bin/ash

if [[ "${DRONE_BRANCH}" -eq "master" ]]; then
  echo -n "latest,build-${DRONE_BUILD_NUMBER}" > .tags
  echo -n "builddate-$(date +%Y-%m-%d)" >> .tags
else
  echo -n "testing,build-${DRONE_BUILD_NUMBER}" > .tags
fi
