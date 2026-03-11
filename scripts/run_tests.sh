#!/bin/bash
set -euo pipefail

# ---------------------------------------------------------------------------
# Test fixtures – each function prints a realistic mock test-failure log.
# A fixture is chosen at random at runtime so every pipeline run looks fresh.
# ---------------------------------------------------------------------------

fixture_auth_jwt() {
  echo "Running test suite..."
  echo ""
  echo "FAIL: test_jwt_token_expiry (0.18s)"
  echo "  AssertionError: expected token to be valid but received TokenExpiredError"
  echo "  Token issued at: 2026-03-10T22:00:00Z  Expired at: 2026-03-10T23:00:00Z"
  echo "  at validateToken (src/auth/jwt.js:87)"
  echo "  at middleware (src/middleware/auth.js:34)"
  echo ""
  echo "FAIL: test_refresh_token_rotation (0.09s)"
  echo "  AssertionError: refresh token was not invalidated after use"
  echo "  Expected: token in revocation list"
  echo "  Received: token still valid"
  echo "  at rotateRefreshToken (src/auth/jwt.js:142)"
  echo ""
  echo "2 failed, 14 passed"
  exit 1
}

fixture_db_deadlock() {
  echo "Running test suite..."
  echo ""
  echo "FAIL: test_concurrent_order_updates (4.72s)"
  echo "  DatabaseError: Deadlock detected while attempting to acquire lock"
  echo "  Transaction A waiting for row lock held by Transaction B"
  echo "  Transaction B waiting for row lock held by Transaction A"
  echo "  at executeTransaction (src/db/transactions.js:58)"
  echo "  at updateOrder (src/services/orders.js:203)"
  echo ""
  echo "1 failed, 21 passed"
  exit 1
}

fixture_oom() {
  echo "Running test suite..."
  echo ""
  echo "FAIL: test_large_dataset_aggregation (12.34s)"
  echo "  FATAL ERROR: Reached heap limit Allocation failed - JavaScript heap out of memory"
  echo "   1: 0xb7b6c0 node::Abort() [node]"
  echo "   2: 0xa9147e node::FatalError(char const*, char const*) [node]"
  echo "   3: 0xd9323e v8::Utils::ReportOOMFailure(v8::internal::Isolate*, char const*, bool) [node]"
  echo "  heapUsed: 1.87 GB  heapTotal: 1.87 GB  rss: 2.14 GB"
  echo "  at aggregateMetrics (src/analytics/aggregator.js:317)"
  echo ""
  echo "1 failed, 9 passed"
  exit 1
}

fixture_null_pointer() {
  echo "Running test suite..."
  echo ""
  echo "FAIL: test_user_profile_render (0.04s)"
  echo "  TypeError: Cannot read properties of null (reading 'avatarUrl')"
  echo "  at renderAvatar (src/components/UserProfile.jsx:56)"
  echo "  at UserProfile.render (src/components/UserProfile.jsx:112)"
  echo "  at processChild (react-dom/cjs/react-dom.development.js:3990)"
  echo ""
  echo "FAIL: test_dashboard_widgets_load (0.07s)"
  echo "  TypeError: Cannot read properties of undefined (reading 'map')"
  echo "  Expected widgets array to be populated before render"
  echo "  at Dashboard.componentDidMount (src/pages/Dashboard.jsx:78)"
  echo ""
  echo "2 failed, 18 passed"
  exit 1
}

fixture_payment_gateway() {
  echo "Running test suite..."
  echo ""
  echo "FAIL: test_stripe_charge_creates_receipt (2.01s)"
  echo "  HTTPError: 402 Payment Required"
  echo "  {\"error\":{\"code\":\"card_declined\",\"decline_code\":\"insufficient_funds\","
  echo "  \"message\":\"Your card has insufficient funds.\","
  echo "  \"type\":\"card_error\"}}"
  echo "  at chargeCard (src/payments/stripe.js:99)"
  echo "  at processCheckout (src/services/checkout.js:44)"
  echo ""
  echo "FAIL: test_refund_reversal_idempotency (1.55s)"
  echo "  AssertionError: duplicate refund was not rejected"
  echo "  Expected error code: idempotency_key_in_use"
  echo "  Received: charge_already_refunded"
  echo "  at requestRefund (src/payments/stripe.js:178)"
  echo ""
  echo "2 failed, 31 passed"
  exit 1
}

