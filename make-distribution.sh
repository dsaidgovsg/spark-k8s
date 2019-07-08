#!/usr/bin/env bash
set -euox pipefail

DOCKER_REPO=${DOCKER_REPO:-guangie88/spark-k8s}
HIVE_HADOOP3_HIVE_EXEC_URL=${HIVE_HADOOP3_HIVE_EXEC_URL:-https://github.com/guangie88/hive-exec-jar/releases/download/1.2.1.spark2-hadoop3/hive-exec-1.2.1.spark2.jar}

if ! which git >/dev/null; then
    >&2 echo "Cannot find git in PATH!"
    exit 1
fi

if [ "${SPARK_VERSION}" = "master" ]; then
    SPARK_VERSION_TAG="master"
else
    SPARK_VERSION_TAG="v${SPARK_VERSION}"
fi

# Get the Spark source files set-up ready
if [ ! -d "spark" ] ; then
    git clone https://github.com/apache/spark.git -b "${SPARK_VERSION_TAG}"
else
    pushd spark >/dev/null
    git reset --hard
    git checkout "${SPARK_VERSION_TAG}"
    popd >/dev/null
fi

HIVE_INSTALL_FLAG=$(if [ "${WITH_HIVE}" = "true" ]; then echo "-Phive"; fi)
PYSPARK_INSTALL_FLAG=$(if [ "${WITH_PYSPARK}" = "true" ]; then echo "--pip"; fi)

pushd spark >/dev/null

# The build is very verbose and exceeds max log length, need to reduce using awk
./dev/make-distribution.sh \
    ${PYSPARK_INSTALL_FLAG} --name spark-${SPARK_VERSION}_hadoop-${HADOOP_VERSION} \
    -Phadoop-$(echo ${HADOOP_VERSION} | cut -c 1-3) \
    -Dhadoop.version=${HADOOP_VERSION} \
    -Pkubernetes \
    ${HIVE_INSTALL_FLAG} \
    -DskipTests | awk 'NR % 10 == 0'

# Replace Hive for Hadoop 3 since Hive 1.2.1 does not officially support Hadoop 3
# Note docker-image-tool.sh takes the jars from assembly/target/scala-2.*/jars
if [ "${WITH_HIVE}" = "true" ] && [ "$(echo ${HADOOP_VERSION} | cut -c 1)" = "3" ]; then
    JARS_DIR="$(find assembly -type d -name 'scala-2.*')"
    (cd ${JARS_DIR} && curl -LO ${HIVE_HADOOP3_HIVE_EXEC_URL})
    (cp ${JARS_DIR}/hive-exec-1.2.1.spark2.jar dist/jars/)
fi

GIT_REV="$(git rev-parse HEAD | cut -c 1-7)"
if [ "${SPARK_VERSION}" = "master" ]; then
    SPARK_LABEL="${GIT_REV}"
else
    SPARK_LABEL="master-${SPARK_VERSION}"
fi

# There is no way to rename the Docker image, so we simply retag
./bin/docker-image-tool.sh -r ${DOCKER_REPO} -t ${SPARK_LABEL}_hadoop-${HADOOP_VERSION} build

docker tag "${DOCKER_REPO}/spark:${SPARK_LABEL}_hadoop-${HADOOP_VERSION}" "${DOCKER_REPO}:${SPARK_LABEL}_hadoop-${HADOOP_VERSION}"

SPARK_XY_VERSION="$(echo ${SPARK_VERSION} | cut -c 1-3)"
if [ "${SPARK_XY_VERSION}" != "2.3" ]; then  # >= 2.4 or master
    docker tag "${DOCKER_REPO}/spark-r:${SPARK_LABEL}_hadoop-${HADOOP_VERSION}" "${DOCKER_REPO}-r:${SPARK_LABEL}_hadoop-${HADOOP_VERSION}"
    docker tag "${DOCKER_REPO}/spark-py:${SPARK_LABEL}_hadoop-${HADOOP_VERSION}" "${DOCKER_REPO}-py:${SPARK_LABEL}_hadoop-${HADOOP_VERSION}"
fi

popd >/dev/null
