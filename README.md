# `spark-k8s`

![CI
Status](https://img.shields.io/github/workflow/status/dsaidgovsg/spark-k8s/CI/master?label=CI&logo=github&style=for-the-badge)

CI setup to generate Spark Docker images meant for running in Kubernetes
sset-up.

The current set-up builds for the following Spark versions with Kubernetes on
Debian:

- `3.3.0`
- `3.2.2`
- `3.1.3`
- `3.4.0`

## Note

(R builds are temporarily suspended due to keyserver issues at current time.)

Build image for Spark 3.4.0 is Ubuntu based because openjdk is deprecated and
going forward the official Spark repository uses `eclipse-temurin:<java>-jre`
where slim variants of jre images are not available at the moment.

All the build images with Spark before v3.4.0 are Debian based as the official 
Spark repository now uses `openjdk:<java>-jre-slim-buster` as the base image 
for Kubernetes build. Because currently the official Dockerfiles do not pin 
the Debian distribution, they are incorrectly using the latest Debian `bullseye`,
which does not have support for Python 2, and its Python 3.9 do not work well 
with PySpark.

Hence some Dockerfile overrides are in-place to make sure that Spark 2 builds
can still work.

Because of the fast-changing nature of the Spark repository, this set-up might
contain inevitable breaking changes. As such, the build Docker images are
additionally tagged with this repository distribution tag version as prefix,
such as `v3_3.3.0_hadoop-3.3.2_scala-2.12_java_11`.

The older distribution tag version will separately go into a different Git
branch for clarity.

For details on the distribution versions, check [CHANGELOG.md](CHANGELOG.md).

## Test Self-Build

For quick testing of local build, you should do the following commands:

```bash
export IMAGE_NAME=spark-k8s
export SELF_VERSION="v3"
export SCALA_VERSION="2.12"
export SPARK_VERSION="3.3.0"
export HADOOP_VERSION="3.3.2"
export JAVA_VERSION="11"
export WITH_HIVE="true"
export WITH_PYSPARK="true"
bash make-distribution.sh

# Alternatively, just run ./build.sh, which contains the above commands
./build.sh
```

## How to Apply Template

For Linux user, you can download Tera CLI v0.4 at
<https://github.com/guangie88/tera-cli/releases> and place it in `PATH`.

Otherwise, you will need `cargo`, which can be installed via
[rustup](https://rustup.rs/).

Once `cargo` is installed, simply run `cargo install tera-cli --version=^0.4.0`.

Always make changes in `templates/ci.yml.tmpl` since the template will be
applied onto `.github/workflows/ci.yml`.

Run `templates/apply-vars.sh` to apply the template once `tera-cli` has been
installed.