fixture_race_condition() {
  echo "Running test suite..."
  echo ""
  echo "FAIL: test_message_queue_ordering (3.88s)"
  echo "  AssertionError: messages delivered out of order"
  echo "  Expected sequence: [1, 2, 3, 4, 5]"
  echo "  Received sequence: [1, 3, 2, 5, 4]"
  echo "  Possible race condition in consumer worker pool (workers: 4)"
  echo "  at assertOrder (tests/queue/ordering.test.js:67)"
  echo "  at WorkerPool.onMessage (src/queue/worker-pool.js:122)"
  echo ""
  echo "1 failed, 7 passed"
  exit 1
}

fixture_ssl_cert() {
  echo "Running test suite..."
  echo ""
  echo "FAIL: test_tls_mutual_auth (0.31s)"
  echo "  Error: SSL peer certificate or SSH remote key was not OK"
  echo "  SSL certificate problem: certificate has expired"
  echo "  Certificate subject: CN=internal-api.skynet.local"
  echo "  NotAfter: Mar  1 00:00:00 2026 GMT  (expired 10 days ago)"
  echo "  at TLSSocket.<anonymous> (src/clients/internal-api.js:23)"
  echo ""
  echo "FAIL: test_certificate_rotation_health_check (0.11s)"
  echo "  AssertionError: cert rotation job did not renew before expiry window"
  echo "  Expected renewal at: 30 days before expiry"
  echo "  Last renewal: 95 days ago"
  echo "  at checkCertExpiry (src/health/cert-checker.js:48)"
  echo ""
  echo "2 failed, 5 passed"
  exit 1
}

fixture_json_parse() {
  echo "Running test suite..."
  echo ""
  echo "FAIL: test_external_weather_api_response_parsing (0.22s)"
  echo "  SyntaxError: Unexpected token '<' at position 0"
  echo "  Received HTML error page instead of JSON:"
  echo "  <!DOCTYPE html><html><head><title>503 Service Unavailable</title>..."
  echo "  at JSON.parse (<anonymous>)"
  echo "  at parseWeatherData (src/integrations/weather.js:34)"
  echo ""
  echo "1 failed, 12 passed"
  exit 1
}

fixture_stack_overflow() {
  echo "Running test suite..."
  echo ""
  echo "FAIL: test_nested_comment_thread_renderer (0.05s)"
  echo "  RangeError: Maximum call stack size exceeded"
  echo "  Detected cycle or depth > 500 in comment tree"
  echo "  at renderThread (src/components/CommentThread.jsx:29)"
  echo "  at renderThread (src/components/CommentThread.jsx:29)"
  echo "  at renderThread (src/components/CommentThread.jsx:29)"
  echo "  ... (483 more frames)"
  echo ""
  echo "1 failed, 6 passed"
  exit 1
}

fixture_file_not_found() {
  echo "Running test suite..."
  echo ""
  echo "FAIL: test_report_pdf_export (1.04s)"
  echo "  Error: ENOENT: no such file or directory, open '/tmp/reports/monthly-summary.pdf'"
  echo "  errno: -2  code: ENOENT  syscall: open"
  echo "  path: /tmp/reports/monthly-summary.pdf"
  echo "  at exportReport (src/reporting/pdf-exporter.js:88)"
  echo "  at generateMonthlyReport (src/jobs/monthly-report.js:55)"
  echo ""
  echo "FAIL: test_template_missing_fallback (0.06s)"
  echo "  AssertionError: expected fallback template to be served on missing file"
  echo "  Received: unhandled ENOENT propagated to client"
  echo "  at renderTemplate (src/templating/engine.js:114)"
  echo ""
  echo "2 failed, 16 passed"
  exit 1
}

fixture_permission_denied() {
  echo "Running test suite..."
  echo ""
  echo "FAIL: test_audit_log_write (0.08s)"
  echo "  Error: EACCES: permission denied, open '/var/log/skynet/audit.log'"
  echo "  errno: -13  code: EACCES  syscall: open"
  echo "  path: /var/log/skynet/audit.log"
  echo "  Running as: uid=1001 (ci-runner)  Required: uid=0 or gid=adm"
  echo "  at writeAuditEntry (src/audit/logger.js:31)"
  echo ""
  echo "1 failed, 23 passed"
  exit 1
}

