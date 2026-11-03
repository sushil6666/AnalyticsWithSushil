# dbt v2 Stable batch-testing presenter guide

## Purpose

Show a dbt v2 execution feature: ten test results can come from four test
queries, while failures still identify the original test and column.

This is a verified dbt v2 capability. A specific Summit 2026 announcement date
has not been verified; avoid claiming one in the presentation.

## Before presenting

1. Use dbt v2 Stable and an isolated Snowflake development target.
2. Open `dbt_v2_batch_orders.sql`, the model's `schema.yml`, and `RUN_EVIDENCE.md`.
3. Ensure `DBT_ENGINE_BATCH_TESTS` is unset or false for the baseline.
4. Keep the warehouse and thread count unchanged across both test commands.
5. Build the clean fixture before starting.

```bash
dbt build --select +dbt_v2_batch_orders+ --batch-tests --no-manage-state
```

Expected: one six-row seed, one six-row model, ten passing data tests.

## Step 1. Explain the existing execution pattern

Say:

> Every check is useful, but sending one warehouse query per check adds overhead.
> dbt v2 can batch compatible tests without removing any assertions.

Show the six default `not_null` tests and two default `unique` tests in the
model's YAML. Point out the two exceptions: `accepted_values` and the separately
named amount null check with a `where` filter.

## Step 2. Run the baseline

```bash
dbt test --select dbt_v2_batch_orders --no-manage-state
```

Expected: ten tests pass using ten test queries. The tested engine does not
support `--no-batch-tests`; the baseline omits the flag and assumes batching is
not enabled by the environment.

Before the next command overwrites it, inspect `target/run_results.json` and
count distinct test `adapter_response.query_id` values. Snowflake Query History
is an alternative for confirming query counts within the command's time window.

## Step 3. Enable batching

```bash
dbt test --select dbt_v2_batch_orders --no-manage-state --batch-tests
```

Expected: all ten tests still pass. Six null checks share one query ID; two
uniqueness checks share another. The filtered null check and accepted-values
check run separately: four test-query IDs in total.

Say:

> We kept ten assertions and reduced the test queries from ten to four. This is
> batching, not dbt State reuse; we disabled state reuse in both commands.

The observed development run took 4.82 seconds without batching and 4.40 seconds
with it. Explain that one tiny fixture is not a speed or cost benchmark. Lead
with the measured 60% reduction in test queries, not a performance promise.

## Step 4. Prove that failure reporting still works

Run the null-customer mode:

```bash
dbt build --select +dbt_v2_batch_orders+ --batch-tests --no-manage-state --vars '{"dbt_v2_batch_tests_demo_mode":"null_customer"}'
```

Expected: the build fails intentionally. Nine tests pass and the customer null
test fails. Show `not_null_dbt_v2_batch_orders_customer_id` in the output.

Optionally show the uniqueness batch too:

```bash
dbt build --select +dbt_v2_batch_orders+ --batch-tests --no-manage-state --vars '{"dbt_v2_batch_tests_demo_mode":"duplicate_payment"}'
```

Expected: nine tests pass and `unique_dbt_v2_batch_orders_payment_id` fails.
Only the second order's payment reference is changed; order IDs remain unique.

## Step 5. Restore the model before finishing

```bash
dbt build --select +dbt_v2_batch_orders+ --batch-tests --no-manage-state --vars '{"dbt_v2_batch_tests_demo_mode":"safe"}'
```

Expected: all ten tests pass. A failing build has already materialized the bad
fixture, so a successful test-only invocation is not a substitute for rebuilding.

## Troubleshooting

- **Tests were reused:** retain `--no-manage-state` on both comparison commands.
- **Baseline already has batches:** check the batching environment variable.
- **Some tests run separately:** inspect test type and config. `where`, severity
  and thresholds, failure storage, `fail_calc`, and `limit` exclude batching.
- **Ten result rows remain:** expected; count distinct query IDs, not test rows.
- **Elapsed time does not improve:** focus on query reduction. Startup, hooks,
  warehouse cache, load, and concurrency can dominate six-row demonstrations.
- **Failures persist after omitting the variable:** explicitly rebuild safe mode.
- **Production compare is unavailable:** this new model needs a deployed state
  baseline; failure-mode runs are validated against development only.

## Closing message

> dbt v2 batches compatible test execution, preserves individual test results,
> and lets incompatible checks keep their existing behavior.

## References

- [Batch tests](https://docs.getdbt.com/reference/global-configs/batch-tests)
- [Walkthrough](README.md)
- [Measured run evidence](RUN_EVIDENCE.md)
