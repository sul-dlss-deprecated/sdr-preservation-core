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

# try to symlink private configs
echo
[ -f .env ] && source .env
priv_relpath=${PRIVATE_CONFIG_PATH}
priv_abspath=$(cd ${priv_relpath}; pwd)  # ensure it's an absolute path
if [ -d ${priv_abspath} ]; then
    echo "Found private configs; checking symlinks..."
    configs=$(find ${priv_abspath} -type f)
    for f in ${configs}; do
        priv_filename=$(basename ${f})
        priv_confdir=$(dirname ${f})
        this_confdir=$(echo ${priv_confdir} | sed s/.*config/config/)
        [ ! -d ${this_confdir} ] && mkdir -p ${this_confdir}
        f="${priv_confdir}/${priv_filename}"
        nf=$(echo ${f} | sed s/.*config/config/)
        echo -e "Checking symlink: $f  >  $nf"
        [ ! -s ${nf} ] && ln -s ${f} ${nf}
    done
else
    echo "Could not find private configs in $priv_abspath - check .env"
fi