fixture_schema_migration() {
  echo "Running test suite..."
  echo ""
  echo "FAIL: test_v3_schema_migration_rollback (8.17s)"
  echo "  MigrationError: rollback of migration 20260308_add_user_preferences failed"
  echo "  Column 'preferences_jsonb' does not exist on table 'users' after rollback"
  echo "  Possibly a missing down-migration step for the jsonb column drop"
  echo "  at rollbackMigration (src/db/migrations/runner.js:204)"
  echo "  at MigrationRunner.down (src/db/migrations/runner.js:88)"
  echo ""
  echo "FAIL: test_foreign_key_constraint_on_soft_delete (0.39s)"
  echo "  QueryError: insert or update on table 'orders' violates foreign key constraint"
  echo "  Key (user_id)=(99999) is not present in table 'users'"
  echo "  Soft-deleted users must remain reachable via FK"
  echo "  at createOrder (src/services/orders.js:78)"
  echo ""
  echo "2 failed, 27 passed"
  exit 1
}

fixture_flaky_e2e() {
  echo "Running test suite..."
  echo ""
  echo "FAIL: test_e2e_checkout_flow (45.00s)"
  echo "  TimeoutError: Waiting for selector '.order-confirmation' timed out after 45000ms"
  echo "  Last screenshot saved to: /tmp/screenshots/checkout-timeout-20260311.png"
  echo "  Page URL at timeout: https://staging.skynet.internal/checkout/payment"
  echo "  Console errors captured:"
  echo "    [error] Failed to load resource: net::ERR_CONNECTION_RESET (payments-api:443)"
  echo "  at waitForSelector (playwright/lib/page.js:512)"
  echo "  at runCheckoutFlow (tests/e2e/checkout.spec.js:93)"
  echo ""
  echo "1 failed, 44 passed"
  exit 1
}

fixture_data_validation() {
  echo "Running test suite..."
  echo ""
  echo "FAIL: test_email_format_validation (0.03s)"
  echo "  AssertionError: invalid email 'user@@domain..com' was accepted"
  echo "  Expected: ValidationError thrown"
  echo "  Received: user object created with id 4821"
  echo "  at validateEmail (src/validators/user.js:19)"
  echo ""
  echo "FAIL: test_phone_number_e164_normalization (0.04s)"
  echo "  AssertionError: +1 (800) SKYNET-1 was not normalized to E.164 format"
  echo "  Expected: '+18007595381'"
  echo "  Received: '+1 (800) SKYNET-1'"
  echo "  at normalizePhone (src/validators/user.js:47)"
  echo ""
  echo "FAIL: test_age_range_boundary (0.02s)"
  echo "  AssertionError: age value 0 passed validation"
  echo "  Expected: minimum age of 13 to be enforced"
  echo "  Received: user created with age=0"
  echo "  at validateAge (src/validators/user.js:63)"
  echo ""
  echo "3 failed, 29 passed"
  exit 1
}

# ---------------------------------------------------------------------------
# Main: if a failure log was supplied (via $1 or Buildkite metadata), use it
# directly for diagnosis; otherwise pick a fixture at random.
# ---------------------------------------------------------------------------

FAILURE_INPUT="${1:-}"

if [[ -z "$FAILURE_INPUT" ]] && command -v buildkite-agent &>/dev/null; then
  FAILURE_INPUT=$(buildkite-agent meta-data get failure-log --default "" 2>/dev/null || true)
fi

if [[ -n "$FAILURE_INPUT" ]]; then
  echo "--- Using provided failure log for diagnosis"
  echo "$FAILURE_INPUT" | tee test-output.log
  exit 1
fi

FIXTURES=(
  fixture_auth_jwt
  fixture_db_deadlock
  fixture_oom
  fixture_null_pointer
  fixture_payment_gateway
  fixture_race_condition
  fixture_ssl_cert
  fixture_json_parse
  fixture_stack_overflow
  fixture_file_not_found
  fixture_permission_denied
  fixture_schema_migration
  fixture_flaky_e2e
  fixture_data_validation
)

SELECTED="${FIXTURES[RANDOM % ${#FIXTURES[@]}]}"
echo "--- Selected test fixture: $SELECTED"

"$SELECTED" 2>&1 | tee test-output.log
