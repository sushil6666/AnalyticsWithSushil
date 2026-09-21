# dbt v2 Stable static analysis demo

## The simple idea

This demo shows how dbt v2 Stable can catch SQL mistakes before Snowflake runs
the query.

We demonstrate two common mistakes:

1. A misspelled column: `payment_amunt` instead of `payment_amount`
2. A wrong data type: passing a timestamp to the numeric `SQRT` function

The mistakes are controlled by a project variable. The default mode is safe, so
a normal project build stays green.

## What was added

```text
Payment seed
    |
    v
Typed payment model
    |
    v
Daily payment summary
```

The demo files are:

```text
models/dbt_v2_static_analysis_demo/
├── dbt_v2_static_analysis_typed_payments.sql
├── dbt_v2_static_analysis_daily_quality.sql
├── schema.yml
├── README.md
└── DEMO_GUIDE.md

seeds/dbt_v2_static_analysis_demo/
├── dbt_v2_static_analysis_payment_events.csv
└── schema.yml
```

The seed and both models use:

```yaml
static_analysis: strict
```

## 1. Run the normal build

```bash
dbt build --select dbt_v2_static_analysis_payment_events+
```

Expected result:

- One seed loads with five payment events
- Two models build
- Twenty-one data tests run
- Twenty-six total results succeed
- The daily summary contains three dates
- The total payment amount is 489.49

## 2. Test a misspelled column

```bash
dbt build --select dbt_v2_static_analysis_payment_events+ --vars '{"dbt_v2_static_analysis_demo_error": "missing_column"}'
```

This mode changes the rendered SQL from:

```sql
payment_amount
```

to the invalid column:

```sql
payment_amunt
```

dbt stops the model with:

```text
UnresolvedIdentifier (dbt0227)
No column PAYMENT_AMUNT found
```

It also lists the valid columns available from the payment seed. The downstream
summary and its tests do not run.

## 3. Test a wrong function type

```bash
dbt build --select dbt_v2_static_analysis_payment_events+ --vars '{"dbt_v2_static_analysis_demo_error": "type_mismatch"}'
```

This mode renders:

```sql
sqrt(event_timestamp)
```

`event_timestamp` is a timestamp, while `SQRT` requires a number. dbt stops the
model with:

```text
FunctionResolutionFailed (dbt0209)
Actual argument: TIMESTAMP_NTZ
Expected argument: FLOAT
```

Snowflake does not execute the invalid model.

## 4. Return to the safe mode

Run the normal command again:

```bash
dbt build --select dbt_v2_static_analysis_payment_events+
```

The variable defaults to `safe`, so no code edit or cleanup is needed.

## Why this matters

Data tests validate data after a model exists. Static analysis checks SQL before
the model runs. Using both catches more problems and prevents avoidable warehouse
failures.

## Requirements

- Run the demo on dbt v2 Stable, not dbt Core
- Use an authenticated dbt session for strict analysis
- Keep upstream and downstream resources compatible with strict analysis
