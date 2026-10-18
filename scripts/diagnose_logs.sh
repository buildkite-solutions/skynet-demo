#!/bin/bash
set -euo pipefail

buildkite-agent artifact download test-output.log . --step "run-tests"
cp test-output.log test-output.txt

echo 'TEST OUTPUT CONFIRMATION:'
cat test-output.txt

LOG_CONTENT=$(cat test-output.txt)

RESPONSE=$(curl -sS --fail-with-body -X POST "$BUILDKITE_AGENT_ENDPOINT/ai/anthropic/v1/messages" \
  -H "x-api-key: $BUILDKITE_AGENT_ACCESS_TOKEN" \
  -H "anthropic-version: 2023-06-01" \
  -H "anthropic-beta: server-side-fallback-2026-07-01" \
  -H "content-type: application/json" \
  -d "$(jq -n \
    --arg log "$LOG_CONTENT" \
    '{
      model: "claude-opus-5-5",
      max_tokens: 16000,
      output_config: {effort: "medium"},
      fallbacks: "default",
      system: "You are an expert software engineer. Analyze build and test failures, identify root causes, and suggest fixes.",
      messages: [{"role": "user", "content": ("Analyze the test failures in this log:\n\n" + $log)}]
    }')") || {
  echo "ERROR: API request failed:" >&2
  echo "$RESPONSE" >&2
  exit 1
}

STOP_REASON=$(echo "$RESPONSE" | jq -r '.stop_reason // empty')
if [[ "$STOP_REASON" == "refusal" ]]; then
  echo "ERROR: Claude declined to analyze the log (category: $(echo "$RESPONSE" | jq -r '.stop_details.category // "unknown"'))" >&2
  exit 1
fi
if [[ "$STOP_REASON" == "max_tokens" ]]; then
  echo "WARNING: analysis was truncated at max_tokens" >&2
fi

# The response can start with thinking blocks, so collect the text blocks by type.
ANALYSIS=$(echo "$RESPONSE" | jq -r '[.content[]? | select(.type == "text") | .text] | join("")')
if [[ -z "$ANALYSIS" ]]; then
  echo "ERROR: Unexpected API response:" >&2
  echo "$RESPONSE" >&2
  exit 1
fi

echo "$ANALYSIS" | buildkite-agent annotate --style "error" --context "failure-analysis"
