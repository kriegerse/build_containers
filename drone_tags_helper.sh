#!/usr/bin/env bash

if [[ "${DRONE_BRANCH}" == "master" ]]; then
  echo -n "latest,build-${DRONE_BUILD_NUMBER}" > .tags
  echo -n ",builddate-$(date +%Y-%m-%d)" >> .tags
else
  echo -n "build-${DRONE_BUILD_NUMBER}" > .tags
  echo -n ",branch-${DRONE_BRANCH}" >> .tags
  if [[ "${DRONE_PULL_REQUEST}" != "" ]]; then
    echo -n ",PR-${DRONE_PULL_REQUEST}" >> .tags
  fi
fi

cat ./.tags
