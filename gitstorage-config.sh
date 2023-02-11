#!/bin/bash

# used in
# https://github.com/tomekwlod/tomekwlod.github.io

GITSTORAGESOURCE="git@github.com:tomekwlod/gitstorage.git"

GITSTORAGETARGETDIR="github-tomekwlod.github.io"

GITSTORAGELIST=(
    ".env::${GITSTORAGETARGETDIR}/.env"
    "gitstorage-config.sh::${GITSTORAGETARGETDIR}/gitstorage-config.sh"
)
