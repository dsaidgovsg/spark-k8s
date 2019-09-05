#!/usr/bin/env bash
set -euo pipefail

DOCKER_REPO=${DOCKER_REPO:-guangie88/spark-k8s}
docker login -u="${DOCKER_USERNAME}" -p="${DOCKER_PASSWORD}"

pushd spark >/dev/null

GIT_REV="$(git rev-parse HEAD | cut -c 1-7)"
if [ "${SPARK_VERSION}" = "master" ]; then
    SPARK_LABEL="master-${GIT_REV}"
else
    SPARK_LABEL="${SPARK_VERSION}"
fi

docker push "${DOCKER_REPO}:${SPARK_LABEL}_hadoop-${HADOOP_VERSION}"

# Spark <= 2.3 does not do -py and -r set-up, therefore we need this check here
SPARK_MAJOR_VERSION="$(echo "${SPARK_VERSION}" | cut -d '.' -f1)"
SPARK_MINOR_VERSION="$(echo "${SPARK_VERSION}" | cut -d '.' -f2)"
if [[ "${SPARK_VERSION}" == "master" ]] || [[ ${SPARK_MAJOR_VERSION} -ge 2 ]] && [[ ${SPARK_MINOR_VERSION} -ge 4 ]]; then  # >= 2.4
    docker push "${DOCKER_REPO}-r:${SPARK_LABEL}_hadoop-${HADOOP_VERSION}"
    docker push "${DOCKER_REPO}-py:${SPARK_LABEL}_hadoop-${HADOOP_VERSION}"
fi

popd >/dev/null
