#!/bin/bash
set -euo pipefail

buildkite-agent artifact download test-output.log . --step "run-tests"
cp test-output.log test-output.txt

echo 'TEST OUTPUT CONFIRMATION:'
cat test-output.txt

echo 'Do we even gotta jq?'
jq --version

ATHRO_KEY=$(buildkite-agent secret get ANTHROPIC_API_KEY)

FILE_ID_JSON=$(curl -s -X POST "https://api.anthropic.com/v1/files" \
  -H "x-api-key: $ATHRO_KEY" \
  -H "anthropic-version: 2023-06-01" \
  -H "anthropic-beta: files-api-2025-04-14" \
  -F "file=@test-output.txt;type=text/plain")

echo "FILE_ID_FULL_JSON IS: $FILE_ID_JSON"

FILE_ID=$(echo $FILE_ID_JSON | jq -r '.id')

echo "FILE_ID: $FILE_ID"

curl -X POST "$BUILDKITE_AGENT_ENDPOINT/ai/anthropic/v1/messages" \
  -H "x-api-key: $BUILDKITE_AGENT_ACCESS_TOKEN" \
  -H "anthropic-version: 2023-06-01" \
  -H "anthropic-beta: files-api-2025-04-14" \
  -H "content-type: application/json" \
  -d @- <<EOF
{
  "model": "claude-sonnet-4-5",
  "max_tokens": 1024,
  "system": "You are an expert software engineer. Analyze build and test failures, identify root causes, and suggest fixes.",
  "messages": [
    {
      "role": "user",
      "content": [
        {
          "type": "text",
          "text": "Analyze the test failures in this log:."
        },
        {
          "type": "document",
          "source": {
            "type": "file",
            "file_id": "$FILE_ID"
          }
        }
      ]
    }
  ]
}
EOF
