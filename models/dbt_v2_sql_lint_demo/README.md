# dbt v2 Stable SQL lint demo

## What this demo teaches

This demo shows how `dbt lint` checks SQL style and dbt coding conventions
before code is merged.

The committed model passes lint. During the demo, you introduce one safe style
violation, ask dbt to report it, and use `--fix` to restore the clean file.

## Beginner terms

### SQL linting

SQL linting checks source code against agreed rules. It can find inconsistent
capitalization, layout problems, ambiguous references, and unsafe patterns.

### Lint rule

A lint rule is one coding standard. Each rule has a code, such as `CP01` or
`DBT01`.

### Auto-fix

An auto-fix changes source code when dbt can make the correction safely. Some
rules require a person to decide how the SQL should change.

## Linting is not the same as static analysis

| Check | Main question |
| --- | --- |
| SQL linting | Does the source follow our coding conventions? |
| Static analysis | Are columns, types, and SQL expressions valid? |
| `dbt build` | Does the code run and do its tests pass? |

A model can build successfully and still fail lint because style and correctness
are different concerns.

## Demo flow

```text
dbt_v2_lint_order_events
          |
          v
dbt_v2_lint_orders
```

The seed contains four orders. The model adds `order_date` and an
`is_completed` flag.

## Files

```text
.sqlfluff

models/dbt_v2_sql_lint_demo/
├── .sqlfluff
├── dbt_v2_lint_orders.sql
├── schema.yml
├── README.md
└── DEMO_GUIDE.md

seeds/dbt_v2_sql_lint_demo/
├── dbt_v2_lint_order_events.csv
└── schema.yml
```

## Rules used

The root `.sqlfluff` sets the dbt templater and Snowflake dialect. The demo
`.sqlfluff` enables two focused rules:

| Rule | Meaning | Auto-fix |
| --- | --- | --- |
| `CP01` | SQL keywords must use lowercase | Yes |
| `DBT01` | Each `ref()` or `source()` must be imported through a top-level CTE | No |

Every demo command passes the local configuration with `--config`. This makes
the chosen rules explicit and avoids changing the enabled rules for unrelated
models.

## Step 1. Build the safe model

```bash
dbt build --select dbt_v2_lint_order_events+
```

Expected result:

```text
1 seed
1 model
15 data tests
0 failures
```

## Step 2. Confirm the model passes lint

```bash
dbt lint models/dbt_v2_sql_lint_demo/dbt_v2_lint_orders.sql --config models/dbt_v2_sql_lint_demo/.sqlfluff
```

Expected result: no lint violations.

`dbt lint` is built into dbt v2 Stable. It reads SQLFluff-compatible rule codes
and configuration, but its results can differ from standalone SQLFluff.

## Step 3. Introduce a safe style violation

In `dbt_v2_lint_orders.sql`, change the first lowercase keyword:

```sql
select
```

to:

```sql
SELECT
```

This does not change the query result. It violates the configured lowercase
keyword rule.

## Step 4. See the lint failure

```bash
dbt lint models/dbt_v2_sql_lint_demo/dbt_v2_lint_orders.sql --config models/dbt_v2_sql_lint_demo/.sqlfluff
```

Expected result:

```text
KeywordCaseMismatch: expected Lower, got Upper ('SELECT') [CP01]
```

## Step 5. Auto-fix the file

```bash
dbt lint models/dbt_v2_sql_lint_demo/dbt_v2_lint_orders.sql --config models/dbt_v2_sql_lint_demo/.sqlfluff --fix
```

`--fix` performs one fix pass. Run lint again because one correction can expose
another violation.

```bash
dbt lint models/dbt_v2_sql_lint_demo/dbt_v2_lint_orders.sql --config models/dbt_v2_sql_lint_demo/.sqlfluff
```

Expected result: the file passes again and the demo is back in its safe state.

## Optional DBT01 example

The committed model imports its dependency through a top-level CTE:

```sql
with order_events as (
    select * from {{ ref('dbt_v2_lint_order_events') }}
)

select * from order_events
```

Using `ref()` directly in the final query violates `DBT01`:

```sql
select *
from {{ ref('dbt_v2_lint_order_events') }}
```

`DBT01` cannot be auto-fixed. Restore the top-level CTE manually.

## Useful commands

Return machine-readable results:

```bash
dbt lint models/dbt_v2_sql_lint_demo/dbt_v2_lint_orders.sql --config models/dbt_v2_sql_lint_demo/.sqlfluff --format json
```

Override the configured rules for one command:

```bash
dbt lint models/dbt_v2_sql_lint_demo/dbt_v2_lint_orders.sql --config models/dbt_v2_sql_lint_demo/.sqlfluff --rules CP01
```

## Important limitations

1. `dbt lint` requires dbt v2 or later.
2. SQLFluff compatibility does not guarantee identical results.
3. Studio IDE linting still uses SQLFluff and may report different violations.
4. A root `.sqlfluff` makes Studio use SQLFluff rules for SQL formatting instead
   of its default sqlfmt behavior.
5. `--fix` runs one pass and cannot fix every rule.
6. Review all automatic source-code changes before committing them.

## Official reference

- [dbt lint command](https://docs.getdbt.com/reference/commands/lint)
