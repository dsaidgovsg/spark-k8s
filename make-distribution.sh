#!/usr/bin/env bash
set -euox pipefail

if ! command -v git >/dev/null; then
    >&2 echo "Cannot find git in PATH!"
    exit 1
fi

SPARK_VERSION_TAG="v${SPARK_VERSION}"

# Get the Spark source files set-up ready
if [[ ! -d "spark" ]]; then
    git clone https://github.com/apache/spark.git -b "${SPARK_VERSION_TAG}"
else
    pushd spark >/dev/null
    git reset --hard
    git fetch
    git checkout "origin/${SPARK_VERSION_TAG}" || git checkout "${SPARK_VERSION_TAG}"
    popd >/dev/null
fi

[[ "${WITH_HIVE}" == "true" ]] && HIVE_INSTALL_FLAG="yes"
[[ "${WITH_PYSPARK}" == "true" ]] && PYSPARK_INSTALL_FLAG="yes"

pushd spark >/dev/null

HADOOP_OVERRIDE_FLAG="yes"

# TERM issue: https://github.com/lihaoyi/mill/issues/139#issuecomment-366818171
TERM=xterm-color ./dev/make-distribution.sh \
    ${PYSPARK_INSTALL_FLAG:+"--pip"} --name "spark-${SPARK_VERSION}_hadoop-${HADOOP_VERSION}" \
    "-Phadoop-$(echo "${HADOOP_VERSION}" | cut -d '.' -f1,2)" \
    ${HADOOP_OVERRIDE_FLAG:+"-Dhadoop.version=${HADOOP_VERSION}"} \
    -Pkubernetes \
    ${HIVE_INSTALL_FLAG:+"-Phive"} \
    -DskipTests

GIT_REV="$(git rev-parse HEAD | cut -c 1-7)"
SPARK_LABEL="${SPARK_VERSION}"

TAG_NAME="${SELF_VERSION}_${SPARK_LABEL}_hadoop-${HADOOP_VERSION}"

./bin/docker-image-tool.sh \
    -r "${IMAGE_NAME}" \
    -t "${TAG_NAME}" \
    -p "./dist/kubernetes/dockerfiles/spark/bindings/python/Dockerfile" \
    -R "./dist/kubernetes/dockerfiles/spark/bindings/R/Dockerfile" \
    build

docker tag "${IMAGE_NAME}/spark:${TAG_NAME}" "${IMAGE_NAME}:${TAG_NAME}"
docker tag "${IMAGE_NAME}/spark-py:${TAG_NAME}" "${IMAGE_NAME}-py:${TAG_NAME}"
docker tag "${IMAGE_NAME}/spark-r:${TAG_NAME}" "${IMAGE_NAME}-r:${TAG_NAME}"

popd >/dev/null
