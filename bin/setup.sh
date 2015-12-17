#!/usr/bin/env bash
# see commentary on this practice at
# http://blog.howareyou.com/post/66375371138/ruby-apps-best-practices

set -e

bundle config
echo
bundle install --binstubs .binstubs --clean --jobs=3 --retry=3 --without integration test production
echo
bundle package --all --quiet
echo
bundle show --paths | sort

# try to sync private configs
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

