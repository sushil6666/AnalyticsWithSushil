# dbt v2 Stable static analysis demo

This demo shows how dbt v2 Stable can prove Snowflake SQL invalid before a
model starts running. It uses a fully typed payment seed, a strict typed-events
model, and a downstream daily summary.

## What this demonstrates

- `static_analysis: strict` on a seed and its downstream models
- Column resolution against an upstream dbt resource
- Snowflake function argument type checking
- A safe default that builds and tests normally
- Intentional error modes activated only through a project variable
- Prevention of partial execution across the selected dependency slice

## 1. Run the safe build

```bash
dbt build --select dbt_v2_static_analysis_payment_events+
```

Expected result: the seed loads, both models build, and all attached data tests
pass. The daily summary returns three dates and a total amount of 489.49.

## 2. Demonstrate missing-column detection

```bash
dbt build --select dbt_v2_static_analysis_payment_events+ --vars '{"dbt_v2_static_analysis_demo_error": "missing_column"}'
```

The typed-events model renders `payment_amunt`, which does not exist in the
seed schema. Strict static analysis should reject the query before Snowflake
executes the selected models.

## 3. Demonstrate function type checking

```bash
dbt build --select dbt_v2_static_analysis_payment_events+ --vars '{"dbt_v2_static_analysis_demo_error": "type_mismatch"}'
```

The typed-events model passes the `timestamp_ntz` column `event_timestamp` to
`SQRT`, whose supported signature requires a floating-point argument. Strict
static analysis reports `FunctionResolutionFailed (dbt0209)` before Snowflake
executes the selected models.

## 4. Restore the safe state


```bash
dbt build --select dbt_v2_static_analysis_payment_events+
```

The variable defaults to `safe`, so no cleanup or source edit is required.

## Notes

Strict mode requires an authenticated dbt v2 Stable session. If authentication
is unavailable, dbt can fall back to baseline analysis. The demo keeps all
intentional failures behind a variable so normal project builds remain green.
