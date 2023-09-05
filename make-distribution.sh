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

./dev/change-scala-version.sh "${SCALA_VERSION}"
# TERM issue: https://github.com/lihaoyi/mill/issues/139#issuecomment-366818171
TERM=xterm-color ./dev/make-distribution.sh \
    ${PYSPARK_INSTALL_FLAG:+"--pip"} \
    --name "${SPARK_VERSION}_hadoop-${HADOOP_VERSION}_scala-${SCALA_VERSION}_java-${JAVA_VERSION}" \
    -Pscala-${SCALA_VERSION} \
    -Djava.version=${JAVA_VERSION} \
    "-Phadoop-$(echo "${HADOOP_VERSION}" | cut -d '.' -f1,2)" \
    -Phadoop-cloud \
    ${HADOOP_OVERRIDE_FLAG:+"-Dhadoop.version=${HADOOP_VERSION}"} \
    -Pkubernetes \
    ${HIVE_INSTALL_FLAG:+"-Phive"} \
    -DskipTests

SPARK_MAJOR_VERSION="$(echo "${SPARK_VERSION}" | cut -d '.' -f1)"
HADOOP_MAJOR_VERSION="$(echo "${HADOOP_VERSION}" | cut -d '.' -f1)"
HIVE_HADOOP3_HIVE_EXEC_URL=${HIVE_HADOOP3_HIVE_EXEC_URL:-https://github.com/guangie88/hive-exec-jar/releases/download/1.2.1.spark2-hadoop3/hive-exec-1.2.1.spark2.jar}

# Replace Hive for Hadoop 3 since Hive 1.2.1 does not officially support Hadoop 3 when using Spark 2.y.z
# Note docker-image-tool.sh takes the jars from assembly/target/scala-2.*/jars
if [[ "${WITH_HIVE}" = "true" ]] && [[ "${SPARK_MAJOR_VERSION}" -eq 2 ]] && [[ "${HADOOP_MAJOR_VERSION}" -eq 3 ]]; then
    HIVE_EXEC_JAR_NAME="hive-exec-1.2.1.spark2.jar"
    TARGET_JAR_PATH="$(find assembly -type f -name "${HIVE_EXEC_JAR_NAME}")"
    curl -LO "${HIVE_HADOOP3_HIVE_EXEC_URL}" && mv "${HIVE_EXEC_JAR_NAME}" "${TARGET_JAR_PATH}"
    # Spark <= 2.4 uses ${TARGET_JAR_PATH} for Docker COPY, but Spark >= 3 uses dist/jars/
    cp "${TARGET_JAR_PATH}" "dist/jars/"
fi

SPARK_MAJOR_VERSION="$(echo "${SPARK_VERSION}" | cut -d '.' -f1)"
SPARK_MINOR_VERSION="$(echo "${SPARK_VERSION}" | cut -d '.' -f2)"

if [[ ${SPARK_MAJOR_VERSION} -eq 2 && ${SPARK_MINOR_VERSION} -eq 4 ]]; then  # 2.4.z
    # Same Dockerfiles as Spark v2.4.8, but allow override of base image to use Debian Buster
    # and not using PYTHONENV and instead copies pyspark out like Spark 3.y.z
    DOCKERFILE_BASE="../overrides/base/2.4.z/Dockerfile"
    DOCKERFILE_PY="../overrides/python/2.4.z/Dockerfile"
else
    DOCKERFILE_BASE="./resource-managers/kubernetes/docker/src/main/dockerfiles/spark/Dockerfile"
    DOCKERFILE_PY="./resource-managers/kubernetes/docker/src/main/dockerfiles/spark/bindings/python/Dockerfile"
fi

if [[ ${SPARK_MAJOR_VERSION} -eq 3 && ${SPARK_MINOR_VERSION} -ge 4 ]]; then  # >=3.4
    # From Spark v3.4.0 onwards, openjdk is not the prefered base image source as it i
    # deprecated and taken over by eclipse-temurin. slim-buster variants are not available
    # on eclipse-temurin at the moment.
    IMAGE_VARIANT="jre-alpine"
else
    IMAGE_VARIANT="jre-slim-buster"
fi

# Temporarily remove R build due to keyserver issue
# DOCKERFILE_R="./resource-managers/kubernetes/docker/src/main/dockerfiles/R/Dockerfile"

SPARK_LABEL="${SPARK_VERSION}"
TAG_NAME="${SELF_VERSION}_${SPARK_LABEL}_hadoop-${HADOOP_VERSION}_scala-${SCALA_VERSION}_java-${JAVA_VERSION}"

# ./bin/docker-image-tool.sh \
#     -b java_image_tag=${JAVA_VERSION}-jre-slim-buster \
#     -r "${IMAGE_NAME}" \
#     -t "${TAG_NAME}" \
#     -f "${DOCKERFILE_BASE}" \
#     -p "${DOCKERFILE_PY}" \
#     -R "${DOCKERFILE_R}" \
#     build

./bin/docker-image-tool.sh \
    -b java_image_tag=${JAVA_VERSION}-${IMAGE_VARIANT} \
    -r "${IMAGE_NAME}" \
    -t "${TAG_NAME}" \
    -f "${DOCKERFILE_BASE}" \
    -p "${DOCKERFILE_PY}" \
    build

docker tag "${IMAGE_NAME}/spark:${TAG_NAME}" "${IMAGE_NAME}:${TAG_NAME}"
docker tag "${IMAGE_NAME}/spark-py:${TAG_NAME}" "${IMAGE_NAME}-py:${TAG_NAME}"
# docker tag "${IMAGE_NAME}/spark-r:${TAG_NAME}" "${IMAGE_NAME}-r:${TAG_NAME}"

popd >/dev/null
