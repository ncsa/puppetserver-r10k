#!/usr/bin/env python3

import sys

# Require python 3
if sys.version_info.major < 3:
    msg = "Requires python version 3; attempted with version '{}'".format(
        sys.version_info.major
        )
    raise UserWarning( msg )

import logging
logfmt = '%(levelname)s:%(funcName)s[%(lineno)d] %(message)s'
#loglvl = logging.INFO
loglvl = logging.DEBUG
logging.basicConfig( level=loglvl, format=logfmt )

import configparser
import os
import pathlib
import subprocess

# Module level (global) settings
resources = {}

def get_install_dir():
    key = 'install_dir'
    if key not in resources:
        resources[ key ] = pathlib.Path(
            os.getenv( 'PUP_R10K_DIR', default='/etc/puppetlabs/r10k' ) )
    return resources[ key ]


def get_cfg():
    key = 'cfg'
    if key not in resources:
        base = get_install_dir()
        confdir = get_install_dir() / 'config.ini'
        cfg = configparser.ConfigParser()
        cfg.read( confdir )
        resources[ key ] = cfg
    return resources[ key ]


def get_puppet_environmentpath():
    key = 'puppet_environmentpath'
    if key not in resources:
        cfg = get_cfg()
        cmd = [ cfg['PUPPET']['puppet'] ]
        cmd.extend( 'config print environmentpath --section master'.split() )
        proc = subprocess.run( cmd,
                               stdout=subprocess.PIPE,
                               check=True,
                               timeout=30
                             )
        resources[ key ] = pathlib.Path( proc.stdout.decode().strip() )
    return resources[ key ]



# Get list of env dirs
envpath = get_puppet_environmentpath()
envdirs = [ f for f in envpath.iterdir() if f.is_dir() ]
logging.debug( f"ENVDIRS: {envdirs}" )

# Update environment isolation
cfg = get_cfg()
PUPPET = pathlib.Path( cfg['PUPPET']['puppet'] )
cmd = [ PUPPET, 'generate', 'types', '--environment' ]
for dir in envdirs:
    logging.debug( f"about to run environment isolation for '{dir.name}'" )
    proc = subprocess.run( cmd + [dir.name], 
                           check=True,
                           timeout=30
                         )
