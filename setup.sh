#!/bin/bash

YES=0
NO=1
DEBUG=$YES
VERBOSE=$YES


croak() {
  echo "ERROR $*" >&2
  kill -s TERM $BASHPID
  exit 99
}


log() {
  [[ $VERBOSE -eq $YES ]] || return
  echo "INFO $*" >&2
}


debug() {
  [[ $DEBUG -eq $YES ]] || return
  echo "DEBUG (${BASH_SOURCE[1]} [${BASH_LINENO[0]}] ${FUNCNAME[1]}) $*"
}


get_os_family() {
  [[ $DEBUG -eq $YES ]] && set -x
  local _osfam=$( cat /etc/*elease* | awk '
    BEGIN{IGNORECASE=1}
    /ubuntu|debian/{print "deb"; exit 0;}
    /redhat|centos/{print "rhel"; exit 0;}
  ')
  [[ -z "$_osfam" ]] && croak "Unable to determine OS family"
  echo "$_osfam"
}


ensure_prereqs() {
  # r10k postscript needs run-parts
  [[ $DEBUG -eq $YES ]] && set -x
  case "$OSFAMILY" in
    deb)
      _apt_install debianutils
      ;;
    rhel)
      _yum_install crontabs
      ;;
    *) croak "Unknown OS family for ensure_prereqs"
  esac
}


_apt_install() {
  [[ $DEBUG -eq $YES ]] && set -x
  local _rc
  apt update
  apt install -y "$@"
  _rc=$?
  apt clean
  rm -rf /var/lib/apt/lists/*
  return $_rc
}


_yum_install() {
  [[ $DEBUG -eq $YES ]] && set -x
  local _rc
  yum -y install "$@"
  _rc=$?
  yum clean all
  return $_rc
}


set_install_dir() {
  [[ $DEBUG -eq $YES ]] && set -x
  INSTALL_DIR=/etc/puppetlabs/r10k
  [[ -n "$PUP_R10K_DIR" ]] && INSTALL_DIR="$PUP_R10K_DIR"

  [[ -z "$INSTALL_DIR" ]] \
  && croak "Unable to determine install base. Try setting 'PUP_R10K_DIR' env var."

  [[ -d "$INSTALL_DIR" ]] || mkdir -p $INSTALL_DIR

  [[ -d "$INSTALL_DIR" ]] \
  || croak "Unable to find or create script dir: '$INSTALL_DIR'"
}


ensure_python() {
  [[ $DEBUG -eq $YES ]] && set -x
  PYTHON=$(which python3) 2>/dev/null
  [[ -n "$PY3_PATH" ]] && PYTHON="$PY3_PATH"
  [[ -z "$PYTHON" ]] && croak "Unable to find Python3. Try setting 'PY3_PATH' env var."
  PYTHON=$( realpath -e "$PYTHON" )
  [[ -x "$PYTHON" ]] || croak "Found Python3 at '$PYTHON' but it is not executable."
  "$PYTHON" "$BASE/require_py_v3.py" || croak "Python version too low"
  "$PYTHON" -m ensurepip
}


setup_python_venv() {
  [[ $DEBUG -eq $YES ]] && set -x
  venvdir="$INSTALL_DIR/.venv"
  [[ -d "$venvdir" ]] || {
    "$PYTHON" -m venv "$venvdir"
    PIP="$venvdir/bin/pip"
    "$PIP" install --upgrade pip
    "$PIP" install -r "$BASE/requirements.txt"
  }
  V_PYTHON="$venvdir/bin/python"
  [[ -x "$V_PYTHON" ]] || croak "Something went wrong during python venv install."
}


set_shebang_path() {
  [[ $DEBUG -eq $YES ]] && set -x
  newpath="$1"
  shift
  sed -i -e "1 c \#\!$newpath" "$@"
}


install_scripts() {
  [[ $DEBUG -eq $YES ]] && set -x

  # Update bash scripts (backup existing)
  for fn in postrun.sh r10k.sh ; do
    install -vbC --suffix="$TS" -t "$INSTALL_DIR" "$BASE/$fn"
  done

  # Update postrun scripts (backup existing)
  local _tgtdir="$INSTALL_DIR/postrun_parts"
  mkdir -p "$_tgtdir"
  find "$BASE/postrun_parts" -name '*.py' -print \
  | while read ; do
      set_shebang_path "$V_PYTHON" "$REPLY"
      install -vbC --suffix="$TS" -t "$_tgtdir" "$REPLY"
  done

  # Install config files (ignore existing)
  for fn in config.ini r10k.yaml ; do
    [[ -f "$INSTALL_DIR/$fn" ]] || cp "$BASE/$fn" "$INSTALL_DIR"
  done
}


[[ $DEBUG -eq $YES ]] && set -x
BASE=$(readlink -e $( dirname $0 ) )
TS=$(date +%s)

OSFAMILY=$( get_os_family )

ensure_prereqs

set_install_dir
log "Installing into: '$INSTALL_DIR'"

ensure_python
debug "Got PYTHON: '$PYTHON'"

setup_python_venv

install_scripts
