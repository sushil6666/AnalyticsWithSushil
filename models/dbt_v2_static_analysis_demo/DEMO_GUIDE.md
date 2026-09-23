# dbt v2 Stable static analysis presenter guide

## Purpose

Use this guide to present the static analysis demo to someone who is new to dbt.

The demo answers one question:

```text
Can dbt find a SQL mistake before Snowflake runs the bad query?
```

## Beginner terms

1. A seed is a CSV file that dbt loads into the warehouse.
2. A model is a SQL query that creates a table or view.
3. Static analysis means dbt reads and checks SQL before the warehouse runs it.
4. A data type describes a value, such as text, number, or timestamp.
5. A dbt variable changes demo behavior for one command.

## Demo flow

```text
Payment event seed
        |
        v
Typed payment model
        |
        v
Daily payment summary
```

The demo has three modes:

| Mode | SQL behavior | Result |
| --- | --- | --- |
| `safe` | Uses valid SQL | Build succeeds |
| `missing_column` | Uses `payment_amunt` | dbt reports a missing column |
| `type_mismatch` | Runs `SQRT` on a timestamp | dbt reports a wrong data type |

The default mode is `safe`.

## Files to show

```text
models/dbt_v2_static_analysis_demo/
├── dbt_v2_static_analysis_typed_payments.sql
├── dbt_v2_static_analysis_daily_quality.sql
└── schema.yml

seeds/dbt_v2_static_analysis_demo/
├── dbt_v2_static_analysis_payment_events.csv
└── schema.yml
```

The seed and both models use:

```yaml
static_analysis: strict
```

## Step 1. Run the safe build

Run:

```bash
dbt build --select dbt_v2_static_analysis_payment_events+
```

The `+` selects the seed and everything after it.

Expected result:

```text
1 seed loads
2 models build
All attached tests pass
0 failures
```

Expected data:

```text
5 payment events
3 summary dates
489.49 total payment amount
```

Say:

> This is the normal path. The SQL is valid, so dbt builds the complete payment
> flow and runs its tests.

## Step 2. Show the control variable

Open `dbt_v2_static_analysis_typed_payments.sql` and show:

```sql
{% set demo_error = var('dbt_v2_static_analysis_demo_error', 'safe') | lower %}
```

Explain:

1. The default is `safe`.
2. A command can turn on one example error.
3. No file edit is needed during the presentation.
4. The normal command returns the demo to safe mode.

## Step 3. Show a missing column

Run:

```bash
dbt build --select dbt_v2_static_analysis_payment_events+ --vars '{"dbt_v2_static_analysis_demo_error": "missing_column"}'
```

The model asks for:

```sql
payment_amunt as payment_amount
```

The real column is `payment_amount`.

Expected error:

```text
UnresolvedIdentifier (dbt0227)
No column PAYMENT_AMUNT found
```

Say:

> dbt knows the columns available from the seed. It finds the misspelled column
> before Snowflake runs the invalid model.

Point out that the typed model does not run and the daily summary is skipped.

## Step 4. Show a wrong data type

Run:

```bash
dbt build --select dbt_v2_static_analysis_payment_events+ --vars '{"dbt_v2_static_analysis_demo_error": "type_mismatch"}'
```

The model renders:

```sql
sqrt(event_timestamp) as payment_amount
```

`SQRT` needs a number. `event_timestamp` is a timestamp.

Expected error:

```text
FunctionResolutionFailed (dbt0209)
Actual argument: TIMESTAMP_NTZ
Expected argument: FLOAT
```

Say:

> dbt understands the function and the input type. It stops the model before
> Snowflake executes the invalid SQL.

## Step 5. Return to safe mode

Always finish with:

```bash
dbt build --select dbt_v2_static_analysis_payment_events+
```

Say:

> Safe mode is the default, so the development tables are restored without a
> code change.

## Static analysis and data tests

```text
Static analysis checks SQL before execution.
Data tests check data after execution.
Strong dbt projects use both.
```

Static analysis can find missing columns and some wrong function types. Data
tests can find nulls, duplicates, unexpected values, and broken relationships.

Static analysis does not prove that business logic is correct. It also does not
replace unit tests, data tests, code review, or performance testing.

## Why this demo matters

1. Developers receive feedback earlier.
2. Invalid SQL can stop before avoidable warehouse work starts.
3. Downstream models are protected from an invalid upstream schema.
4. Error messages can show the missing column or expected data type.

## Five minute presentation order

1. Define seed, model, and static analysis.
2. Show the three-resource flow.
3. Run the safe build.
4. Show the control variable.
5. Run the missing-column example.
6. Run the wrong-type example.
7. Return to safe mode.
8. Compare static analysis with data tests.

## Troubleshooting

### The safe build fails

1. Confirm you are using dbt v2 Stable.
2. Confirm your dbt session is signed in.
3. Run the command without `--vars`.
4. Confirm the payment seed can be loaded.

### An error example succeeds unexpectedly

1. Use the exact variable value.
2. Confirm the variable name is `dbt_v2_static_analysis_demo_error`.
3. Confirm strict static analysis is enabled.
4. Confirm the demo branches still exist in the typed model.

### The daily summary is skipped

This is expected during an error example because its parent model is invalid.

## Final message

> dbt v2 Stable can check column names and data types before Snowflake executes
> an invalid model. Static analysis gives faster feedback, while data tests check
> the data after successful execution.
