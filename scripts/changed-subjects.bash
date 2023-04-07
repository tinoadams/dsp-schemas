#!/bin/env bash
set -eo pipefail

# # Validate/register key and value Avro schema definitions in the given directory against the schema registry

# set PATH_TO_SUBJECTS and error out if not provided
PATH_TO_SUBJECTS=$(realpath "${1:?Please provide PATH_TO_SUBJECTS as first argument}")
# set RELEASE_TAG and error out if not provided
RELEASE_TAG="${2:?Please provide RELEASE_TAG as second argument}"
# set ORDER and error out if not provided
ORDER="${3:?Please provide ORDER=[BY_VERSION|BY_TIME] as third argument}"

# extract the environment and version from the release tag
ENVIRONMENT=$(dirname "$RELEASE_TAG" | sed 's/\.//g') # dirname "non-prod-1.1" return '.' but we want ENV to be empty
[ -z "$ENVIRONMENT" ] && { echo "Unable to extract environment from release tag eg. 'prod/1.0': $RELEASE_TAG"; exit 2; }
# VERSION=$(basename "$RELEASE_TAG")

# debug output
echo "BY_VERSION" >&2
git tag -l --sort=version:refname "$ENVIRONMENT/*" 1>&2
echo "-----------" >&2
echo "BY_TIME" >&2
git tag -l --sort=creatordate "$ENVIRONMENT/*" 1>&2

# order tags by version number regardless of when the commit was made
if [ "$ORDER" == "BY_VERSION" ]; then
  echo "Ordering tags by version number... finding previous version tag" >&2
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
  echo "Ordering tags by time... finding previous version tag" >&2
  # find the version tag for the environment before this version eg.
  #   prod/1.0  <- line is not in grep output
  #   prod/1.2  <- PREVIOUS_VERSION_TAG (head -n 1)
  #   prod/1.1  <- grep matched RELEASE_TAG
  #   prod/1.3  <- line is not in grep output
  # grep -B 1 shows the matching line and the line before
  # https://stackoverflow.com/questions/6269927/how-can-i-list-all-tags-in-my-git-repository-by-the-date-they-were-created
  PREVIOUS_VERSION_TAG=$(git tag -l --sort=creatordate "$ENVIRONMENT/*" | grep -B 1 -- "$RELEASE_TAG" | head -n 1 || true)
else
  echo "Unknown ordering [BY_VERSION|BY_TIME]: $ORDER" >&2
  exit 1
fi

# list all subjects if no previous version tag exists or the previous version tag is the same as the current tag
if [ -z "$PREVIOUS_VERSION_TAG" ] || [ "$PREVIOUS_VERSION_TAG" == "$RELEASE_TAG" ]; then
  echo "No previous version tag found for $RELEASE_TAG, listing all subjects" >&2

  pushd "$(dirname "$0")" > /dev/null
  ./foreach-subject.bash "$PATH_TO_SUBJECTS" "echo"
  exit 0
fi

# find changed subjects between the latest environment tag and current tag
echo "Finding changed subjects between '$PREVIOUS_VERSION_TAG' and '$RELEASE_TAG'" >&2
git diff --name-status "$RELEASE_TAG..$PREVIOUS_VERSION_TAG" \
    | awk '{print $2}' \
    | grep -E '^subjects' \
    | while read file; do
        pushd "$PATH_TO_SUBJECTS/.." > /dev/null
        realpath "$(dirname "$file")"
        popd > /dev/null
      done \
    | sort -u