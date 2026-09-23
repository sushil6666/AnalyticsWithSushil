# dbt v2 Stable static analysis presenter guide

## Purpose

This guide helps you present the dbt v2 Stable static analysis demo to someone
who is new to dbt.

The demo answers one main question:

```text
Can dbt find a SQL mistake before Snowflake runs the bad query?
```

The answer is yes when dbt v2 Stable can understand the SQL with strict static
analysis.

## The demo story

The demo uses a small payment pipeline:

```text
Payment event CSV file
          |
          v
Typed payment model
          |
          v
Daily payment summary
```

The CSV file contains five payment events. The first model selects and checks the
payment columns. The final model creates one summary row for each payment date.

The demo can switch between three modes:

| Mode | What it does | Expected result |
| --- | --- | --- |
| `safe` | Uses valid SQL | Build succeeds |
| `missing_column` | Uses a misspelled column name | dbt stops before model execution |
| `type_mismatch` | Sends a timestamp to a numeric function | dbt stops before model execution |

The committed project uses `safe` by default.

## Beginner terms

Explain these words before starting the demo.

### Seed

A seed is a CSV file that dbt loads into the warehouse as a table.

This demo uses:

```text
dbt_v2_static_analysis_payment_events.csv
```

### Model

A model is a SQL query that creates a table or view.

This demo has two models:

```text
dbt_v2_static_analysis_typed_payments
dbt_v2_static_analysis_daily_quality
```

### Static analysis

Static analysis means dbt reads and understands the SQL before the warehouse
runs it.

It can check things such as:

1. Whether a selected column exists
2. Whether a function receives the correct data type
3. Whether downstream SQL matches the available upstream columns

### Data type

A data type describes the kind of value stored in a column.

Examples include:

```text
VARCHAR for text
NUMBER for numeric values
TIMESTAMP_NTZ for timestamps
```

### Project variable

A project variable is a value passed to dbt when a command runs.

This demo uses a variable to turn each example error on or off without editing
the SQL file.

## Demo resources

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

Strict mode tells dbt to report a problem when it cannot prove that the SQL is
valid.

## What each resource does

### Payment event seed

The seed contains five payment events with these important columns:

```text
event_id
customer_id
payment_amount
payment_status
event_timestamp
```

The seed YAML declares the Snowflake data type for each column. This gives dbt a
clear schema to check before the models run.

### Typed payment model

The typed payment model selects the payment columns.

In safe mode it uses:

```sql
payment_amount
```

The model can intentionally change that expression for the two error examples.

### Daily payment summary

The final model groups payment events by date. It counts payment statuses and
adds the payment amounts.

This model proves that downstream resources are not executed when an upstream
query is invalid.

## Step 1. Show the safe build

Run:

```bash
dbt build --select dbt_v2_static_analysis_payment_events+
```

The `+` selects the seed and everything after it in the dbt graph.

Expected result:

```text
1 seed loads
2 models build
All attached data tests pass
0 failures
```

Expected data:

```text
5 payment events
3 summary dates
489.49 total payment amount
```

Say:

> This is the normal path. dbt loads five payment events, builds two models, and
> runs the attached tests. The SQL is valid, so Snowflake executes the models.

## Step 2. Show how the variable controls the demo

Open:

```text
dbt_v2_static_analysis_typed_payments.sql
```

Show the variable:

```sql
{% set demo_error = var('dbt_v2_static_analysis_demo_error', 'safe') | lower %}
```

Explain:

1. The default value is `safe`
2. A command can change the value temporarily
3. The committed SQL does not need to be edited
4. Running the normal command returns the demo to safe mode

## Step 3. Show a misspelled column

Run:

```bash
dbt build --select dbt_v2_static_analysis_payment_events+ --vars '{"dbt_v2_static_analysis_demo_error": "missing_column"}'
```

This mode changes the valid expression:

```sql
payment_amount
```

To the invalid expression:

```sql
payment_amunt as payment_amount
```

The word `amount` is intentionally misspelled.

Expected error:

```text
UnresolvedIdentifier (dbt0227)
No column PAYMENT_AMUNT found
```

Say:

> The model asks for payment_amunt, but that column does not exist. dbt knows the
> columns available from the seed, so it reports the mistake before Snowflake
> runs the invalid model.

Point out:

1. dbt shows the missing column name
2. dbt can list valid available columns
3. The typed payment model does not run
4. The downstream daily summary is skipped
5. Tests that depend on those models do not run

## Step 4. Show a wrong data type

Run:

```bash
dbt build --select dbt_v2_static_analysis_payment_events+ --vars '{"dbt_v2_static_analysis_demo_error": "type_mismatch"}'
```

This mode renders:

```sql
sqrt(event_timestamp) as payment_amount
```

`SQRT` is a numeric function. It expects a number.

