# dbt v2 Stable static analysis presentation guide

## Purpose

Show that dbt v2 Stable can catch column and type errors before Snowflake starts
executing a dependency slice.

## Scenario

A payment feed has a declared schema. A typed model feeds a daily quality
summary. During development, an engineer introduces either a misspelled amount
column or an invalid `SQRT` call on a timestamp.

## Demo flow


### 1. Explain the DAG

```text
dbt_v2_static_analysis_payment_events
                |
                v
dbt_v2_static_analysis_typed_payments
                |
                v
dbt_v2_static_analysis_daily_quality
```

All three resources use `static_analysis: strict`. Strictness cannot increase
downstream, so the seed starts the dependency chain in strict mode.

### 2. Establish the safe baseline

```bash
dbt build --select dbt_v2_static_analysis_payment_events+
```

Expected output:

- Five seed rows
- Two model relations
- Three daily summary rows
- All tests passing
- Total payment amount of 489.49

### 3. Introduce a missing column without editing code

```bash
dbt build --select dbt_v2_static_analysis_payment_events+ --vars '{"dbt_v2_static_analysis_demo_error": "missing_column"}'
```

Talking point: the rendered SQL references `payment_amunt`. The typed upstream
seed proves that column does not exist, so dbt can reject the query before
warehouse execution.

### 4. Introduce a function type mismatch

```bash
dbt build --select dbt_v2_static_analysis_payment_events+ --vars '{"dbt_v2_static_analysis_demo_error": "type_mismatch"}'
```

Talking point: `event_timestamp` is declared as `timestamp_ntz`, while the
supported `SQRT` signature requires `FLOAT`. Static analysis reports
`FunctionResolutionFailed (dbt0209)` before Snowflake executes the model.


### 5. Return to green

```bash
dbt build --select dbt_v2_static_analysis_payment_events+
```

No file edit or cleanup is needed because `safe` is the default mode.

## Key takeaway

Runtime tests validate data after relations exist. Static analysis validates
SQL structure and types before execution. Mature dbt projects benefit from both.

## Troubleshooting

- Confirm the command runs on dbt v2 Stable, not dbt Core.
- Confirm the session is authenticated; strict mode can fall back to baseline
  when authentication is unavailable.
- Keep the seed and models at the same strictness level because downstream
  resources cannot be stricter than their parents.
