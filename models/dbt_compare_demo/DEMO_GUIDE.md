# dbt Compare presenter guide

## Purpose

Use this guide to show that a passing build does not prove that a model returns
the same data as the deployed version.

## Main message

```text
Build proves the change works.
Compare proves what the change does to the data.
```

## Beginner definitions

1. Development is the feature branch result.
2. The deployed baseline is the configured staging environment.
3. A state manifest tells dbt where the deployed relations are.
4. Defer lets development use unselected staging parents.

## Step 1. Show the existing model

Open:

```text
models/dbt_v2_static_analysis_demo/dbt_v2_static_analysis_daily_quality.sql
```

Explain that the model already exists in staging. That matters because a new
model has nothing to compare with.

## Step 2. Show the safe default

```text
dbt_compare_demo_mode: safe
```

Safe mode calculates:

```sql
sum(payment_amount)
```

The default output remains identical to the deployed model.

## Step 3. Show the controlled change

```text
dbt_compare_demo_mode: ten_percent_uplift
```

Compare mode calculates:

```sql
sum(payment_amount) * 1.10
```

Say:

> The model name, columns, types, grain, and tests stay the same. Only one value
> calculation changes.

## Step 4. Build the development slice

```bash
dbt build --select +dbt_v2_static_analysis_daily_quality+ --defer --vars '{"dbt_compare_demo_mode":"ten_percent_uplift"}'
```

Observed result:

```text
2 models represented
1 seed represented
21 tests represented
0 warnings
0 failures
```

Say:

> The build is green. That proves the project executes and tests pass. It does
> not tell us how the values differ from staging.

## Step 5. Run compare

```bash
dbt compare --select dbt_v2_static_analysis_daily_quality+ --defer --vars '{"dbt_compare_demo_mode":"ten_percent_uplift"}'
```

Run this in dbt Cloud CI with staging configured as the deferring environment.
The validated compare step completed successfully in eight seconds.

## Step 6. Show the result

| Date | Staging | Development | Difference |
| --- | ---: | ---: | ---: |
| 2026-09-15 | 173.750 | 191.125 | 17.375 |
| 2026-09-16 | 225.750 | 248.325 | 22.575 |
| 2026-09-17 | 89.990 | 98.989 | 8.999 |

Say:

> Every row still exists. Event counts are unchanged. The one changed column is
> exactly 10 percent higher for every date.

## Step 7. Explain why both commands matter

```text
Build result: pass
Compare result: three modified values
```

Say:

> A green build and a data difference can both be correct. Compare makes the
> difference visible before promotion.

## Step 8. Explain the manifest requirement

The local Studio compare returned:

```text
Compare command requires a state manifest
```

Say:

> The local workspace had the staging table but not the staging manifest. CI had
> both, so compare completed there.

For a self-managed workflow, provide a state directory with `--state` or
`--defer-state`.

## Step 9. Return to safe mode

The default is safe. No cleanup variable is required.

```bash
dbt build --select +dbt_v2_static_analysis_daily_quality+
```

## Five minute presentation order

1. Ask whether a passing build proves unchanged data.
2. Show the existing staging-backed model.
3. Show the default-off 10 percent uplift.
4. Run or show the deferred build.
5. Run or show the staging comparison.
6. Review the three modified values.
7. Explain the manifest requirement.
8. Close with build plus compare.

## Troubleshooting

### Compare says a state manifest is required

Run in a dbt Cloud CI job with a deferring environment, or provide a saved
manifest with `--state` or `--defer-state`.

### The development relation is missing

Run the deferred build before compare.

### Compare shows no difference

Confirm the development build used:

```text
dbt_compare_demo_mode: ten_percent_uplift
```

### Compare uses the wrong baseline

Check the job's configured deferring environment. This project expects staging.

### The comparison is expensive

Keep the selector anchored to the changed model and its necessary downstream
slice.

## Final message

> Tests tell us whether known rules still pass. Compare shows the data change we
> may not have written a test for.
