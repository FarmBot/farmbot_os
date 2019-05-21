#!/bin/bash
# Check that a token is available
if [ -z "$SLACK_TOKEN" ]; then
    echo "Please export a SLACK_TOKEN in your environment"
    exit -1
fi

# Check that all exes are available
if [ -z $(command -v jq) ]; then
    echo "jq not available" 
    exit -1
fi

if [ -z $(command -v fwup) ]; then
    echo "fwup not available" 
    exit -1
fi

if [ -z $(command -v awk) ]; then
    echo "awk not available" 
    exit -1
fi

if [ -z $(command -v awk) ]; then
    echo "curl not available" 
    exit -1
fi

# Parse command line options
while getopts i: option
do  case "${option}" in
        i) FIRMWARE_FILE=${OPTARG};;
        [?]) echo "?usage: $0 -i /path/to/firmware.fw"
             exit -1;;
    esac
done

# Make sure required options were supplied.
if [ -z "$FIRMWARE_FILE" ]; then
      echo "usage: $0 -i /path/to/firmware.fw"
      exit -1;
fi

# Get meta about the firmware file 
FW_META=$(fwup -m -i $FIRMWARE_FILE)

# Create the post payload
POST_DATA=$(jq -n \
    --arg meta_uuid $(grep 'meta-uuid' <<< $FW_META | awk -F"=" '{ print $2}') \
    --arg meta_version "$(grep 'meta-version' <<< $FW_META | awk -F"=" '{ print $2}')" \
    --arg meta_vcs_identifier "$(grep 'meta-vcs-identifier' <<< $FW_META | awk -F"=" '{ print $2}')" \
    --arg meta_platform "$(grep 'meta-platform' <<< $FW_META | awk -F"=" '{ print $2}')" \
    --arg meta_creation_date "$(grep 'meta-creation-date' <<< $FW_META | awk -F"=" '{ print $2}')" \
    --arg meta_misc "$(grep 'meta-misc' <<< $FW_META | awk -F"=" '{ print $2}')" \
    --arg slack_channel "C41SHHGQ5" \
    '{channel: $slack_channel, as_user: true, blocks: [
        {type: "section", block_id: "text1", text: {type: "mrkdwn", text: "*A new FarmBot Firmware is available*"}}, 
        {type: "context", elements: [
            {type: "mrkdwn", text: "*UUID:*"},
            {type: "mrkdwn", text: $meta_uuid}
        ]},
        {type: "context", elements: [
            {type: "mrkdwn", text: "*Version:*"},
            {type: "mrkdwn", text: $meta_version}
        ]},
        {type: "context", elements: [
            {type: "mrkdwn", text: "*Git sha:*"},
            {type: "mrkdwn", text: $meta_vcs_identifier}
        ]},
        {type: "context", elements: [
            {type: "mrkdwn", text: "*Misc:*"},
            {type: "mrkdwn", text: $meta_misc}
        ]},
        {type: "context", elements: [
            {type: "mrkdwn", text: "*Platform:*"},
            {type: "mrkdwn", text: $meta_platform}
        ]},
        {type: "context", elements: [
            {type: "mrkdwn", text: "*Creation Date:*"},
            {type: "mrkdwn", text: $meta_creation_date}
        ]}
    ]}')

curl -s -H "Authorization: Bearer ${SLACK_TOKEN}" \
    -H "Content-Type: application/json; charset=utf-8" \
    -d "$POST_DATA" \
    -X POST https://slack.com/api/chat.postMessage | jq -e
