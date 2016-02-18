#!/usr/bin/env bash
# see commentary on this practice at
# http://blog.howareyou.com/post/66375371138/ruby-apps-best-practices

set -e

bundle config
echo
bundle install --binstubs .binstubs --jobs=3 --retry=2
echo
bundle package --all --quiet

