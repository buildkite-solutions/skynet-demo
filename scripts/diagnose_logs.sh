#!/bin/bash
set -euo pipefail

buildkite-agent artifact download test-output.log . --step "run-tests"

jq -n \
  --rawfile log_content test-output.log \
  '{
    "model": "claude-sonnet-4-5",
    "max_tokens": 1000,
    "system": "You are an expert software engineer. Analyze build and test failures, identify root causes, and suggest fixes.",
    "messages": [
      {
        "role": "user",
        "content": [
          {"type": "text", "text": "Analyze the test failures in this log:"},
          {"type": "document", "source": {"type": "text", "text": $log_content}}
        ]
      }
    ]
  }' > analysis-request.json

buildkite-agent artifact upload analysis-request.json

curl -X POST "$BUILDKITE_AGENT_ENDPOINT/ai/anthropic/v1/messages" \
  -H "Content-Type: application/json" \
  -H "x-api-key: $BUILDKITE_AGENT_ACCESS_TOKEN" \
  -d @analysis-request.json
