# dbt Compare demo

## What this demo teaches

This demo shows how to prove what a development change does to data before it is
promoted to the deployed staging environment.

A successful `dbt build` answers:

```text
Does the changed project run and pass its tests?
```

`dbt compare` answers a different question:

```text
How is the development result different from the deployed baseline?
```

## Beginner terms

### Development relation

The development relation contains the result produced by the feature branch.

### Deployed baseline

The deployed baseline is the current relation and manifest from the configured
deferring environment. In this project, that environment is staging.

### State manifest

A state manifest records the deployed project structure and relation names. dbt
uses it to find the correct baseline for comparison.

### Defer

With `--defer`, unselected upstream `ref()` calls can resolve to relations in the
deployed staging environment instead of being rebuilt locally.

## Why this demo reuses an existing model

A brand new model has no deployed relation to compare against.

This demo therefore uses the already deployed model:

```text
dbt_v2_static_analysis_daily_quality
```

The model returns one row per payment date. A default-off variable applies a
controlled 10 percent uplift to `total_payment_amount` in development.

The default remains safe:

```text
dbt_compare_demo_mode: safe
```

The comparison mode is enabled only with:

```text
dbt_compare_demo_mode: ten_percent_uplift
```

## Controlled change

Safe mode:

```sql
sum(payment_amount) as total_payment_amount
```

Compare mode:

```sql
sum(payment_amount) * 1.10 as total_payment_amount
```

The controlled change preserves:

1. The model name
2. The three-row grain
3. Every column name
4. Every column type
5. All existing data tests

Only one column's values change.

## Demo files

```text
models/dbt_compare_demo/
├── README.md
├── DEMO_GUIDE.md
└── RUN_EVIDENCE.md

models/dbt_v2_static_analysis_demo/
├── dbt_v2_static_analysis_daily_quality.sql
└── schema.yml
```

## Step 1. Build and test the development change

Run the changed model with its dependency slice:

```bash
dbt build --select +dbt_v2_static_analysis_daily_quality+ --defer --vars '{"dbt_compare_demo_mode":"ten_percent_uplift"}'
```

The leading `+` includes upstream dependencies. The trailing `+` includes any
downstream dependents.

Observed Studio result:

```text
2 models represented
1 seed represented
21 data tests represented
10 successful executions
16 unchanged resources reused
0 warnings
0 failures
```

A dbt Cloud CI run also built the controlled change successfully in an isolated
comparison schema.

## Step 2. Compare development with deployed staging

Run:

```bash
dbt compare --select dbt_v2_static_analysis_daily_quality+ --defer --vars '{"dbt_compare_demo_mode":"ten_percent_uplift"}'
```

The compare command needs a deployed state manifest. The dbt Cloud CI run used
the configured staging deferral environment and completed successfully in eight
seconds.

A local Studio command without a saved deployed manifest returned:

```text
Compare command requires a state manifest
```

That local message means the baseline manifest was unavailable in the workspace.
It does not mean the staging relation was missing.

For self-managed execution, provide the manifest with `--state` or
`--defer-state`. In dbt Cloud CI, configure the deferring environment so the
baseline is supplied automatically.

## Observed comparison

The comparison preserved all three date rows and changed only
`total_payment_amount`.

| Event date | Staging value | Development value | Difference | Change |
| --- | ---: | ---: | ---: | ---: |
| 2026-09-15 | 173.750 | 191.125 | 17.375 | 10% |
| 2026-09-16 | 225.750 | 248.325 | 22.575 | 10% |
| 2026-09-17 | 89.990 | 98.989 | 8.999 | 10% |

Unchanged behavior:

```text
Rows added: 0
Rows removed: 0
Date keys changed: 0
Event counts changed: 0
Schema changes: 0
```

Changed behavior:

```text
Rows with a modified total_payment_amount: 3
Modified value column: total_payment_amount
Change rate: 10 percent for every row
```

See [RUN_EVIDENCE.md](RUN_EVIDENCE.md) for the captured validation details.

## What the result proves

The build proves the changed project runs and its tests pass.

The comparison proves that the change has a measurable data effect even though:

1. The schema did not change.
2. The row count did not change.
3. The model grain did not change.
4. Every test still passed.

This is why build and compare should be used together for value-level logic
changes.

## Return to safe mode

The variable defaults to `safe`, so the committed behavior remains unchanged
when no comparison variable is supplied.

Run:

```bash
dbt build --select +dbt_v2_static_analysis_daily_quality+
```

## Important limitations

1. The baseline model must already exist in the deployed environment.
2. Compare requires a state manifest or a dbt Cloud deferring environment.
3. Build the development relation before running compare.
4. Compare results describe data differences, not whether those differences are
   good or bad.
5. Large comparisons can use meaningful warehouse compute.
6. Keep the selector anchored to the changed model instead of comparing the
   entire project.

## Validated environment

This project has development and staging environments. The demo compares the
development result with the deployed staging baseline. It does not claim a
separate production environment.

## Official references

- [Project state in dbt](https://docs.getdbt.com/docs/dbt-apis/project-state)
- [Configure State deferral](https://docs.getdbt.com/docs/deploy/dbt-state-deferral)
- [Node selection syntax](https://docs.getdbt.com/reference/node-selection/syntax)
