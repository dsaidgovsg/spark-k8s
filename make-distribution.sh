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
    ${PYSPARK_INSTALL_FLAG:+"--pip"} --name "${SPARK_VERSION}_hadoop-${HADOOP_VERSION}_scala-${SCALA_VERSION}" \
    -Pscala-${SCALA_VERSION} \
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

GIT_REV="$(git rev-parse HEAD | cut -c 1-7)"
SPARK_LABEL="${SPARK_VERSION}"

TAG_NAME="${SELF_VERSION}_${SPARK_LABEL}_hadoop-${HADOOP_VERSION}_scala-${SCALA_VERSION}"

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

# Spark 2.4 builds are silly and don't include spark/python/pyspark contents
# So manually include them
SPARK_MAJOR_VERSION="$(echo "${SPARK_VERSION}" | cut -d '.' -f1)"
SPARK_MINOR_VERSION="$(echo "${SPARK_VERSION}" | cut -d '.' -f2)"

if [[ "${SPARK_VERSION}" != "master" ]] && [[ ${SPARK_MAJOR_VERSION} -eq 2 && ${SPARK_MINOR_VERSION} -ge 4 ]]; then  # >= 2.4
    docker build . -f Dockerfile-py -t "${IMAGE_NAME}-py:${TAG_NAME}" \
        --build-arg "IMAGE_NAME=${IMAGE_NAME}" \
        --build-arg "TAG_NAME=${TAG_NAME}"
fi
