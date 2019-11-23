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

TAG_NAME="${SPARK_LABEL}_hadoop-${HADOOP_VERSION}"
DIST_TAG_NAME="${DIST_VERSION}_spark-${TAG_NAME}"

docker tag "${IMAGE_NAME}:${TAG_NAME}" "${DOCKER_USERNAME}/${IMAGE_NAME}:${TAG_NAME}"
docker push "${DOCKER_USERNAME}/${IMAGE_NAME}:${TAG_NAME}"
docker tag "${IMAGE_NAME}:${TAG_NAME}" "${DOCKER_USERNAME}/${IMAGE_NAME}:${DIST_TAG_NAME}"
docker push "${DOCKER_USERNAME}/${IMAGE_NAME}:${DIST_TAG_NAME}"

SPARK_MAJOR_VERSION="$(echo "${SPARK_VERSION}" | cut -d '.' -f1)"
SPARK_MINOR_VERSION="$(echo "${SPARK_VERSION}" | cut -d '.' -f2)"

if [[ ${SPARK_MAJOR_VERSION} -ge 2 && ${SPARK_MINOR_VERSION} -ge 4 ]]; then  # >= 2.4
    docker tag "${IMAGE_NAME}-r:${TAG_NAME}" "${DOCKER_USERNAME}/${IMAGE_NAME}-r:${TAG_NAME}"
    docker push "${DOCKER_USERNAME}/${IMAGE_NAME}-r:${TAG_NAME}"
    docker tag "${IMAGE_NAME}-r:${TAG_NAME}" "${DOCKER_USERNAME}/${IMAGE_NAME}-r:${DIST_TAG_NAME}"
    docker push "${DOCKER_USERNAME}/${IMAGE_NAME}-r:${DIST_TAG_NAME}"

    docker tag "${IMAGE_NAME}-py:${TAG_NAME}" "${DOCKER_USERNAME}/${IMAGE_NAME}-py:${TAG_NAME}"
    docker push "${DOCKER_USERNAME}/${IMAGE_NAME}-py:${TAG_NAME}"
    docker tag "${IMAGE_NAME}-py:${TAG_NAME}" "${DOCKER_USERNAME}/${IMAGE_NAME}-py:${DIST_TAG_NAME}"
    docker push "${DOCKER_USERNAME}/${IMAGE_NAME}-py:${DIST_TAG_NAME}"
fi

popd >/dev/null
