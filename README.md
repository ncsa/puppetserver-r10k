# Puppetserver R10K Setup
Basic configuration of r10k.

Note: Assumes that `r10k` is already installed, such as in
[Pupperware](https://github.com/puppetlabs/pupperware).

## Dependencies
* Python version >= 3.6

# Installation
1. `export QS_REPO=https://github.com/ncsa/puppetserver-r10k`
1. (optional - use a different branch)
   1. `export QS_GIT_BRANCH=not-the-main-branch`
1. (optional - set a custom install dir)
   1. `export PUP_R10K_DIR=/etc/puppetlabs/r10k`
1. `curl https://raw.githubusercontent.com/andylytical/quickstart/master/quickstart.sh | bash`

# Configuration
1. `vim "${PUP_R10K_DIR:-/etc/puppetlabs/r10k}"/config.ini`
1. `vim "${PUP_R10K_DIR:-/etc/puppetlabs/r10k}"/r10k.yaml`
