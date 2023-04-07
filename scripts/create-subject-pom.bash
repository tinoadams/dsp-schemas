#!/bin/env bash
set -eo pipefail

# This script is used to create a new Maven project based on a templated pom.xml for any given subject.
# The following command will create a Maven project version '0.0-snapshot' for the 'test-topic' subject:
#   scripts/create-subject-pom.bash ./target "0.0-snapshot" ./subjects/test-topic
# The directory of the newly created Maven project is output by this script.

# set TARGET_LOCATION and error out if not provided
TARGET_LOCATION=$(realpath "${1:?Please provide TARGET_LOCATION as first argument}")
# set SUBJECT_PACKAGE_VERSION and error out if not provided
SUBJECT_PACKAGE_VERSION="${2:?Please provide SUBJECT_PACKAGE_VERSION as second argument}"
# set AVRO_SD_LOCATION and error out if not provided
AVRO_SD_LOCATION=$(realpath "${3:?Please provide AVRO_SD_LOCATION as third argument}")
# error if the directory does not exist
[ -d "$AVRO_SD_LOCATION" ] || { echo "Missing Avro schema definition directory: $AVRO_SD_LOCATION"; exit 2; }
# the name of the java package is the subject name withouth key/value suffix
SUBJECT_PACKAGE_NAME="$(basename "$AVRO_SD_LOCATION")"
# set TARGET_LOCATION
PACKAGE_LOCATION="$TARGET_LOCATION/$SUBJECT_PACKAGE_NAME"

pushd "$(dirname "$0")" > /dev/null
echo "Creating POM for subject: $SUBJECT_PACKAGE_NAME ($PACKAGE_LOCATION)" >&2

# Remove the old package build directory and create a new one
rm -rf "$PACKAGE_LOCATION" || true
mkdir -p "$PACKAGE_LOCATION"

# create a pom.xml in the build directory using the template by replacing placeholders using envsubst
export TEMPLATE_SUBJECT_PACKAGE_NAME=$SUBJECT_PACKAGE_NAME
export TEMPLATE_SUBJECT_PACKAGE_VERSION=$SUBJECT_PACKAGE_VERSION
export TEMPLATE_AVRO_FILES_LOCATION=$AVRO_SD_LOCATION
envsubst '$TEMPLATE_SUBJECT_PACKAGE_NAME $TEMPLATE_SUBJECT_PACKAGE_VERSION $TEMPLATE_AVRO_FILES_LOCATION' \
    < templates/pom.xml \
    > "$PACKAGE_LOCATION/pom.xml"

# return the path to the pom.xml
echo "$PACKAGE_LOCATION"