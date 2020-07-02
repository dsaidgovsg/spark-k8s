# `spark-k8s`

![CI Status](https://img.shields.io/github/workflow/status/guangie88/spark-k8s/CI/master?label=CI&logo=github&style=for-the-badge)

CI setup to generate Spark Docker images meant for running in Kubernetes sset-up.

The current set-up only builds for Spark v3 preview versions, and should be
updated to support v3 when it comes.

## Note

All the build images here are Debian based as the official Spark repository now
uses `openjdk:8-jdk-slim` as the base image for Kubernetes build.

Because of the fast-changing nature of the Spark repository, this set-up might
contain inevitable breaking changes. As such, the build Docker images are
additionally tagged with this repository distribution tag version as prefix,
such as `v2_2.4.5_hadoop-3.1.0_scala-2.12`.

The older distribution tag version will separately go into a different Git
branch for clarity.

For details on the distribution versions, check [CHANGELOG.md](CHANGELOG.md).

## How to Apply Travis Template

For Linux user, you can download Tera CLI v0.4 at
<https://github.com/guangie88/tera-cli/releases> and place it in `PATH`.

Otherwise, you will need `cargo`, which can be installed via
[rustup](https://rustup.rs/).

Once `cargo` is installed, simply run `cargo install tera-cli --version=^0.4.0`.

Always make changes in `templates/ci.yml.tmpl` since the template will be
applied onto `.github/workflows/ci.yml`.

Run `templates/apply-vars.sh` to apply the template once `tera-cli` has been
installed.
