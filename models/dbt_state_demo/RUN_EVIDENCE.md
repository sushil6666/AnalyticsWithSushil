# dbt State run evidence

## Scope

This file records the two consecutive managed builds used to validate the demo.
The same command and project files were used for both runs.

```bash
dbt build --select dbt_state_order_events+ --manage-state
```

Validation environment:

```text
dbt v2.0.6
Snowflake development target
dbt State enabled
deferred target reported as prod
```

Private relation names and account details are intentionally excluded.

## First run

Observed summary:

```text
Status: success
Elapsed time: 38.06 seconds
Selected resources: 29
Passed: 29
Reused: 0
Models: 3
Seeds: 1
Data tests: 25
Warnings: 0
Failures: 0
```

Interpretation:

The demo resources were new. dbt executed the seed, models, and tests, then
recorded State metadata for later comparisons.

## Second run

Observed summary:

```text
Status: success
Elapsed time: 16.07 seconds
Selected resources: 29
Passed through execution: 0
Reused: 29
Models represented: 3
Seeds represented: 1
Data tests represented: 25
Warnings: 0
Failures: 0
Run hooks executed: 2
```

The tool's node summary represented the reused resources as skipped execution:

```text
passed=0
skipped=29
```

The final execution summary represented the same resources as reused:

```text
29 reused
```

## Difference

```text
Elapsed reduction: 38.06s - 16.07s = 21.99s
Elapsed reduction percent: 21.99 / 38.06 = 57.8%
```

Avoided selected executions:

```text
1 seed load
3 model builds
25 data tests
29 selected executions total
```

The second run still performed State metadata work and two run hooks. This is
evidence of avoided resource execution, not proof that all warehouse activity or
billing was eliminated.

## State explain

Validated command:

```bash
dbt state explain --verbose --select tag:dbt_state_demo
```

Observed result:

```text
No log files found.
```

The Studio command environment did not persist a `logs/state/` response file for
the latest build. The managed build summary remains the evidence for the reused
count. In an environment that persists response logs, `dbt state explain` can
show the full reason for each `SKIP_EXECUTION` decision.

## Data validation

The final KPI model returned:

```text
total_reporting_days: 2
total_orders: 6
completed_orders: 3
gross_order_amount: 605.50
completion_rate: 0.500000
```

## Reproduction notes

Results can differ when:

1. The relations already exist from an earlier run.
2. Source or seed data changed.
3. SQL or configuration changed.
4. A model's lag tolerance expired after an upstream data change.
5. Warehouse size, concurrency, cache, or network conditions differ.
6. Hooks or metadata checks have different costs.
