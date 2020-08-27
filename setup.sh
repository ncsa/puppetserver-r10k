#!/bin/bash

DEBUG=1


die() {
    echo "ERROR: $*" >&2
    exit 2
}


set_shebang_path() {
    [[ $DEBUG -gt 0 ]] && set -x
    newpath="$1"
    shift
    sed -i -e "1 c \#\!$newpath" "$@"
}


[[ $DEBUG -gt 0 ]] && set -x

# Get install directory
BASE=$(readlink -e $( dirname $0 ) ) 
[[ -n "$PUP_R10K_DIR" ]] && BASE="$PUP_R10K_DIR"
[[ -z "$BASE" ]] && die "Unable to determine install base. Try setting PUP_R10K_DIR env var."

# Find python3
[[ -z "$PYTHON" ]] && PYTHON=$(which python3) 2>/dev/null
[[ -n "$PY3_PATH" ]] && PYTHON=$PY3_PATH
[[ -z "$PYTHON" ]] && die "Unable to find Python3. Try setting PY3_PATH env var."

# Verify python is version 3
"$PYTHON" "$BASE/require_py_v3.py" || die "Python version too low"

# Setup python virtual env
venvdir="$BASE/.venv"
[[ -d "$venvdir" ]] || {
    "$PYTHON" -m venv "$venvdir"
    PIP="$venvdir/bin/pip"
    "$PIP" install --upgrade pip
    "$PIP" install --upgrade wheel
    "$PIP" install -r "$BASE/requirements.txt"
}
V_PYTHON="$venvdir/bin/python"
[[ -x "$V_PYTHON" ]] || die "Something went wrong during python venv install."


# Configure r10k postrun scripts to use venv python
find "$BASE/postrun_parts/" -type f -name '*.py' -print \
| while read ; do
    set_shebang_path "$V_PYTHON" "$REPLY"
done


# Install r10k wrapper script
TGT="$BASE/r10k.sh"
SFX=$(date +%s)
sed --in-place="$SFX" -e "/^BASE=/c\BASE=$BASE" "$TGT"
ln -sf "$TGT" "/usr/local/sbin/r10k"
ln -sf "$TGT" "/opt/puppetlabs/bin/r10k"
