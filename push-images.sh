#!/usr/bin/env bash
set -euo pipefail

echo "${DOCKER_PASSWORD}" | docker login -u="${DOCKER_USERNAME}" --password-stdin

GIT_REV="$(git rev-parse HEAD | cut -c 1-7)"
if [ "${SPARK_VERSION}" = "master" ]; then
    SPARK_LABEL="master-${GIT_REV}"
else
    SPARK_LABEL="${SPARK_VERSION}"
fi

TAG_NAME="${SELF_VERSION}_${SPARK_LABEL}_hadoop-${HADOOP_VERSION}_scala-${SCALA_VERSION}_java-${JAVA_VERSION}"
ALT_TAG_NAME="${SPARK_LABEL}_hadoop-${HADOOP_VERSION}_scala-${SCALA_VERSION}_java-${JAVA_VERSION}"

docker tag "${IMAGE_NAME}:${TAG_NAME}" "test_${IMAGE_ORG}/${IMAGE_NAME}:${TAG_NAME}"
docker push "${IMAGE_ORG}/${IMAGE_NAME}:${TAG_NAME}"

# Python image push
docker tag "${IMAGE_NAME}-py:${TAG_NAME}" "test_${IMAGE_ORG}/${IMAGE_NAME}-py:${TAG_NAME}"
docker push "${IMAGE_ORG}/${IMAGE_NAME}-py:${TAG_NAME}"
