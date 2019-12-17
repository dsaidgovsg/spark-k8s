# `spark-k8s`

![CI Status](https://img.shields.io/github/workflow/status/guangie88/spark-k8s/CI/master?color=green&label=CI&logo=github&logoColor=white&style=for-the-badge)

Travis setup to generate Spark Docker images meant for running in Kubernetes
set-up.

All the built images here are inherently based on `openjdk8` and Alpine as the
official build script builds the Docker image based on that.

Additionally, all the built images are currently built with Hadoop and Hive
support, and images that are using Hadoop 3 for Spark 2.Y.Z are automatically
applied with unofficial patch for Hive JAR to make it work with Hadoop 3. The
unofficial patch can be found
[here](https://github.com/guangie88/hive-exec-jar).

## Note

For the build, if `WITH_PYSPARK` is set to `true`, then `python` and
`python-setuptools` should be `apt` installed.
