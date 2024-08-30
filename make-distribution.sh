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
    git checkout "${SPARK_VERSION_TAG}"
    popd >/dev/null
fi

[[ "${WITH_HIVE}" == "true" ]] && HIVE_INSTALL_FLAG="yes"
[[ "${WITH_PYSPARK}" == "true" ]] && PYSPARK_INSTALL_FLAG="yes"

pushd spark >/dev/null

HADOOP_OVERRIDE_FLAG="yes"
HADOOP_MAJOR_VERSION="$(echo "${HADOOP_VERSION}" | cut -d '.' -f1)"

./dev/change-scala-version.sh "${SCALA_VERSION}"
# TERM issue: https://github.com/lihaoyi/mill/issues/139#issuecomment-366818171
TERM=xterm-color ./dev/make-distribution.sh \
    ${PYSPARK_INSTALL_FLAG:+"--pip"} \
    --name "${SPARK_VERSION}_hadoop-${HADOOP_VERSION}_scala-${SCALA_VERSION}_java-${JAVA_VERSION}" \
    -Pscala-${SCALA_VERSION} \
    -Djava.version=${JAVA_VERSION} \
    "-Phadoop-${HADOOP_MAJOR_VERSION}" \
    -Phadoop-cloud \
    ${HADOOP_OVERRIDE_FLAG:+"-Dhadoop.version=${HADOOP_VERSION}"} \
    -Pkubernetes \
    ${HIVE_INSTALL_FLAG:+"-Phive"} \
    -DskipTests

DOCKERFILE_BASE="./resource-managers/kubernetes/docker/src/main/dockerfiles/spark/Dockerfile"
DOCKERFILE_PY="./resource-managers/kubernetes/docker/src/main/dockerfiles/spark/bindings/python/Dockerfile"

IMAGE_VARIANT="jre"

SPARK_LABEL="${SPARK_VERSION}"
TAG_NAME="${SELF_VERSION}_${SPARK_LABEL}_hadoop-${HADOOP_VERSION}_scala-${SCALA_VERSION}_java-${JAVA_VERSION}"

./bin/docker-image-tool.sh \
    -b java_image_tag=${JAVA_VERSION}-${IMAGE_VARIANT} \
    -r "${IMAGE_NAME}" \
    -t "${TAG_NAME}" \
    -f "${DOCKERFILE_BASE}" \
    -p "${DOCKERFILE_PY}" \
    build

docker tag "${IMAGE_NAME}/spark:${TAG_NAME}" "${IMAGE_NAME}:${TAG_NAME}"
docker tag "${IMAGE_NAME}/spark-py:${TAG_NAME}" "${IMAGE_NAME}-py:${TAG_NAME}"

popd >/dev/null
