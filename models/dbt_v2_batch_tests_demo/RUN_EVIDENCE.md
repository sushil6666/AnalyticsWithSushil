# dbt v2 Stable batch-testing run evidence

## Environment and scope

- Validated on 2026-11-03 using the dbt v2 Stable engine available in Studio
  (reported version 2.1.0.dev20261103), Snowflake, target `default`, six threads.
- Development model: `DBT_DB.DBT_V2_BATCH_TESTS_DEMO.DBT_V2_BATCH_ORDERS`.
- Development seed: `DBT_DB.DBT_V2_BATCH_TESTS_DEMO_SEED.DBT_V2_BATCH_ORDER_EVENTS`.
- Six rows, six distinct order IDs, six distinct payment IDs, zero null customer
  IDs, total order value 255.00 in safe mode.
- The comparison commands disabled dbt State reuse with `--no-manage-state`.
- These are development validation results, not production metrics.

## Successful clean build

The initial strict-analysis build with batching passed all ten tests.
Invocation: `f32c8ce7-9d85-40b1-bf04-244eff45ce5f`.

```bash
dbt build --select +dbt_v2_batch_orders+ --defer --batch-tests --static-analysis strict
```

The seed was reused on this first model build because it had already been loaded
and previewed. The final reset below rebuilt all twelve resources without reuse.

## Sequential test-only comparison

| Run | Invocation ID | Test results | Distinct test-query IDs | Command log elapsed |
| --- | --- | --- | ---: | ---: |
| Unbatched | `9a9e0371-572f-4755-b717-b7f3693c479b` | 10 passed | 10 | 4.82 seconds |
| Batched | `ed93d555-4cd8-4a72-811e-62c379ca81ad` | 10 passed | 4 | 4.40 seconds |

```bash
dbt test --select dbt_v2_batch_orders --no-manage-state
dbt test --select dbt_v2_batch_orders --no-manage-state --batch-tests
```

The unbatched invocation ran between 16:05:30 and 16:05:35 UTC. Snowflake Query
History confirmed these ten SELECT query IDs against the demo model:

```text
01c82ac5-0205-2c11-0005-b18e0007e69e
01c82ac5-0205-2c11-0005-b18e0007e6a2
01c82ac5-0205-2c10-0005-b18e0007676e
01c82ac5-0205-2c10-0005-b18e00076772
01c82ac5-0205-2c11-0005-b18e0007e6a6
01c82ac5-0205-2c11-0005-b18e0007e6ae
01c82ac5-0205-2c11-0005-b18e0007e6aa
01c82ac5-0205-2c10-0005-b18e00076776
01c82ac5-0205-2c10-0005-b18e0007677a
01c82ac5-0205-2c10-0005-b18e0007677e
```

The batched invocation's `run_results.json` contained ten individual test
results sharing these four query IDs:

| Query ID | Test group | Individual test results |
| --- | --- | ---: |
| `01c82ac5-0205-2c10-0005-b18e0007678e` | Six default `not_null` tests | 6 |
| `01c82ac5-0205-2c11-0005-b18e0007e6b2` | Two default `unique` tests | 2 |
| `01c82ac5-0205-2c10-0005-b18e00076792` | Order-status accepted values | 1 |
| `01c82ac5-0205-2c10-0005-b18e0007678a` | Filtered completed-order amount null check | 1 |

The logs also recorded runtime SQL for `aggregated_not_null` and
`aggregated_unique`. This confirms actual batching rather than skipped tests.

Test-query reduction: (10 - 4) / 10 = **60%**. Counts exclude hooks, metadata,
setup, and all non-test statements. Timings are whole-command log durations,
including overhead, from one pair of runs. They do not establish a repeatable
runtime improvement or warehouse credit savings.

## Intentional failure checks

Both checks used `dbt build --select +dbt_v2_batch_orders+ --batch-tests
--no-manage-state` with the mode passed through `--vars`.

| Mode | Invocation ID | Outcome |
| --- | --- | --- |
| `null_customer` | `d151a323-dd19-4b1a-b952-1af12342993f` | 9 tests passed; only `not_null_dbt_v2_batch_orders_customer_id` failed |
| `duplicate_payment` | `6dd71e61-18dd-48b6-a00e-304464810eea` | 9 tests passed; only `unique_dbt_v2_batch_orders_payment_id` failed |

The seed and model built successfully in each failure scenario. The nonzero
status came from the intended test, not a SQL execution error. Individual test
identities remained visible even though their execution was batched.

## Final safe reset

```bash
dbt build --select +dbt_v2_batch_orders+ --defer --batch-tests --no-manage-state --static-analysis strict --vars '{"dbt_v2_batch_tests_demo_mode":"safe"}'
```

Invocation: `6cbd8ebe-6c3c-465c-96ee-48f753352e6a`.

Result: **1 seed, 1 model, and all 10 data tests passed; no resources reused**.
The development table was left in safe mode.

## Production comparison limitation

```bash
dbt compare --select dbt_v2_batch_orders+ --defer
```

Invocation: `da5ea079-b859-43d4-b4e5-65ccac981fb8`.

Compare stopped with: `Compare command requires a state manifest (via --state,
--defer-state, or dbt Cloud)`. No production diff was available. The build and
failure-mode results above validate development only; a future production
comparison requires a configured state baseline.

## Sources

- [Batch tests](https://docs.getdbt.com/reference/global-configs/batch-tests)
- [Walkthrough](README.md)
- [Presenter guide](DEMO_GUIDE.md)
