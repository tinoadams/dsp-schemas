#!/bin/env bash
set -eo pipefail

# Validate/register key and value Avro schema definitions in the given directory against the schema registry

# set SCHEMA_REGISTRY_URL and error out if not provided
export SCHEMA_REGISTRY_URL="${1:?Please provide SCHEMA_REGISTRY_URL as first argument}"
# set MODE, pass "register" as third argument to register the schema with the schema registry eg register-subject.bash http://localhost:8081 "register" ./subjects/xyz
export MODE="${2:?Please provide MODE [validate|register] as second argument}"
# set AVRO_SD_LOCATION and error out if not provided
export AVRO_SD_LOCATION="$(realpath "${3:?Please provide AVRO_SD_LOCATION as third argument}")"
# the name of the subject is the name of the directory containing the Avro schema definitions
export SCHEMA_SUBJECT_PREFIX="$(basename "$AVRO_SD_LOCATION")"

pushd "$(dirname "$0")" > /dev/null
echo "Using schema registry $SCHEMA_REGISTRY_URL"

# find the key and value Avro SD files
for suffix in key value; do
    subject="$SCHEMA_SUBJECT_PREFIX-$suffix"
    avro_file="$AVRO_SD_LOCATION/$suffix.avsc"
    echo "Processing Avro file: $avro_file"
    [ -f "$avro_file" ] || { echo "Missing Avro file: $avro_file"; exit 2; }

    # generate a JSON buffer containing the new schema
    schema_buffer="$(tempfile)"
    echo '{"schema": "'$(sed 's/"/\\"/g' $avro_file)'"}' > "$schema_buffer"

    # validate the new schema against the Confluent Schema Registry
    if [ "$MODE" = "validate" ]; then
        echo "Validating subject: $subject"
        curl -L --silent --show-error --fail -X POST -H "Content-Type: application/vnd.schemaregistry.v1+json" \
            --data "@$schema_buffer" \
            "$SCHEMA_REGISTRY_URL/compatibility/subjects/$subject/versions/latest?verbose=true" | tee "$schema_buffer.out"
        echo ''
        # check if the schema is compatible
        jq -r '.is_compatible' < "$schema_buffer.out" | grep -q true && echo "✅ Schema is compatible" || echo "❌ ERROR: Schema is not compatible"
    fi
    
    # register the new schema with the Confluent Schema Registry
    if [ "$MODE" = "register" ]; then
        echo "Registering subject: $subject"
        curl -L --silent --show-error --fail -X POST -H "Content-Type: application/vnd.schemaregistry.v1+json" \
            --data "@$schema_buffer" \
            "$SCHEMA_REGISTRY_URL/subjects/$subject/versions"
        echo ''
    fi
done
