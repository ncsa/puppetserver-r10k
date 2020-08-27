#!/bin/bash

die() {
    printf 'FATAL: %s\n' "$*" >&2
    exit 1
}

set -x

# Get path to parts depot
if [[ -n "$PUP_CUSTOM_DIR" ]] ; then
    DIRPATH="$PUP_CUSTOM_DIR/r10k/postrun_parts"
else
    # Fall back to execution path
    DIRPATH="$( dirname "$0" )/postrun_parts"
fi

# Ensure run-parts is installed
RP=$(which run-parts)
if [[ -z "$RP" ]] ; then
    die "run-parts not found"
fi

export PUP_DEFAULT_ENV=production

# test run-parts
# run-parts on debian 16.x expects regex to select files to run
# run-parts on CentOS 7.x doesn't support the regex option
RP_regex=--regex='^[0-9]'
$RP --test $RP_regex "$DIRPATH" &>/dev/null || RP_regex=

$RP --verbose $RP_regex "$DIRPATH"
