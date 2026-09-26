# On error continue presenter guide

## Purpose

Use this guide to show how dbt can keep useful monitoring work running when a
model fails.

The demo answers four questions:

1. Can safe parsing preserve bad payment data for review?
2. Can an incident audit run after strict validation fails?
3. Can dbt record a warning without blocking normal delivery?
4. Can a separate monitoring job turn that warning into an alert?

## Beginner terms

1. A seed is a CSV file that dbt loads into the warehouse.
2. A model is a SQL query that creates a table or view.
3. A data test checks whether the data follows a rule.
4. `on_error: continue` allows eligible downstream work to run after a failure.
5. A warning records a problem without failing the normal delivery command.
6. A group identifies the team that owns a dbt resource.

## Demo story

The seed contains five payment events. One amount is malformed and one is
negative.

```text
Payment event seed
      |
      +-> Payment validation
      |
      +-> Incident audit
      |
      +-> Review queue -> Warning test -> Alert
```

The validation model tries to create trusted payment data. The audit and review
queue read the original seed, so they can preserve evidence even when strict
validation fails.

## Main resources

| Resource | Purpose |
| --- | --- |
| `on_error_continue_payment_events` | Stores the sample payment feed |
| `on_error_continue_payment_validation` | Converts raw amounts into numbers |
| `on_error_continue_incident_audit` | Counts malformed, negative, and declined events |
| `on_error_continue_payment_review_queue` | Stores events that need review |
| `on_error_continue_feed_quality` | Demonstrates safe, warning, and error policies |
| `payment_events_requiring_review` | Warning test used for monitoring |

## Important behavior

`on_error: continue` does not hide a failure.

```text
Validation fails
      |
      +-> Command still reports the failure
      |
      +-> Eligible independent work can continue
```

A model that needs the failed relation cannot use unavailable output. The audit
works because it reads the original seed directly.

## Step 1. Run the normal delivery flow

Run:

```bash
dbt build --select on_error_continue_payment_events+
```

Expected result:

```text
5 payment events loaded
Models and tests complete
1 intentional warning
0 failures
```

The review queue should contain:

```text
EVT-1003
EVT-1004
```

Say:

> Normal delivery keeps useful data available and records the known quality
> problem as a warning.

## Step 2. Show strict validation failure

Run:

```bash
dbt build --select on_error_continue_payment_validation+ --vars '{"on_error_continue_demo_strict_validation": true}'
```

Expected behavior:

1. Payment validation fails on the malformed amount.
2. The command reports the failure.
3. The incident audit still runs.
4. The audit reads the seed instead of the failed validation table.

Say:

> Continue does not mean ignore the error. The failure stays visible, but the
> independent incident audit can still collect useful evidence.

## Step 3. Show a Jinja warning

Run:

```bash
dbt build --select on_error_continue_feed_quality --vars '{"on_error_continue_demo_exception_mode": "warn"}'
```

Expected behavior:

1. dbt writes a warning to the logs.
2. The model still builds.
3. Its tests still run.

Say:

> A warning tells the team about a problem without stopping this model.

## Step 4. Show a blocking Jinja error

Run:

```bash
dbt build --select on_error_continue_feed_quality --vars '{"on_error_continue_demo_exception_mode": "error"}'
```

Expected behavior:

1. dbt raises a compiler error.
2. The model does not run.
3. Tests that require the model are skipped.

Say:

> Error mode is for a condition that must stop execution.

## Step 5. Return to safe mode

Run:

```bash
dbt build --select on_error_continue_payment_events+
```

The project variables default to safe values, so no code edit is required.

## Step 6. Show the warning evidence

The warning test is attached to the review queue. It warns when one or more rows
need attention and stores those rows for investigation.

Run:

```bash
dbt test --select tag:on_error_continue_alert
```

The normal test command returns a warning. It does not fail delivery.

This gives the team:

1. A warning result in dbt.
2. A count of affected rows.
3. Stored evidence with event IDs.
4. A tag for selecting the alert test.
5. A resource owner through the dbt group.

