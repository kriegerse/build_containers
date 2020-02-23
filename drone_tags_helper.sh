#!/usr/bin/env ash


if [[ "${DRONE_BRANCH}" == "master" ]]; then
  echo -n "latest" > .tags
  echo -n ",builddate-$(date +%Y-%m-%d)" >> .tags
elif [[ ${DRONE_PULL_REQUEST} != "" ]]; then
  echo -n "pr-${DRONE_PULL_REQUEST}" >> .tags
else
  echo -n "branch-${DRONE_BRANCH}" >> .tags
fi
