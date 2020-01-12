#!/usr/bin/env bash
set -euo pipefail

docker login -u="${DOCKER_USERNAME}" -p="${DOCKER_PASSWORD}"

pushd spark >/dev/null

GIT_REV="$(git rev-parse HEAD | cut -c 1-7)"
if [ "${SPARK_VERSION}" = "master" ]; then
    SPARK_LABEL="master-${GIT_REV}"
else
    SPARK_LABEL="${SPARK_VERSION}"
fi

TAG_NAME="${SELF_VERSION}_${SPARK_LABEL}_hadoop-${HADOOP_VERSION}_scala-${SCALA_VERSION}"
ALT_TAG_NAME="${SPARK_LABEL}_hadoop-${HADOOP_VERSION}_scala-${SCALA_VERSION}"

docker tag "${IMAGE_NAME}:${TAG_NAME}" "${DOCKER_USERNAME}/${IMAGE_NAME}:${TAG_NAME}"
docker push "${DOCKER_USERNAME}/${IMAGE_NAME}:${TAG_NAME}"
docker tag "${IMAGE_NAME}:${TAG_NAME}" "${DOCKER_USERNAME}/${IMAGE_NAME}:${ALT_TAG_NAME}"
docker push "${DOCKER_USERNAME}/${IMAGE_NAME}:${ALT_TAG_NAME}"

# Python image push
docker tag "${IMAGE_NAME}-py:${TAG_NAME}" "${DOCKER_USERNAME}/${IMAGE_NAME}-py:${TAG_NAME}"
docker push "${DOCKER_USERNAME}/${IMAGE_NAME}-py:${TAG_NAME}"
docker tag "${IMAGE_NAME}-py:${TAG_NAME}" "${DOCKER_USERNAME}/${IMAGE_NAME}-py:${ALT_TAG_NAME}"
docker push "${DOCKER_USERNAME}/${IMAGE_NAME}-py:${ALT_TAG_NAME}"

# R image push
docker tag "${IMAGE_NAME}-r:${TAG_NAME}" "${DOCKER_USERNAME}/${IMAGE_NAME}-r:${TAG_NAME}"
docker push "${DOCKER_USERNAME}/${IMAGE_NAME}-r:${TAG_NAME}"
docker tag "${IMAGE_NAME}-r:${TAG_NAME}" "${DOCKER_USERNAME}/${IMAGE_NAME}-r:${ALT_TAG_NAME}"
docker push "${DOCKER_USERNAME}/${IMAGE_NAME}-r:${ALT_TAG_NAME}"

popd >/dev/null