`event_timestamp` has the type `TIMESTAMP_NTZ`. It is not a number.

Expected error:

```text
FunctionResolutionFailed (dbt0209)
Actual argument: TIMESTAMP_NTZ
Expected argument: FLOAT
```

Say:

> The SQL sends a timestamp to SQRT. SQRT needs a number. dbt understands both
> types and stops the model before Snowflake executes it.

Point out:

1. dbt identifies the function that failed
2. dbt shows the actual argument type
3. dbt shows the expected argument type
4. The invalid model is not executed
5. The downstream model is skipped

## Step 5. Compare the two errors

| Example | What is wrong | What dbt checks |
| --- | --- | --- |
| Missing column | `payment_amunt` does not exist | Available column names |
| Wrong type | `SQRT` receives a timestamp | Function argument types |

Use this simple explanation:

> The first error is about a name. The second error is about a type. dbt v2
> Stable can understand both before the warehouse runs the model.

## Step 6. Return the demo to safe mode

Run:

```bash
dbt build --select dbt_v2_static_analysis_payment_events+
```

No variable is passed, so the demo returns to `safe` mode.

Say:

> Safe mode is the default. We do not need to edit or restore a project file.

Always finish a live demo with this command. It restores the development tables
to the expected successful state.

## Static analysis and data tests

Static analysis and data tests solve different problems.

### Static analysis

Static analysis checks the SQL before the model runs.

It can find:

1. Missing columns
2. Invalid function arguments
3. Some incompatible data types
4. Some invalid downstream references

### Data tests

Data tests check the data after a model or seed exists.

They can find:

1. Null values
2. Duplicate keys
3. Unexpected values
4. Broken relationships

The simple comparison is:

```text
Static analysis checks the SQL before execution.
Data tests check the data after execution.
Strong dbt projects use both.
```

## Why this demo is useful

### Faster feedback

A developer can learn about some SQL mistakes before waiting for Snowflake to
execute the query.

### Lower warehouse waste

An invalid model can be stopped before it sends avoidable work to the warehouse.

### Safer downstream models

When an upstream column is missing or has the wrong type, dbt can stop dependent
models from running with an invalid schema.

### Easier code review

Static analysis gives reviewers more confidence that column names and function
arguments are valid.

### Better development experience

Errors can include the missing column, valid alternatives, and the expected data
type.

## What static analysis does not replace

Static analysis does not replace:

1. Data tests
2. Unit tests
3. Business logic review
4. Warehouse permissions
5. Runtime performance testing
6. Source freshness checks

A SQL query can be valid but still calculate the wrong business result. Static
analysis checks whether dbt can understand the SQL. It does not prove that every
business rule is correct.

## One minute presentation

> This demo uses five payment events, one typed model, and one daily summary.
> The normal build succeeds. We then turn on two controlled mistakes with a dbt
> variable. The first mistake uses a column that does not exist. The second sends
> a timestamp to a numeric function. dbt v2 Stable catches both during strict
> static analysis before Snowflake runs the invalid model. We finish by running
> safe mode again. The key message is that static analysis checks SQL before
> execution, while data tests check data after execution.

## Suggested presentation order

1. Explain the seed, models, and static analysis
2. Show the three-resource data flow
3. Run the safe build
4. Open the variable-controlled SQL
5. Run the missing-column example
6. Explain the error message
7. Run the type-mismatch example
8. Explain the expected and actual types
9. Return to safe mode
10. Close with the difference between static analysis and data tests

## Troubleshooting

### The normal build fails

1. Confirm the command is running on dbt v2 Stable
2. Confirm the dbt session is signed in
3. Confirm Snowflake credentials are valid
4. Confirm the payment seed can be created
5. Run the safe command without `--vars`

### The missing-column example succeeds unexpectedly

1. Use the exact value `missing_column`
2. Confirm the variable name is `dbt_v2_static_analysis_demo_error`
3. Confirm the typed payment model still contains the demo branch
4. Confirm strict static analysis is enabled

### The type example succeeds unexpectedly

1. Use the exact value `type_mismatch`
2. Confirm `event_timestamp` is declared as `timestamp_ntz`
3. Confirm the expression still uses `sqrt(event_timestamp)`
4. Confirm strict static analysis is enabled

### The downstream summary is skipped

This is expected when the typed payment model is invalid. A downstream model
cannot run when its required parent model does not have valid SQL.

### The development tables are left in an unexpected state

Run the safe build again:

```bash
dbt build --select dbt_v2_static_analysis_payment_events+
```

## Final message

Use this closing statement:

> dbt v2 Stable can understand more than Jinja rendering. With strict static
> analysis, it can check column names and data types before Snowflake executes
> an invalid model. This gives developers faster feedback and protects the rest
> of the dbt graph from avoidable SQL errors.
