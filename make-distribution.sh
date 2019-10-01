#!/usr/bin/env bash
set -euox pipefail

HIVE_HADOOP3_HIVE_EXEC_URL=${HIVE_HADOOP3_HIVE_EXEC_URL:-https://github.com/guangie88/hive-exec-jar/releases/download/1.2.1.spark2-hadoop3/hive-exec-1.2.1.spark2.jar}

if ! command -v git >/dev/null; then
    >&2 echo "Cannot find git in PATH!"
    exit 1
fi

if [ "${SPARK_VERSION}" = "master" ]; then
    SPARK_VERSION_TAG="master"
else
    SPARK_VERSION_TAG="v${SPARK_VERSION}"
fi

# Get the Spark source files set-up ready
if [ ! -d "spark" ]; then
    git clone https://github.com/apache/spark.git -b "${SPARK_VERSION_TAG}"
else
    pushd spark >/dev/null
    git reset --hard
    git checkout "${SPARK_VERSION_TAG}"
    git pull
    popd >/dev/null
fi

[ "${WITH_HIVE}" = "true" ] && HIVE_INSTALL_FLAG="yes"
[ "${WITH_PYSPARK}" = "true" ] && PYSPARK_INSTALL_FLAG="yes"

pushd spark >/dev/null

[ "${SPARK_VERSION}" != "master" ] && HADOOP_OVERRIDE_FLAG="yes"

# The build is very verbose and exceeds max log length, need to reduce using awk
# TERM issue: https://github.com/lihaoyi/mill/issues/139#issuecomment-366818171
TERM=xterm-color ./dev/make-distribution.sh \
    ${PYSPARK_INSTALL_FLAG:+"--pip"} --name "spark-${SPARK_VERSION}_hadoop-${HADOOP_VERSION}" \
    "-Phadoop-$(echo "${HADOOP_VERSION}" | cut -c 1-3)" \
    ${HADOOP_OVERRIDE_FLAG:+"-Dhadoop.version=${HADOOP_VERSION}"} \
    -Pkubernetes \
    ${HIVE_INSTALL_FLAG:+"-Phive"} \
    -DskipTests | awk 'NR % 10 == 0'

# Replace Hive for Hadoop 3 since Hive 1.2.1 does not officially support Hadoop 3 when using Spark 2.y.z
# Note docker-image-tool.sh takes the jars from assembly/target/scala-2.*/jars
if [ "${SPARK_VERSION}" != "master" ] && [ "${WITH_HIVE}" = "true" ] && [ "$(echo "${HADOOP_VERSION}" | cut -c 1)" = "3" ]; then
    JARS_DIR="$(find assembly -type d -name 'scala-2.*')"
    (cd "${JARS_DIR}" && curl -LO "${HIVE_HADOOP3_HIVE_EXEC_URL}")
    (cp "${JARS_DIR}/hive-exec-1.2.1.spark2.jar" dist/jars/)
fi

GIT_REV="$(git rev-parse HEAD | cut -c 1-7)"
if [ "${SPARK_VERSION}" = "master" ]; then
    SPARK_LABEL="master-${GIT_REV}"
else
    SPARK_LABEL="${SPARK_VERSION}"
fi

TAG_NAME="${SPARK_LABEL}_hadoop-${HADOOP_VERSION}"

if [[ "${SPARK_VERSION}" == "master" ]]; then
    # master branch requires manual specification of the paths of -py and -r Dockerfiles
    ./bin/docker-image-tool.sh \
        -r "${IMAGE_NAME}" \
        -t "${TAG_NAME}" \
        -p dist/kubernetes/dockerfiles/spark/bindings/python/Dockerfile \
        -R dist/kubernetes/dockerfiles/spark/bindings/R/Dockerfile \
        build
else
    # branch-2.3 will does not have -py and -r builds
    # branch-2.4 will auto-infer the -py and -r Dockerfile paths correctly
    ./bin/docker-image-tool.sh \
        -r "${IMAGE_NAME}" \
        -t "${TAG_NAME}" \
        build
fi

docker tag "${IMAGE_NAME}/spark:${TAG_NAME}" "${IMAGE_NAME}:${TAG_NAME}"

SPARK_MAJOR_VERSION="$(echo "${SPARK_VERSION}" | cut -d '.' -f1)"
SPARK_MINOR_VERSION="$(echo "${SPARK_VERSION}" | cut -d '.' -f2)"

# There is no way to rename the Docker image, so we simply retag
# Spark <= 2.3 does not do -py and -r set-up, therefore we need this check here
if [[ "${SPARK_VERSION}" == "master" ]] || [[ ${SPARK_MAJOR_VERSION} -ge 2 && ${SPARK_MINOR_VERSION} -ge 4 ]]; then  # >= 2.4
    docker tag "${IMAGE_NAME}/spark-r:${TAG_NAME}" "${IMAGE_NAME}-r:${TAG_NAME}"
    docker tag "${IMAGE_NAME}/spark-py:${TAG_NAME}" "${IMAGE_NAME}-py:${TAG_NAME}"
fi

popd >/dev/null
