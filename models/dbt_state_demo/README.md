# dbt State demo

## What this demo teaches

This demo shows how dbt State avoids rebuilding resources when their logic and
inputs have not changed.

It covers:

1. A first run that builds every selected resource.
2. A second identical run that reuses all selected resources.
3. Model-level `lag_tolerance` values.
4. The difference between reuse, skip, clone, and defer.
5. A measured before and after comparison.

## Beginner terms

### dbt State

dbt State compares the current code and upstream data with previous executions.
It then chooses the least expensive safe action for each resource.

### Lag tolerance

`lag_tolerance` controls how long dbt State can wait before rebuilding a model
after upstream data changes.

A freshness change triggers a rebuild only when both are true:

1. Upstream data changed after the previous build.
2. The previous build is older than the model's tolerance window.

A SQL logic change still triggers a rebuild even inside the tolerance window.

### Reuse and skip

Reuse means an existing relation is still valid, so dbt does not rebuild it.
`dbt state explain` describes this as `SKIP_EXECUTION`. The command summary may
show the same decision as a reused resource.

### Clone

Clone means the target relation is missing, but another environment has an
unchanged and sufficiently fresh result. On supported platforms, dbt State can
copy or clone that result instead of running the model SQL again.

### Defer

Defer means an unselected `ref()` resolves to a relation in another environment,
usually production. This lets one changed development model use stable upstream
production relations without rebuilding the whole DAG.

## Demo flow

```text
dbt_state_order_events
          |
          v
dbt_state_stg_orders
       15m tolerance
          |
          v
dbt_state_daily_orders
        4h tolerance
          |
          v
dbt_state_kpi_summary
       24h tolerance
```

The seed contains six orders across two dates. The final model returns one KPI
row.

## Files

```text
models/dbt_state_demo/
├── dbt_state_stg_orders.sql
├── dbt_state_daily_orders.sql
├── dbt_state_kpi_summary.sql
├── schema.yml
├── README.md
├── DEMO_GUIDE.md
└── RUN_EVIDENCE.md

seeds/dbt_state_demo/
├── dbt_state_order_events.csv
└── schema.yml
```

## Model-level configuration

Each model sets its own tolerance in its SQL config:

```sql
{{ config(
    materialized='table',
    state={
        "lag_tolerance": "4h"
    }
) }}
```

The demo uses:

| Model | Materialization | Lag tolerance |
| --- | --- | ---: |
| `dbt_state_stg_orders` | View | 15 minutes |
| `dbt_state_daily_orders` | Table | 4 hours |
| `dbt_state_kpi_summary` | Table | 24 hours |

The different values represent three freshness needs. The staging view is close
to its input, the daily table can wait longer, and the KPI summary is intended
for daily reporting.

## Requirements

1. dbt v2 Stable or another dbt version supported by dbt State.
2. dbt State enabled for the account and current user or job.
3. A supported warehouse.
4. Authentication to the dbt platform State service.

This project does not add a `flags:` block to `dbt_project.yml`. The validated
commands enable State explicitly with `--manage-state`.

## Step 1. Run the first build

```bash
dbt build --select dbt_state_order_events+ --manage-state
```

The first run has no previous State record for these resources, so it builds the
seed, models, and tests.

Observed result:

```text
1 seed executed
3 models executed
25 data tests executed
29 selected resources passed
0 resources reused
38.06 seconds elapsed
```

## Step 2. Run the same command again

```bash
dbt build --select dbt_state_order_events+ --manage-state
```

Nothing changed between the two runs.

Observed result:

```text
29 selected resources reused
0 selected resources rebuilt
2 run hooks still executed
16.07 seconds elapsed
```

## Before and after

| Measurement | First run | Second run |
| --- | ---: | ---: |
| Selected resources | 29 | 29 |
| Selected resources executed | 29 | 0 |
| Selected resources reused | 0 | 29 |
| Elapsed time | 38.06s | 16.07s |
| Elapsed reduction | 0.00s | 21.99s |
| Elapsed reduction percent | 0.0% | 57.8% |

The second run avoided executing:

```text
1 seed load
3 model builds
25 data tests
```

State metadata queries and run hooks still used some time and warehouse
activity. The elapsed reduction is an observed demo result, not a guaranteed
billing reduction. Results vary by warehouse, concurrency, cache state, and
network conditions.

See [RUN_EVIDENCE.md](RUN_EVIDENCE.md) for the captured run details.

## Step 3. Explain the latest State decisions

```bash
dbt state explain --verbose --select tag:dbt_state_demo
```

Normally, this reads the latest response file and shows decisions such as:

```text
SKIP_EXECUTION model.example - query is current and upstream data is within tolerance
```

In the validated Studio session, the command returned `No log files found`
because no `logs/state/` response file was persisted. The build summary still
reported all 29 selected resources as reused.

In dbt platform job run details, open the **Explain** tab to see the same
node-level decisions when that interface is available.

## Reuse, skip, clone, and defer

| Decision | When it happens | Warehouse effect |
| --- | --- | --- |
| Reuse | The target relation exists and remains valid | Model SQL is not rebuilt |
| Skip execution | State's internal decision for valid existing work | Appears as reused in summaries |
| Clone | Target is missing but a matching deferred result exists | Copies the result instead of recomputing it |
| Defer | An unselected upstream relation is missing locally | Reads the relation from the deferred environment |
| Normal build | Reuse and clone are not safe | Executes the model SQL normally |

## Clone and defer exercise

Clone and defer need at least two configured targets or environments.

A typical flow is:

1. Build the complete DAG in the deployment target.
2. Start with an empty development schema.
3. Select only `dbt_state_kpi_summary` in development.
4. dbt State defers its unselected upstream refs to the deployment environment.
5. If the selected table is unchanged and eligible, dbt State clones it instead
   of rebuilding it.

This Studio session had one active development target, so clone was documented
but not included in the captured before and after run. The command output did
confirm that dbt State was enabled and configured to defer to `prod`.

## Expected data

The final model returns:

| Metric | Value |
| --- | ---: |
| Reporting days | 2 |
| Orders | 6 |
| Completed orders | 3 |
| Gross order amount | 605.50 |
| Completion rate | 50% |

## Important limitations

1. `lag_tolerance` applies to data freshness, not SQL logic changes.
2. dbt State requires login and is a usage-based feature after its trial.
3. Reuse does not mean zero activity. Metadata checks and hooks can still run.
4. Clone behavior depends on the warehouse, relation type, permissions, and
   available deferred environment.
5. Incremental SQL can change between the first and later run, which can trigger
   downstream rebuilds even inside a tolerance window.
6. Timing and savings vary across environments.

## Official references

- [About dbt State](https://docs.getdbt.com/docs/deploy/dbt-state-about)
- [dbt State examples](https://docs.getdbt.com/docs/deploy/dbt-state-examples)
- [`lag_tolerance` configuration](https://docs.getdbt.com/reference/resource-configs/lag-tolerance)
- [dbt State configurations](https://docs.getdbt.com/reference/resource-configs/dbt-state-configs)
- [`dbt state explain`](https://docs.getdbt.com/reference/commands/state-explain)
- [Configure State deferral](https://docs.getdbt.com/docs/deploy/dbt-state-deferral)
