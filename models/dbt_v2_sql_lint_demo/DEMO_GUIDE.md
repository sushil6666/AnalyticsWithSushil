# dbt v2 Stable SQL lint presenter guide

## Purpose

Use this guide to show a new dbt user how linting checks source-code conventions
and how it differs from building or statically analyzing a model.

## Main message

```text
Lint checks coding conventions.
Static analysis checks SQL meaning.
Build executes the project and runs tests.
```

## Beginner definitions

1. A linter checks source code against agreed rules.
2. A lint rule is one coding standard with a code such as `CP01`.
3. Auto-fix changes a file when dbt can apply a safe correction.

## Step 1. Show the sample project

```text
dbt_v2_lint_order_events
          |
          v
dbt_v2_lint_orders
```

Say:

> The data is intentionally simple. We are demonstrating source-code quality,
> not complex business logic.

## Step 2. Show the configuration

Open the root `.sqlfluff` and
`models/dbt_v2_sql_lint_demo/.sqlfluff`.

Explain:

1. The root file selects the dbt templater and Snowflake dialect.
2. The demo file enables `CP01` and `DBT01`.
3. `CP01` requires lowercase SQL keywords.
4. `DBT01` requires `ref()` and `source()` calls in top-level CTEs.
5. Each command uses `--config` to select the demo rules explicitly.

## Step 3. Build the safe project

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

Say:

> A successful build proves that the SQL runs and the tests pass. It does not
> prove that the SQL follows our coding conventions.

## Step 4. Confirm clean lint

```bash
dbt lint models/dbt_v2_sql_lint_demo/dbt_v2_lint_orders.sql --config models/dbt_v2_sql_lint_demo/.sqlfluff
```

Expected result: no violations.

Say:

> `dbt lint` is built into dbt v2 Stable. It reads SQLFluff-compatible
> configuration and rule codes.

## Step 5. Introduce one style violation

Change the first lowercase `select` in the model to uppercase:

```sql
SELECT
```

Say:

> This change does not alter the data. It violates the team rule that SQL
> keywords must be lowercase.

## Step 6. Run lint again

```bash
dbt lint models/dbt_v2_sql_lint_demo/dbt_v2_lint_orders.sql --config models/dbt_v2_sql_lint_demo/.sqlfluff
```

Expected result:

```text
KeywordCaseMismatch: expected Lower, got Upper ('SELECT') [CP01]
```

## Step 7. Auto-fix and verify

```bash
dbt lint models/dbt_v2_sql_lint_demo/dbt_v2_lint_orders.sql --config models/dbt_v2_sql_lint_demo/.sqlfluff --fix
dbt lint models/dbt_v2_sql_lint_demo/dbt_v2_lint_orders.sql --config models/dbt_v2_sql_lint_demo/.sqlfluff
```

Expected result: the keyword returns to lowercase and the second command passes.

Say:

> `--fix` runs one pass. Run lint again because one fix can expose another
> violation.

## Step 8. Explain the dbt-specific rule

Show the top-level import CTE:

```sql
with order_events as (
    select * from {{ ref('dbt_v2_lint_order_events') }}
)
```

Say:

> `DBT01` encourages dependencies to be imported at the top of the model. This
> makes refs easier to find and keeps the final query focused on transformation
> logic.

Explain that `DBT01` requires a manual correction and is not auto-fixable.

## Five minute presentation order

1. Define linting.
2. Compare lint, static analysis, and build.
3. Show both `.sqlfluff` files.
4. Build the safe model.
5. Run a clean lint.
6. Introduce uppercase `SELECT`.
7. Show `CP01`.
8. Run `--fix` and lint again.
9. Explain `DBT01`.

## Troubleshooting

### `dbt lint` is not recognized

Confirm the environment uses dbt v2 Stable. Earlier dbt versions do not include
this native command.

### The file reports different violations in Studio

Studio IDE linting uses SQLFluff. Native `dbt lint` is SQLFluff-compatible but
not identical.

### A templater warning appears

Confirm the root `.sqlfluff` contains `templater = dbt`, then pass the demo
configuration with `--config` as shown above.

### `--fix` leaves a violation

Run lint again. Some rules need another pass, and some rules require a manual
change.

## Safe reset

The committed file already uses lowercase keywords and a top-level import CTE.
After the `CP01` example, the `--fix` command restores that safe state.

## Final message

> Linting makes coding conventions repeatable. It complements static analysis
> and builds rather than replacing them.
