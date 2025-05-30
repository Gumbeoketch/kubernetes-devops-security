#!/bin/bash

# Kubesec scan script

# Perform a single API request and store the JSON response
scan_result=$(curl -sSX POST --data-binary @"k8s_deployment_service.yaml" https://v2.kubesec.io/scan)

# Validate if response is JSON
if ! echo "$scan_result" | jq empty 2>/dev/null; then
    echo "Error: Invalid JSON response from Kubesec API."
    echo "$scan_result"
    exit 1
fi

# Extract scan message and score
scan_message=$(echo "$scan_result" | jq -r '.[0].message // "No message returned"')
scan_score=$(echo "$scan_result" | jq -r '.[0].score // empty')

# Check if scan_score is a valid number
if [[ -z "$scan_score" || ! "$scan_score" =~ ^[0-9]+$ ]]; then
    echo "Error: Failed to extract a valid scan score."
    echo "Raw response: $scan_result"
    exit 1
fi

# Kubesec scan result processing
echo "Scan Score: $scan_score"

if [[ "$scan_score" -ge 5 ]]; then #if scan >= 5 it passes
    echo "✅ Kubesec Scan Passed: $scan_message"
else
    echo "❌ Scan Score is $scan_score, which is less than 5. Security check failed."
    exit 1
fi
