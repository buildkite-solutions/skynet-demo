#!/bin/bash
set -euo pipefail

buildkite-agent artifact download test-output.log . --step "run-tests"

FILE_ID=$(curl -s -X POST "$BUILDKITE_AGENT_ENDPOINT/ai/anthropic/v1/files" \
  -H "x-api-key: $BUILDKITE_AGENT_ACCESS_TOKEN" \
  -H "anthropic-beta: files-api-2025-04-14" \
  -F "file=@test-output.log;type=text/plain" \
  | jq -r '.id')

curl -X POST "$BUILDKITE_AGENT_ENDPOINT/ai/anthropic/v1/messages" \
  -H "Content-Type: application/json" \
  -H "x-api-key: $BUILDKITE_AGENT_ACCESS_TOKEN" \
  -H "anthropic-beta: files-api-2025-04-14" \
  -d "$(jq -n \
    --arg file_id "$FILE_ID" \
    '{
      "model": "claude-sonnet-4-5",
      "max_tokens": 1000,
      "system": "You are an expert software engineer. Analyze build and test failures, identify root causes, and suggest fixes.",
      "messages": [
        {
          "role": "user",
          "content": [
            {"type": "text", "text": "Analyze the test failures in this log:"},
            {"type": "document", "source": {"type": "file", "file_id": $file_id}}
          ]
        }
      ]
    }')"
