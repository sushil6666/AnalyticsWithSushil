# dbt v2 Stable static analysis presentation guide

## What you are showing

This demo proves that dbt can catch a bad column name or an invalid data type
before Snowflake executes the model.

The audience only needs to remember this flow:

```text
Payment seed
    |
    v
Typed payment model
    |
    v
Daily payment summary
```

## Step 1. Show the safe build

Run:

```bash
dbt build --select dbt_v2_static_analysis_payment_events+
```

Say:

> This is the normal path. dbt loads five payment events, builds two models,
> and runs the attached tests. All 26 results succeed.

Expected values:

- Five payment events
- Three summary dates
- Total payment amount of 489.49

## Step 2. Show a misspelled column

Run:

```bash
dbt build --select dbt_v2_static_analysis_payment_events+ --vars '{"dbt_v2_static_analysis_demo_error": "missing_column"}'
```

Say:

> The model now asks for `payment_amunt`, but the real column is
> `payment_amount`. dbt understands the upstream seed schema and stops the
> mistake before the invalid model runs.

Expected error:

```text
UnresolvedIdentifier (dbt0227)
No column PAYMENT_AMUNT found
```

Point out that dbt also lists the valid available columns. The downstream daily
summary is skipped because its parent model is invalid.

## Step 3. Show a wrong data type

Run:

```bash
dbt build --select dbt_v2_static_analysis_payment_events+ --vars '{"dbt_v2_static_analysis_demo_error": "type_mismatch"}'
```

Say:

> The model now passes `event_timestamp` to `SQRT`. A timestamp is not a number,
> so dbt rejects the function call before Snowflake executes the model.

Expected error:

```text
FunctionResolutionFailed (dbt0209)
Actual argument: TIMESTAMP_NTZ
Expected argument: FLOAT
```

## Step 4. Return to green

Run:

```bash
dbt build --select dbt_v2_static_analysis_payment_events+
```

Say:

> Safe mode is the default. We do not need to edit or restore any project file.

## Final takeaway

```text
Data tests check the data after a model is built.
Static analysis checks the SQL before the model runs.
Strong dbt projects use both.
```

## Troubleshooting

- Confirm the command runs on dbt v2 Stable
- Confirm the dbt session is authenticated
- Use the exact variable values `safe`, `missing_column`, or `type_mismatch`
- Run the safe command at the end so the development relations are restored
