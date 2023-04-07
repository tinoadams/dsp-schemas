#!/bin/env bash
set -eo pipefail

# This script is used to run a command for each subject that has changed since the given release tag.
# The following command will print the name of each subject that has changed since the release tag:
#   scripts/foreach-changed-subject.bash ./subjects prod/1.0 BY_VERSION echo "found changed subject -> "
# If no previous release tag is found ie. the provided release tag is the first for the environment, the given command is run for all subjects.

# set PATH_TO_SUBJECTS and error out if not provided
PATH_TO_SUBJECTS=$(realpath "${1:?Please provide PATH_TO_SUBJECTS as first argument}"); shift
# set RELEASE_TAG and error out if not provided
RELEASE_TAG="${1:?Please provide RELEASE_TAG as second argument}"; shift
# set ORDER and error out if not provided
ORDER="${1:?Please provide ORDER=[BY_VERSION|BY_TIME] as third argument}"; shift

# extract the environment and version from the release tag
ENVIRONMENT=$(dirname "$RELEASE_TAG" | sed 's/\.//g') # dirname "non-prod-1.1" return '.' but we want ENV to be empty
[ -z "$ENVIRONMENT" ] && { echo "Unable to extract environment from release tag eg. 'prod/1.0': $RELEASE_TAG"; exit 2; }
VERSION=$(basename "$RELEASE_TAG")
[ -z "$VERSION" ] && { echo "Unable to extract version from release tag eg. 'prod/1.0': $RELEASE_TAG"; exit 2; }
GIT_REPO_ROOT=$(git rev-parse --show-toplevel)
RELATIVE_PATH_TO_SUBJECTS=$(sed "s|^$GIT_REPO_ROOT/||" <<< "$PATH_TO_SUBJECTS")

# debug output
echo "BY_VERSION"
git tag -l --sort=version:refname "$ENVIRONMENT/*"
echo "-----------"
echo "BY_TIME"
git tag -l --sort=creatordate "$ENVIRONMENT/*"

echo "Finding version tag before: $RELEASE_TAG"
# order tags by version number regardless of when the commit was made
if [ "$ORDER" == "BY_VERSION" ]; then
  echo "Ordering tags by version number"
  # find the version tag for the environment before this version eg.
  #   prod/1.0  <- line is not in grep output
  #   prod/1.1  <- PREVIOUS_VERSION_TAG (head -n 1)
  #   prod/1.2  <- grep matched RELEASE_TAG
  #   prod/1.3  <- line is not in grep output
  # grep -B 1 shows the matching line and the line before
  # https://stackoverflow.com/questions/14273531/how-to-sort-git-tags-by-version-string-order-of-form-rc-x-y-z-w
  PREVIOUS_VERSION_TAG=$(git tag -l --sort=version:refname "$ENVIRONMENT/*" | grep -B 1 -- "$RELEASE_TAG" | head -n 1 || true)
# strictly order tags by when the commit was made
elif [ "$ORDER" == "BY_TIME" ]; then
  echo "Ordering tags by time"
  # find the version tag for the environment before this version eg.
  #   prod/1.0  <- line is not in grep output
  #   prod/1.2  <- PREVIOUS_VERSION_TAG (head -n 1)
  #   prod/1.1  <- grep matched RELEASE_TAG
  #   prod/1.3  <- line is not in grep output
  # grep -B 1 shows the matching line and the line before
  # https://stackoverflow.com/questions/6269927/how-can-i-list-all-tags-in-my-git-repository-by-the-date-they-were-created
  PREVIOUS_VERSION_TAG=$(git tag -l --sort=creatordate "$ENVIRONMENT/*" | grep -B 1 -- "$RELEASE_TAG" | head -n 1 || true)
else
  echo "Unknown ordering [BY_VERSION|BY_TIME]: $ORDER"
  exit 1
fi

# list all subjects if no previous version tag exists ie. this is the first release for the environment
if [ -z "$PREVIOUS_VERSION_TAG" ] || [ "$PREVIOUS_VERSION_TAG" == "$RELEASE_TAG" ]; then
  echo "No previous version tag found for $RELEASE_TAG, listing all subjects"

  # find all sub-directories starting with a letter and execute the given command
  for subject_dir in "$PATH_TO_SUBJECTS"/[a-zA-Z]*; do
    if [ -d "$subject_dir" ]; then
      "$@" "$ENVIRONMENT" "$VERSION" "$subject_dir"
    fi
  done
  exit 0
fi

# find changed subjects between the PREVIOUS_VERSION_TAG and RELEASE_TAG eg.
#   M  subjects/test-subject/value.avsc
#   M  subjects/other-subject/value.avsc
# then run the given command for each subject passing as arguments the environment, version and subject directory ($@ ...)
echo "Finding changed subjects between '$PREVIOUS_VERSION_TAG' and '$RELEASE_TAG'"
git diff --name-status "$RELEASE_TAG..$PREVIOUS_VERSION_TAG" \
    | awk '{print $2}' \
    | grep -E "^$RELATIVE_PATH_TO_SUBJECTS/" \
    | while read file; do
        pushd "$PATH_TO_SUBJECTS/.." > /dev/null
        [ -f "$file" ] && realpath "$(dirname "$file")" || echo "DELETED"
        popd > /dev/null
      done \
    | grep -v '^DELETED$' \
    | sort -u \
    | while read subject_dir; do
        "$@" "$ENVIRONMENT" "$VERSION" "$subject_dir"
      done