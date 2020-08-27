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

import collections
import configparser
import os
import pathlib
import pprint
import re
import shutil
import subprocess
import yaml

# Custom type for R10K source data
R10KSrc = collections.namedtuple( 'R10KSrc', ['basedir', 'environments'] )

# Module level (global) settings
resources = {}


def get_ignore_list():
    key = 'ignore_list'
    if key not in resources:
        resources[ key ] = [ 'wip_*', 'production' ]
    return resources[ key ]


def get_install_dir():
    key = 'install_dir'
    if key not in resources:
        resources[ key ] = pathlib.Path( 
            os.getenv( 'PUP_CUSTOM_DIR', default='/etc/puppetlabs/local' ) )
    return resources[ key ]


def get_cfg():
    key = 'cfg'
    if key not in resources:
        base = get_install_dir()
        confdir = get_install_dir() / 'config' / 'config.ini'
        cfg = configparser.ConfigParser()
        cfg.read( confdir )
        resources[ key ] = cfg
    return resources[ key ]


def get_r10k_sources():
    ''' Get R10K deploy display YAML output
    '''
    key = 'r10k_sources'
    if key not in resources:
        cfg = get_cfg()
        sources = {}
        cmd = [ cfg['R10K']['r10k'], 'deploy', 'display' ]
        proc = subprocess.run( cmd, 
                               stdout=subprocess.PIPE,
                               stderr=subprocess.PIPE, 
                               check=True,
                               timeout=30
                             )
        data = yaml.safe_load( proc.stdout.decode().strip() )
        logging.debug( 'Raw Data:\n{}\n'.format( pprint.pformat( data ) ) )
        # create r10k resource list
        for s in data[':sources']:
            name = s[':name'].strip(':')
            basedir = s[':basedir'].strip(':')
            sources[name] = R10KSrc( basedir=pathlib.Path( basedir ),
                                     environments=s[':environments'] )
        logging.debug( "SOURCES:\n{}\n".format( pprint.pformat( sources ) ) )
        resources[ key ] = sources
    return resources[ key ]


def run():
    # Get r10k deploy information
    sources = get_r10k_sources()

    # Create list of all unique branch names
    branches = []
    for name, repo in sources.items():
        branches.extend( repo.environments )
    logging.debug( 'r10k_branch_names: {}'.format( pprint.pformat( branches ) ) )

    # Keep env dirs if:
    #   matches any regex in ignore_list
    #   OR
    #   is an r10k deployed environment
    safe_list_strings = set().union( get_ignore_list(), branches )
    # Ignore_list items are regex strings, so convert all rawstrings to regex's
    safe_list = [ re.compile(x) for x in safe_list_strings ]

    # Check children in basedir for each source
    for name,src in sources.items():
        # for each child in basedir
        for child in src.basedir.iterdir():
            purge = False
            if child.is_dir():
                # we only care about directories
                purge = True
                for regexp in safe_list:
                    if regexp.match( child.name ):
                        purge = False
                        break
            if purge:
                logging.info( f"Purge: '{child}'" )
                shutil.rmtree( child )


if __name__ == '__main__':
    run()
