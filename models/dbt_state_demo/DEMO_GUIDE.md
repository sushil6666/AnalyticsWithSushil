# dbt State presenter guide

## Purpose

Use this guide to show a new dbt user how two identical commands can produce two
very different execution plans when dbt State is enabled.

## Main message

```text
First run: build the resources and record State.
Second run: compare, skip execution, and reuse valid results.
```

## Beginner definitions

1. dbt State compares current logic and data with earlier executions.
2. `lag_tolerance` is the allowed delay after upstream data changes.
3. Reuse keeps a valid relation instead of rebuilding it.
4. Clone copies a valid result into a missing target relation.
5. Defer resolves an unselected upstream `ref()` in another environment.

## Step 1. Show the DAG

```text
seed -> staging view -> daily table -> KPI table
```

Show the model-level values:

```text
staging view: 15m
daily table: 4h
KPI table: 24h
```

Say:

> Each model has a different freshness need. dbt State uses those tolerances when
> upstream data changes, but a SQL logic change still forces a rebuild.

## Step 2. Show one model config

Open `dbt_state_daily_orders.sql`:

```sql
state={
    "lag_tolerance": "4h"
}
```

Say:

> This is model-level State configuration. It does not mean the table rebuilds
> every four hours. It becomes eligible after four hours when upstream data has
> also changed.

## Step 3. Run the first build

```bash
dbt build --select dbt_state_order_events+ --manage-state
```

Observed first-run result:

```text
29 selected resources executed
0 reused
38.06 seconds
```

Say:

> These resources had no previous State record, so dbt built them and stored the
> information needed for later decisions.

## Step 4. Run the identical command

```bash
dbt build --select dbt_state_order_events+ --manage-state
```

Observed second-run result:

```text
29 selected resources reused
0 selected resources rebuilt
16.07 seconds
```

Say:

> The command did not change. The execution plan changed because dbt State knew
> the logic and data were still valid.

## Step 5. Show the before and after

| Measurement | First run | Second run |
| --- | ---: | ---: |
| Executed resources | 29 | 0 |
| Reused resources | 0 | 29 |
| Elapsed time | 38.06s | 16.07s |
| Time avoided | 0.00s | 21.99s |
| Elapsed reduction | 0.0% | 57.8% |

Explain what was avoided:

```text
1 seed load
3 model builds
25 data tests
```

Clarify:

> Two run hooks and State metadata checks still ran. This is reduced execution,
> not a promise of zero compute or an exact billing reduction.

## Step 6. Explain reuse and skip

Say:

> Reuse is the user-facing result. `SKIP_EXECUTION` is the State decision that
> prevents the build. Different interfaces can describe the same optimized node
> as skipped or reused.

## Step 7. Explain clone and defer

Use this fresh-development example:

```text
Production has the complete DAG.
Development has an empty schema.
Only the KPI model is selected.
```

Explain:

1. Unselected upstream refs defer to production.
2. If the selected table has an unchanged valid result in production, State can
   clone it into development.
3. If clone is not safe, dbt performs a normal build using deferred upstream
   relations.

Say:

> Defer answers where missing parents come from. Clone answers how an unchanged
> selected table can appear without recomputing it.

## Step 8. Show State explain

```bash
dbt state explain --verbose --select tag:dbt_state_demo
```

In a session with persisted response logs, this shows the decision and analysis
for each selected node.

Observed limitation in this Studio session:

```text
No log files found.
```

The build summary still recorded 29 reused resources. In dbt platform jobs, use
the run's **Explain** tab when available.

## Step 9. Show the final data

```text
2 reporting days
6 orders
3 completed orders
605.50 gross order amount
50% completion rate
```

## Five minute presentation order

1. Define dbt State and lag tolerance.
2. Show the three-model DAG.
3. Show model-level tolerances.
4. Run or show the first build.
5. Run or show the second identical build.
6. Compare executed and reused resources.
7. Explain reuse, skip, clone, and defer.
8. Close with the compute and freshness tradeoff.

## Troubleshooting

### dbt State is not enabled

Confirm the account feature is enabled, authenticate with dbt, and include
`--manage-state` in the command.

### The second run rebuilds a model

Check for SQL changes, upstream data changes, expired tolerance, hooks, volatile
SQL, missing target relations, or unsupported clone conditions.

### `dbt state explain` finds no logs

Use the Explain tab in a dbt platform run, or confirm that `logs/state/` response
files are persisted in the execution environment.

### A fresh development run fails on an upstream ref

Confirm the deferred target or environment is configured and accessible.

## Final message

> dbt State changes execution from rebuild everything to rebuild only what is no
> longer safe to reuse.