## Step 7. Explain delivery and monitoring jobs

Use separate jobs so delivery and alerting have different responsibilities.

### Delivery job

```bash
dbt build --select on_error_continue_payment_events+
```

Purpose:

1. Load and transform the feed.
2. Preserve bad rows for review.
3. Record warning-level quality issues.
4. Keep delivery successful for this warning threshold.

### Monitoring job

```bash
dbt test --select tag:on_error_continue_alert --warn-error-options '{"error":["RunResultWarningMessage"]}'
```

Purpose:

1. Run only the alert-tagged test.
2. Convert its warning into a failed monitoring job.
3. Trigger the job error notification configured in dbt Platform.

Say:

> Delivery records the warning. Monitoring promotes only the selected warning so
> the alert channel receives a clear signal.

## Step 8. Explain ownership and notifications

The review queue belongs to the `payment_operations_demo` group. The group owner
identifies the team responsible for the issue.

For email model notifications:

1. Run the command in a dbt Platform deployment environment.
2. Confirm the deployed branch contains the demo.
3. Enable group and owner model notifications.
4. Enable test warning and failure statuses as needed.
5. Use a team-owned email address in `groups.yml`.

For Slack job notifications:

1. Create the monitoring job.
2. Connect the required Slack channel in dbt Platform.
3. Select the deployment environment and monitoring job.
4. Enable job error notifications.

Interactive Studio commands do not send deployment model-owner notifications.

## Three separate decisions

The demo separates three questions:

| Question | Demo feature |
| --- | --- |
| Can eligible work continue? | `on_error: continue` |
| Should the issue be recorded? | Warning test and stored evidence |
| Should someone be notified? | Email or Slack configuration |

This separation keeps the failure visible while preserving useful evidence.

## Why this demo matters

1. Incident evidence can survive a transformation failure.
2. Delivery warnings do not need to become delivery failures.
3. Selected warnings can still create alerts through a monitoring job.
4. Resource ownership gives each alert a responsible team.
5. Safe parsing and strict validation can support different operational needs.

## Important limits

1. `on_error: continue` does not change a failed model into a success.
2. It does not make the failed relation available.
3. A child that queries unavailable output may still fail.
4. A Jinja warning is only a log message unless a test or job records status.
5. Notifications require the correct deployment environment and account setup.

## Ten minute presentation order

1. Define seed, model, test, warning, and `on_error: continue`.
2. Show the payment resource flow.
3. Run the normal delivery command.
4. Show the review queue and intentional warning.
5. Run the strict validation example.
6. Point out that the audit still runs.
7. Show Jinja warning and error modes.
8. Explain the delivery and monitoring jobs.
9. Explain ownership and notifications.
10. Return to safe mode.

## Troubleshooting

### Nothing is selected

Run:

```bash
dbt ls --select on_error_continue_payment_events+
dbt ls --select tag:on_error_continue_alert
```

### The seed is missing

Run:

```bash
dbt seed --select on_error_continue_payment_events --full-refresh
```

### The warning evidence is missing

Run:

```bash
dbt build --select +on_error_continue_payment_review_queue
```

Confirm the review queue contains `EVT-1003` and `EVT-1004`.

### Strict mode still returns a failed command

This is expected. `on_error: continue` allows eligible work to continue but does
not suppress the validation failure.

### Slack does not receive an alert

1. Confirm the monitoring job uses the documented command.
2. Confirm the job returns a failed status.
3. Confirm Slack is connected to dbt Platform.
4. Confirm job error notifications are enabled.

### Email does not arrive

1. Confirm model notifications are enabled for the account.
2. Confirm test warning notifications are selected.
3. Confirm the job runs in a deployment environment.
4. Confirm the review queue belongs to `payment_operations_demo`.
5. Confirm the owner email in `groups.yml` is valid.

## Final message

> A failure should remain visible, but it should not block independent monitoring
> from collecting evidence. This demo separates processing, evidence, and
> notification so each part has one clear responsibility.
