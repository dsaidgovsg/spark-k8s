#!/usr/bin/env sh
if ! which tera >/dev/null; then
    echo "Run \"cargo install tera-cli\" to install tera first.\nLinux users may download from https://github.com/guangie88/tera-cli/releases instead."
    return 1
fi

tera -f .travis.yml.tmpl --yaml vars.yml > .travis.yml && \
echo "Successfully applied template into .travis.yml!"
