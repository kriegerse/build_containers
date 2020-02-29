#!/usr/bin/env bash

RELEASE_PRIMARY_TAG=latest
RELEASE_SECONDARY_TAGS=build-$(date +%Y%m%d)

BUILD_PRIMARY_TAG="commit-${CI_COMMIT_SHORT_SHA}"
BUILD_SECONDARY_TAGS="branch-${CI_COMMIT_BRANCH}"

if [[ ${CI_EXTERNAL_PULL_REQUEST_IID} != "" &&
${CI_EXTERNAL_PULL_REQUEST_TARGET_BRANCH_NAME} == "master" ]]; then
  BUILD_SECONDARY_TAGS="${BUILD_SECONDARY_TAGS} pr-${CI_EXTERNAL_PULL_REQUEST_IID}"
fi

# print out for source file
echo "RELEASE_PRIMARY_TAG=\"${RELEASE_PRIMARY_TAG}\""
echo "RELEASE_SECONDARY_TAGS=\"${RELEASE_SECONDARY_TAGS}\""
echo "BUILD_PRIMARY_TAG=\"${BUILD_PRIMARY_TAG}\""
echo "BUILD_SECONDARY_TAGS=\"${BUILD_SECONDARY_TAGS}\""


# on normal commit in github to working brnach
# CI_PIPELINE_SOURCE=push
# CI_COMMIT_BRANCH=enable_gitlab_ci
# CI_COMMIT_SHORT_SHA=4b89e8a4

# creating a PR
# CI_PIPELINE_SOURCE=external_pull_request_event
# CI_EXTERNAL_PULL_REQUEST_IID=9
# CI_EXTERNAL_PULL_REQUEST_TARGET_BRANCH_NAME=master
# CI_COMMIT_BRANCH=enable_gitlab_ci

# on after mergeing a PR into master
# CI_PIPELINE_SOURCE=push
# CI_COMMIT_BRANCH=master
# CI_COMMIT_SHORT_SHA=a54cae03

# on gitlab scheduled build on master
# CI_PIPELINE_SOURCE=schedule
# CI_COMMIT_BRANCH=master
# CI_COMMIT_SHORT_SHA=a54cae03
