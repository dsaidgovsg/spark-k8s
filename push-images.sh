#!/usr/bin/env bash
set -euo pipefail

DOCKER_REPO=${DOCKER_REPO:-guangie88/spark-k8s}
docker login -u="${DOCKER_USERNAME}" -p="${DOCKER_PASSWORD}"

pushd spark >/dev/null

GIT_REV="$(git rev-parse HEAD | cut -c 1-7)"
if [ "${SPARK_VERSION}" = "master" ]; then
    SPARK_LABEL="${GIT_REV}"
else
    SPARK_LABEL="master-${SPARK_VERSION}"
fi

docker push "${DOCKER_REPO}:${SPARK_LABEL}_hadoop-${HADOOP_VERSION}"

SPARK_XY_VERSION="$(echo ${SPARK_VERSION} | cut -c 1-3)"
if [ "${SPARK_XY_VERSION}" != "2.3" ]; then  # >= 2.4 or master
    docker push "${DOCKER_REPO}-r:${SPARK_LABEL}_hadoop-${HADOOP_VERSION}"
    docker push "${DOCKER_REPO}-py:${SPARK_LABEL}_hadoop-${HADOOP_VERSION}"
fi

popd >/dev/null
