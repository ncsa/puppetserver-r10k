#!/bin/bash


BASE=/etc/puppetlabs/r10k

###
# FUNCTIONS
###

load_config() {
    # set the following variables from the config file
    # r10k
    # pidfile
    # logdir
    eval $( sed -n -e 's/ //g' -e '/^[a-zA-Z]/p' "$BASE"/config.ini )
    LOGFILE="${logdir}"/$(date +%s)
}

die() {
    echo "ERROR - $*"
    exit 99
}


get_Lock() {
    exec 200>$pidfile
    flock --nonblock --exclusive 200 || die "unable to acquire lock - process already running?"
    pid=$$
    echo $pid 1>&200
}


release_Lock() {
    flock --unlock 200 || exit 1
}


check_Errors() {
    tmpfn=$( mktemp )
    grep -i error "$LOGFILE" \
    | grep -v \
      -e '/[^/]*error[^/]*\.pp' \
      -e 'HEAD is now at' \
      -e '[a-zA-Z0-9_]error' \
      -e 'error[a-zA-Z0-9_]' \
      -e 'pe_license' \
      -e 'title patterns that use procs are not supported' \
    >"$tmpfn"
    if [[ -s "$tmpfn" ]] ; then
        cat "$tmpfn"
        echo
        echo "For more details, see: '$LOGFILE'"
        echo
    fi
    rm -rf "$tmpfn"
}


#rk_323_workaround() {
#    # https://tickets.puppetlabs.com/browse/RK-323
#    rm -rf /etc/puppetlabs/code/* /var/cache/r10k
#}


clean_Old_Logs() {
    find "$logdir" -mtime +30 -delete
}


###
# Start actual work
###

load_config
echo "r10k: $r10k"
echo "pidfile: $pidfile"
echo "logdir: $logdir"
echo "LOGFILE: $LOGFILE"
die "FORCED EXIT"

# If any cmdline paramters, run regular r10k and exit
if [[ $# -gt 0 ]] ; then
$r10k "$@"
exit $?
fi

# Otherwise, run deploy environment

mkdir -p "$logdir"

get_Lock

#rk_323_workaround

$r10k deploy environment -p -v debug2 &>"$LOGFILE"

release_Lock

check_Errors

clean_Old_Logs
