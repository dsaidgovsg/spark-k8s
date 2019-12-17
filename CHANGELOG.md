# CHANGELOG

## v1

- Basic setup for Spark 2.3.4 and Spark 2.4.4.
- Alpine-based image since Spark pre-v3 uses `openjdk:8-alpine`.
  See: <https://github.com/apache/spark/blob/v2.4.4/resource-managers/kubernetes/docker/src/main/dockerfiles/spark/Dockerfile#L18>
