#!/usr/bin/env bash
set -e
oldrev=$1
newrev=$2

run() {
  [ -x $1 ] && $1 $oldrev $newrev
}

echo files changed: $(git diff $oldrev $newrev --diff-filter=ACDMR --name-only | wc -l)

umask 002

run deploy/before_restart
run deploy/restart && run deploy/after_restart
