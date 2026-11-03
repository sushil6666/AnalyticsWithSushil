# dbt v2 Stable batch-testing demo

## What this demo teaches

Batch testing is a dbt v2 capability. With `--batch-tests`, dbt combines compatible
`not_null` tests on one model into one query, and compatible `unique` tests into
another query. Each original test still reports its own pass or fail result.

The feature being demonstrated is test execution batching, not a new business
calculation. This guide documents a verified v2 capability; it does not claim a
verified Summit 2026 announcement date.

## The data flow

```text
dbt_v2_batch_order_events (six synthetic orders)
                 |
                 v
        dbt_v2_batch_orders
                 |
                 v
         ten data-test results
```

The model is a table with one row per order. It keeps the seed's six columns:
`order_id`, `payment_id`, `customer_id`, `order_amount`, `order_status`, and
`ordered_at`. The seed has no attached data tests so the query comparison
isolates the ten tests on one model.

## Files in this demo

```text
models/dbt_v2_batch_tests_demo/
├── dbt_v2_batch_orders.sql
├── schema.yml
├── README.md
├── DEMO_GUIDE.md
└── RUN_EVIDENCE.md

seeds/dbt_v2_batch_tests_demo/
├── dbt_v2_batch_order_events.csv
└── schema.yml
```

## Step 1. Build the clean demo

```bash
dbt build --select +dbt_v2_batch_orders+ --batch-tests --no-manage-state
```

Expected result: one seed, one model, and ten passing data tests. The model
contains six rows, six distinct order IDs, six distinct payment IDs, no null
customer IDs, and 255.00 in total order value.

The default mode is `safe`. No project-wide batching configuration is changed.
`--no-manage-state` disables service-backed state reuse for this demonstration,
so repeated invocations actually execute the selected resources.

## Step 2. Compare test execution

After building, run these two commands sequentially:

```bash
dbt test --select dbt_v2_batch_orders --no-manage-state
dbt test --select dbt_v2_batch_orders --no-manage-state --batch-tests
```

For the first command, ensure `DBT_ENGINE_BATCH_TESTS` is unset or false and
batching is not enabled elsewhere in your environment. The tested engine has no
`--no-batch-tests` flag. The second command explicitly enables batching.

| Test group | Individual tests | Without batching | With batching |
| --- | ---: | ---: | ---: |
| Default `not_null`, one per column | 6 | 6 queries | 1 query |
| Default `unique`, order and payment IDs | 2 | 2 queries | 1 query |
| `accepted_values`, order status | 1 | 1 query | 1 query |
| Filtered `not_null`, completed-order amount | 1 | 1 query | 1 query |
| **Total** | **10** | **10 queries** | **4 queries** |

The filtered check is deliberately named `dbt_v2_batch_completed_amount_not_null`
and uses `where: "order_status = 'completed'"`. It runs separately even though
its test type is `not_null`. The default amount check remains eligible.

This is a **60% reduction in test queries**, with the same ten test results.
The counts exclude parsing, metadata, hooks, and other warehouse statements.

### How to verify the query count

After each command, inspect `target/run_results.json` before running the next
command, which overwrites it. Filter results to this model's tests and count
distinct non-null `adapter_response.query_id` values, not result rows. In the
batched run, six null checks share one query ID and two uniqueness checks share
another. The two standalone tests each have their own query ID.

Alternatively, inspect Snowflake Query History for the command's time window
and test SELECT statements against `DBT_V2_BATCH_ORDERS`. Do not count hooks or
metadata queries as test queries. Batched runtime SQL can also be found under
`target/run/` with `aggregated_not_null` and `aggregated_unique` in the filenames.
Generated files are evidence, not source files to edit.

### Observed timings

On the development Snowflake target, the unbatched command took 4.82 seconds
and the batched command took 4.40 seconds in one sequential pair of runs. Both
passed all ten tests. These are whole-command log timings, including setup and
hooks, not isolated warehouse execution times or a repeatable benchmark.

A tiny warm fixture is not a reliable speed or cost benchmark. Warehouse load,
concurrency, caching, and startup overhead affect elapsed time. The measured
query reduction is the main demonstration. See [run evidence](RUN_EVIDENCE.md).

## Step 3. Show that failures remain visible

These commands intentionally return a failing status. Run them only in an
isolated development schema, never against a production target. The build writes
the deliberately bad fixture before its test fails.

### One null customer

```bash
dbt build --select +dbt_v2_batch_orders+ --batch-tests --no-manage-state --vars '{"dbt_v2_batch_tests_demo_mode":"null_customer"}'
```

Only order `O-1002` gets a null `customer_id`. Expected: nine tests pass and
`not_null_dbt_v2_batch_orders_customer_id` fails. The batch still identifies the
specific failing column.

### One duplicated payment reference

```bash
dbt build --select +dbt_v2_batch_orders+ --batch-tests --no-manage-state --vars '{"dbt_v2_batch_tests_demo_mode":"duplicate_payment"}'
```

Order `O-1002` gets payment reference `P-1001`, which is already used by
`O-1001`. Expected: nine tests pass and
`unique_dbt_v2_batch_orders_payment_id` fails. Order IDs remain unique.

## Step 4. Always restore clean data

```bash
dbt build --select +dbt_v2_batch_orders+ --batch-tests --no-manage-state --vars '{"dbt_v2_batch_tests_demo_mode":"safe"}'
```

All ten tests should pass again. Running `dbt test` alone does not restore the
model's rows: rebuild it in safe mode. Unknown mode names raise a compiler error.

## Eligibility and limitations

- Batching applies to `dbt test` and `dbt build` in dbt v2.
- A batch needs at least two compatible tests of the same type on the same model.
- Supported types are default-configured `not_null` and `unique` tests.
- `accepted_values`, relationships, and custom generic tests are not covered by
  this batching feature.
- Tests with `severity`, `error_if`, `warn_if`, `fail_calc`, `limit`, `where`,
  `store_failures`, or `store_failures_as` run separately. This demo uses `where`
  to show that boundary.
- Keep the same model, test selection, thread count, and warehouse when comparing.
- This is a development demo; a production comparison requires a deployed state
  baseline for the new model.

## Official documentation

- [Batch tests](https://docs.getdbt.com/reference/global-configs/batch-tests)
- [New features in dbt v2](https://docs.getdbt.com/docs/dbt-versions/dbt-upgrade/upgrading-to-v2)
- [Data tests](https://docs.getdbt.com/docs/build/data-tests)
