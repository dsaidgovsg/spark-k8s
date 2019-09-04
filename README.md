# `spark-k8s`

[![Build Status](https://travis-ci.org/guangie88/spark-k8s.svg?branch=master)](https://travis-ci.org/guangie88/spark-k8s)

Travis setup to generate Spark Docker images meant for running in Kubernetes
set-up.

All the built images here are inherently based on `openjdk8` and Alpine as the
official build script builds the Docker image based on that.

Additionally, all the built images are currently built with Hadoop and Hive
support, and images that are using Hadoop 3 for Spark 2.Y.Z are automatically
applied with unofficial patch for Hive JAR to make it work with Hadoop 3. The
unofficial patch can be found
[here](https://github.com/guangie88/hive-exec-jar).

## How to Apply Travis Template

For Linux user, you can download Tera CLI v0.2 at
<https://github.com/guangie88/tera-cli/releases> and place it in `PATH`.

Otherwise, you will need `cargo`, which can be installed via
[rustup](https://rustup.rs/).

Once `cargo` is installed, simply run `cargo install tera-cli --version=^0.2.0`.

## Note

For the build, if `WITH_PYSPARK` is set to `true`, then `python` and
`python-setuptools` should be `apt` installed.
