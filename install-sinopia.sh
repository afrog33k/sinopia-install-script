#!/bin/bash
# =============================================================================
#
# FILE: install-sinopia.sh
#
# USAGE: bash install-sinopia.sh
#
# DESCRIPTION: This script does the following:
#   1. Add the chris-lea:node.js ppa
#   2. Install nodejs and build-essential
#   3. Create a "sinopia" user with password "sinopia"
#   4. Install `sinopia` and `forever` under the "sinopia" user
#   5. Start `sinopia` with `forever`
#   6. Add a crontab to start `sinopia` on server restart
#
# NOTES:
#   - Bash options
#     - `-e` = failfast on non-zero return code
#     - `-x` = output bash commands to console - helpful when debugging
#
# =============================================================================

set -ex

# Add the necessary apt repos for our system dependencies
sudo apt-get update
sudo apt-get install python-software-properties -y
sudo add-apt-repository ppa:chris-lea/node.js -y
sudo apt-get update

# Install system dependencies
sudo apt-get install nodejs build-essential -y

# Create a sinopia user
sudo su -c "yes '' | adduser sinopia"
sudo su -c "echo -e 'sinopia\nsinopia' | passwd sinopia"

# Install `sinopia` and `forever`
sudo su sinopia -c 'cd ${HOME} && npm install sinopia forever'

# Add `sinopia` configuration
sudo wget \
    --no-check-certificate -H \
    https://github.com/christopherdcunha/sinopia-install-script/raw/master/sinopia-config.yaml \
    -O /home/sinopia/sinopia-config.yaml
sudo chown sinopia: /home/sinopia/sinopia-config.yaml

# Launch `sinopia` with `forever` and the right configuration
sudo su sinopia -c '
    /home/sinopia/node_modules/.bin/forever start \
    /home/sinopia/node_modules/.bin/sinopia --listen 0.0.0.0:4873 \
    --config /home/sinopia/sinopia-config.yaml'

# Make sure that `sinopia` restarts when the server restarts, i.e. install the
# same command above as a cronjob.
sudo su sinopia -c 'echo "@reboot /home/sinopia/node_modules/.bin/forever start /home/sinopia/node_modules/.bin/sinopia --listen 0.0.0.0:4873 --config /home/sinopia/sinopia-config.yaml" | crontab'
