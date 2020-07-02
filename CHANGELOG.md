# CHANGELOG

## v2

- Previously supported Spark 3.0.0 previews, but drop in favor to use
  the official Spark 3.0.0. Also support from 2.4.5 and 2.4.6 that comes
  with Debian-based image support.
- Debian-based image since the earliest preview release tag
  `v3.0.0-preview-rc1` uses `openjdk:8-jdk-slim`. See:
  - <https://github.com/apache/spark/blob/v3.0.0-preview-rc1/resource-managers/kubernetes/docker/src/main/dockerfiles/spark/Dockerfile#L18>
  - <https://github.com/apache/spark/blob/v2.4.5/resource-managers/kubernetes/docker/src/main/dockerfiles/spark/Dockerfile#L18>

## v1

- Basic setup for Spark 2.3.4 and Spark 2.4.4.
- Alpine-based image since Spark pre-v3 uses `openjdk:8-alpine`. See:
  <https://github.com/apache/spark/blob/v2.4.4/resource-managers/kubernetes/docker/src/main/dockerfiles/spark/Dockerfile#L18>
