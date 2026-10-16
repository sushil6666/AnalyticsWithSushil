# dbt Compare run evidence

## Scope

This file records the controlled development build and comparison against the
deployed staging baseline.

Private schemas, environment IDs, run IDs, and account details are intentionally
excluded.

## Controlled mode

```text
dbt_compare_demo_mode: ten_percent_uplift
```

The mode changes only:

```sql
sum(payment_amount)
```

to:

```sql
sum(payment_amount) * 1.10
```

## Development build

Validated command:

```bash
dbt build --select +dbt_v2_static_analysis_daily_quality+ --defer --vars '{"dbt_compare_demo_mode":"ten_percent_uplift"}'
```

Observed Studio summary:

```text
Status: success
Resources represented: 24
Models represented: 2
Seed represented: 1
Data tests represented: 21
Successful executions: 10
Reused resources: 16
Warnings: 0
Failures: 0
Elapsed time: 24.51 seconds
```

A dbt Cloud CI build also completed successfully in an isolated comparison
schema before the compare step.

## Compare command

Validated CI command:

```bash
dbt compare --select dbt_v2_static_analysis_daily_quality+ --defer --vars '{"dbt_compare_demo_mode":"ten_percent_uplift"}'
```

Observed CI result:

```text
Status: success
Compare duration: 8 seconds
Baseline: configured deployed staging environment
```

The CI environment supplied the staging state manifest automatically.

## Local Studio limitation

The same local compare command returned:

```text
Compare command requires a state manifest
```

The workspace had access to relations through deferral but did not contain a
saved staging `manifest.json`. The failure occurred before data comparison. It
was not caused by a missing staging relation.

## Value evidence

| Event date | Staging amount | Development amount | Difference | Change rate |
| --- | ---: | ---: | ---: | ---: |
| 2026-09-15 | 173.750 | 191.125 | 17.375 | 10% |
| 2026-09-16 | 225.750 | 248.325 | 22.575 | 10% |
| 2026-09-17 | 89.990 | 98.989 | 8.999 | 10% |

Verified unchanged values:

```text
Staging rows: 3
Development rows: 3
Rows added: 0
Rows removed: 0
Staging key changes: 0
Event count changes: 0
Schema changes: 0
```

Verified changed values:

```text
Modified rows: 3
Modified value column: total_payment_amount
Change rate per row: 10 percent
```

## Interpretation

All tests passed because the change preserved the expected schema, grain, and
not-null behavior.

Compare still found a meaningful business-value change. This is the exact gap
the demo is designed to show.

## Safe-default reset

Validated command:

```bash
dbt build --select +dbt_v2_static_analysis_daily_quality+ --defer
```

Observed result:

```text
Status: success
Warnings: 0
Failures: 0
Elapsed time: 24.98 seconds
```

The development relation returned to the committed safe calculation.

## Environment wording

This account uses development and staging. The evidence compares development
with deployed staging. References to a separate production environment are not
part of this demo.
