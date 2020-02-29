#!/usr/bin/env bash


### generate docker image tags ################################################

# in master for release
# if [[ "${CI_COMMIT_BRANCH}" == "master" ]]; then
#   REGEX='^(schedule|merge_request_event)$'
#   if [[ "${CI_PIPELINE_SOURCE}" =~ $REGEX ]]; then
#     echo "export IMAGE_PRIMARY_TAG='latest'"
#     echo "export IMAGE_SECONDARY_TAGS=\"build-$(date +%Y%m%d) stable\""
#   fi
#
#   if [[ "${CI_PIPELINE_SOURCE}" == "external_pull_request_event" ]]; then
#     echo "export IMAGE_PRIMARY_TAG='PR-'"
#     echo "export IMAGE_SECONDARY_TAGS=\"build-$(date +%Y%m%d) stable\""
#   fi
# # in any working branch
# else
#   echo "export IMAGE_PRIMARY_TAG=$(CI_COMMIT_SHA)"
#   echo "export IMAGE_SECONDARY_TAGS=$(CI_COMMIT_BRANCH)"
# fi


# # on PR
# DOCKER_ENV_CI_PIPELINE_SOURCE=external_pull_request_event
# CI_EXTERNAL_PULL_REQUEST_IID=9
# CI_EXTERNAL_PULL_REQUEST_TARGET_BRANCH_NAME=master
# CI_COMMIT_BRANCH=enable_gitlab_ci
#
# # on normal commit in github to working brnach
# CI_PIPELINE_SOURCE=push
# CI_COMMIT_BRANCH=enable_gitlab_ci
# CI_COMMIT_SHORT_SHA=4b89e8a4



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
