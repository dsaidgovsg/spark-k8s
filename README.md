# `spark-k8s`

![CI Status](https://img.shields.io/github/workflow/status/guangie88/spark-k8s/CI/master?label=CI&logo=github&style=for-the-badge)

Travis setup to generate Spark Docker images meant for running in Kubernetes
set-up.

The current set-up only builds for Spark v3 preview versions, and should be
updated to support v3 when it comes.

## Note

All the build images here are Debian based as the official Spark repository now
uses `openjdk:8-jdk-slim` as the base image for Kubernetes build.

Because of the fast-changing nature of the Spark repository, this set-up might
contain inevitable breaking changes. As such, the build Docker images are
additionally tagged with this repository distribution tag version as prefix,
such as `v1_spark-2.4.4_hadoop-3.1.0`.

The older distribution tag version will separately go into a different Git
branch for clarity.

For details on the distribution versions, check [CHANGELOG.md](CHANGELOG.md).
