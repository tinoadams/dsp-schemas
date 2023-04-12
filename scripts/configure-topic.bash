#!/bin/env bash
set -eo pipefail

# This script is used to configure a Kafka topic based on two configuration files (create.properties, config.properties)
# The following command will create a topic named 'test-topic' with the configuration defined in the 'create.properties' file
# and then alter the topic with the configuration defined in the 'config.properties' file:
#   scripts/configure-topic.bash ./topics/test-topic

# load environment variables from .env file
source .env

# set TOPIC_CONFIG_LOCATION and error out if not provided
TOPIC_CONFIG_LOCATION=$(realpath "${1:?Please provide TOPIC_CONFIG_LOCATION as first argument}")
# error if the directory does not exist
[ -d "$TOPIC_CONFIG_LOCATION" ] || { echo "Missing topic config directory: $TOPIC_CONFIG_LOCATION"; exit 2; }
# determine topic name based on the directory name
TOPIC_NAME="$(basename "$TOPIC_CONFIG_LOCATION")"
TOPIC_CREATE_FILE="$TOPIC_CONFIG_LOCATION/create.properties"
TOPIC_CONFIG_FILE="$TOPIC_CONFIG_LOCATION/config.properties"

# execute a command in the kafka-cli docker container
function kafka_cli() {
    COMMAND_NAME=$1
    shift
    docker run -ti --net host --rm --entrypoint "$COMMAND_NAME" \
        -v "$PWD":"$PWD" \
        "confluentinc/cp-server:$ENV_CONFLUENT_PLATFORM_VERSION" \
        --command-config "$PWD/kafka-cli-client.properties" \
        --bootstrap-server "$ENV_BOOTSTRAP_SERVERS" \
        $@
}

# determine if we need to create or alter the topic by checking whether the topic exists
echo "Checking if topic exists: $TOPIC_NAME"
if ! kafka_cli kafka-configs --describe --entity-type topics --entity-name "$TOPIC_NAME"; then
    echo "Failed to describe topic, will create it based on: $TOPIC_CREATE_FILE"
    # read topic config file and replace new lines with '--' to pass it as a single argument to kafka-topics
    TOPIC_ARGS=$(grep -vE '^#' "$TOPIC_CREATE_FILE" | sed ':a;N;$!ba;s/\n/ --/g')
    kafka_cli kafka-topics --create --if-not-exists --topic "$TOPIC_NAME" --$TOPIC_ARGS
    sleep 5
fi

# turn the `kafka-configs --describe` output into a list of keys eg.
#    Dynamic configs for topic request-topic are:
#      confluent.value.schema.validation=true sensitive=false synonyms={DYNAMIC_TOPIC_CONFIG:confluent.value.schema.validation=true}
CURRENT_CONFIGS=$(mktemp)
kafka_cli kafka-configs --describe --entity-type topics --entity-name "$TOPIC_NAME" \
    | awk '{print $1}' \
    | { grep '=' || true; } \
    | sed 's/=.*//g' \
    | sort -u \
    > "$CURRENT_CONFIGS" || { echo "Failed to get current topic config"; cat "$CURRENT_CONFIGS"; exit 2; }

# extract the keys from the topic config file "$TOPIC_CONFIG_FILE" eg.
#    confluent.key.schema.validation=true
#    confluent.key.subject.name.strategy=io.confluent.kafka.serializers.subject.TopicRecordNameStrategy
NEW_CONFIGS=$(mktemp)
grep -vE '^#' "$TOPIC_CONFIG_FILE" | sed 's/=.*//g' | sort -u > "$NEW_CONFIGS"

# Compare existing configs for the topic with the new configs
MISSING_LINES=$(mktemp)
comm --nocheck-order -23 "$CURRENT_CONFIGS" "$NEW_CONFIGS" > "$MISSING_LINES" || { echo "Failed to compare topic configs"; cat "$MISSING_LINES"; exit 2; }
if [ "$(wc -l < "$MISSING_LINES")" -gt 0 ]; then
    echo "The topic currently has configs set which are missing in the config file ($TOPIC_CONFIG_FILE), this script will not automatically remove configs:"
    cat "$MISSING_LINES"
    exit 2
fi

# read topic config file and replace new lines with commas
TOPIC_ARGS=$(grep -vE '^#' "$TOPIC_CONFIG_FILE" | sed ':a;N;$!ba;s/\n/,/g')
# alter topic config
echo "Altering topic config: $TOPIC_NAME ($TOPIC_CONFIG_FILE)"
kafka_cli kafka-configs --alter --entity-type topics --entity-name "$TOPIC_NAME" --add-config $TOPIC_ARGS
# output the new config
kafka_cli kafka-configs --describe --entity-type topics --entity-name "$TOPIC_NAME"