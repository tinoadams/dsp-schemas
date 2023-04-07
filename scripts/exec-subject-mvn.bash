#!/bin/env bash
set -eo pipefail

# This script is used to run Maven profile goals for a given subject.
# The following command will run Maven profile 'local' to validate and package the 'test-topic' subject as version '0.0-snapshot':
#   scripts/exec-subject-mvn.bash "validate package" "local" "0.0-snapshot" ./subjects/test-topic
# A new Maven project is created based on a templated pom.xml using create-subject-pom.bash.

# set MVN_GOALS and error out if not provided
MVN_GOALS="${1:?Please provide MVN_GOALS as first argument}"
# set MAVEN_PROFILE and error out if not provided
MAVEN_PROFILE="${2:?Please provide MAVEN_PROFILE as second argument}"
# set SUBJECT_PACKAGE_VERSION and error out if not provided
SUBJECT_PACKAGE_VERSION="${3:?Please provide SUBJECT_PACKAGE_VERSION as third argument}"
# set AVRO_SD_LOCATION and error out if not provided
AVRO_SD_LOCATION=$(realpath "${4:?Please provide AVRO_SD_LOCATION as fourth argument}")

# jump to the directory of this script which also contains create-subject-pom.bash
pushd "$(dirname "$0")" > /dev/null
# create-subject-pom.bash returns the directory where the pom.xml was created
pushd "$(./create-subject-pom.bash ../target "$SUBJECT_PACKAGE_VERSION" "$AVRO_SD_LOCATION")" > /dev/null

# run maven to validate the schema
mvn -P "$MAVEN_PROFILE" $MVN_GOALS
