#!/bin/env bash
set -eo pipefail

# set PATH_TO_SUBJECTS and error out if not provided
PATH_TO_SUBJECTS="${1:?Please provide PATH_TO_SUBJECTS as first argument}"
# remove first argument
shift

# find all sub-directories starting with a letter and execute the given command
for dir in "$PATH_TO_SUBJECTS"/[a-zA-Z]*; do
  if [ -d "$dir" ]; then
    $@ "$dir"
  fi
done