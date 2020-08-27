# Puppetserver R10K Setup
Basic configuration of r10k.

Note: Assume r10k is already installed, such as in
[Pupperware](https://github.com/puppetlabs/pupperware).

## Dependencies
* Python version >= 3.6

# Installation
1. `export PUP_R10K_DIR=/etc/puppetlabs/r10k`
1. `git clone https://github.com/ncsa/puppetserver-r10k.git $PUP_R10K_DIR`
1. (optional) `vim $PUP_R10K_DIR/config.ini`
1. (optional) `export PY3_PATH=</path/to/python3>`
1. `$PUP_R10K_DIR/setup.sh`
