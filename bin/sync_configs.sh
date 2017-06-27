#!/usr/bin/env bash

set -e

# try to sync private configs from local clone of private repo.
echo
[ -f .env ] && source .env
priv_relpath=${PRIVATE_CONFIG_PATH}
priv_abspath=$(cd ${priv_relpath}; pwd)  # ensure it's an absolute path
if [ -d ${priv_abspath} ]; then
    echo "Found private configs; updating configs ..."
    rsync -avz --update ${priv_abspath}/config/ config/
else
    echo "Could not find private configs in $priv_abspath - check .env"
fi

