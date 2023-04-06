#!/bin/env bash
set -eo pipefail
pushd "$(dirname "$0")" > /dev/null

# find all sub-directories starting with a letter and execute the given command
for dir in ./subjects/[a-zA-Z]*; do
  if [ -d "$dir" ]; then
    $@ "$dir"
  fi
done