#!/usr/bin/env bash
set -euo pipefail

DOCKER_REPO=${DOCKER_REPO:-guangie88/spark-k8s}
docker login -u="${DOCKER_USERNAME}" -p="${DOCKER_PASSWORD}"

docker push "${DOCKER_REPO}:${SPARK_VERSION}_hadoop-${HADOOP_VERSION}"

SPARK_XY_VERSION="$(echo ${SPARK_VERSION} | cut -c 1-3)"
if [ "${SPARK_XY_VERSION}" != "2.3" ]; then # >= 2.4
    docker push "${DOCKER_REPO}-r:${SPARK_VERSION}_hadoop-${HADOOP_VERSION}"
    docker push "${DOCKER_REPO}-py:${SPARK_VERSION}_hadoop-${HADOOP_VERSION}"
fi
