#!/bin/env bash
set -eo pipefail

# Given a directory containing Avro schema definitions, this script builds the Java serde packages

# set SCHEMA_PACKAGE_VERSION and error out if not provided
SCHEMA_PACKAGE_VERSION="${1:?Please provide SCHEMA_PACKAGE_VERSION as first argument}"
# set AVRO_SD_LOCATION and error out if not provided
AVRO_SD_LOCATION="$(realpath "${2:?Please provide AVRO_SD_LOCATION as second argument}")"
# the name of the java package is the subject name withouth key/value suffix
SCHEMA_PACKAGE_NAME="$(basename "$AVRO_SD_LOCATION")"

pushd "$(dirname "$0")" > /dev/null
echo "Building $SCHEMA_PACKAGE_NAME ($AVRO_SD_LOCATION)"

# Remove the old package build directory and create a new one
rm -rf "target/$SCHEMA_PACKAGE_NAME" || true
mkdir -p "target/$SCHEMA_PACKAGE_NAME"

# create a pom.xml in the build directory using the template by replacing placeholders using envsubst
export TEMPLATE_SCHEMA_PACKAGE_NAME=$SCHEMA_PACKAGE_NAME
export TEMPLATE_SCHEMA_PACKAGE_VERSION=$SCHEMA_PACKAGE_VERSION
envsubst '$TEMPLATE_SCHEMA_PACKAGE_NAME $TEMPLATE_SCHEMA_PACKAGE_VERSION' < templates/pom.xml > "target/$SCHEMA_PACKAGE_NAME/pom.xml"

# build the package
pushd "target/$SCHEMA_PACKAGE_NAME" > /dev/null
mvn package
popd > /dev/null
