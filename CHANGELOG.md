# CHANGELOG

## v3

- (Temporarily drop support for R due to keyserver issues)
- Only supports for for 3.1.3, 3.2.2, 3.3.0, 3.4.1 (dropped 2.4.8).
- Supports both Java 8 and 11 for Spark 3 builds.
- Add Ubuntu-based image since the migration to eclipse-temurin for jre image source.

## v2

- Add support up to 3.1.1 for Spark 3.y.z.
- Drop 2.4.5 and 2.4.6 and only support 2.4.7 as the last supported 2.4.z version.
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
