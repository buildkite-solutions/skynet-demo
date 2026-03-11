#!/bin/bash
set -euo pipefail

buildkite-agent artifact download test-output.log . --step "run-tests"
cp test-output.log test-output.txt

echo 'TEST OUTPUT CONFIRMATION:'
cat test-output.txt

LOG_CONTENT=$(cat test-output.txt)

RESPONSE=$(curl -s -f -X POST "$BUILDKITE_AGENT_ENDPOINT/ai/anthropic/v1/messages" \
  -H "x-api-key: $BUILDKITE_AGENT_ACCESS_TOKEN" \
  -H "anthropic-version: 2023-06-01" \
  -H "content-type: application/json" \
  -d "$(jq -n \
    --arg log "$LOG_CONTENT" \
    '{
      model: "claude-sonnet-4-5",
      max_tokens: 1024,
      system: "You are an expert software engineer. Analyze build and test failures, identify root causes, and suggest fixes.",
      messages: [{"role": "user", "content": ("Analyze the test failures in this log:\n\n" + $log)}]
    }')")

ANALYSIS=$(echo "$RESPONSE" | jq -r '.content[0].text // empty')
if [[ -z "$ANALYSIS" ]]; then
  echo "ERROR: Unexpected API response:" >&2
  echo "$RESPONSE" >&2
  exit 1
fi

echo "$ANALYSIS" | buildkite-agent annotate --style "error" --context "failure-analysis"
