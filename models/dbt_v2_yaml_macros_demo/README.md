# dbt v2 Stable: project macros in schema YAML

## What this demo teaches

**One project macro drives both a documented status list and an executable data test.**
In v2, project macros are registered before schema YAML is rendered, so you can
call them directly in YAML values. In v1, the restricted YAML Jinja context does
not include project macros; the same call fails with an undefined-macro error.

This demonstrates a verified v2 authoring capability, not a new payment
calculation. A specific Summit 2026 announcement date has not been verified.
The example was tested with the environment's v2 engine, which reported
`2.1.0.dev20261103`; it is not a certification for every v2 release.

## Design

```text
dbt_v2_yaml_payment_events (six synthetic payments)
                    |
                    v
          dbt_v2_yaml_payments
                    |
                    v
            seven data tests

payment_statuses.sql -- called by schema.yml --> description + accepted_values
```

The table has one row per payment and preserves all five fixture columns:
`payment_id`, `customer_id`, `payment_status`, `payment_amount`, and `paid_at`.
Only `P-2006` changes status in opt-in demo modes. Amounts and timestamps stay
unchanged; this is not refund accounting or revenue recognition.

A dedicated fixture/model keeps deliberate failures isolated from other demos.
No packages or project-wide settings are added. The model uses strict static
analysis. Seven tests cover five non-null columns, unique payment IDs, and the
macro-supplied allowed statuses. The status test has the stable name
`dbt_v2_yaml_payment_status_allowed`.

## Files

- [Model](dbt_v2_yaml_payments.sql)
- [Schema YAML: the two macro call sites](schema.yml)
- [Shared policy macro](../../macros/dbt_v2_yaml_macros_demo/payment_statuses.sql)
- [Synthetic seed](../../seeds/dbt_v2_yaml_macros_demo/dbt_v2_yaml_payment_events.csv)
- [Seed configuration](../../seeds/dbt_v2_yaml_macros_demo/schema.yml)
- [Presenter guide](DEMO_GUIDE.md)
- [Observed run evidence](RUN_EVIDENCE.md)

## Two independent controls

| Variable | Default | Supported values |
| --- | --- | --- |
| `dbt_v2_yaml_macros_demo_policy` | `standard` | `standard`, `extended` |
| `dbt_v2_yaml_macros_demo_mode` | `safe` | `safe`, `refunded`, `invalid_status` |

The macro returns a native list, using `return`, for the YAML test's
`arguments.values`. The description calls the same macro and joins the list.
`standard` allows `completed`, `pending`, and `cancelled`; `extended` also allows
`refunded`. The independent mode injects either `refunded` or `not_a_status` into
`P-2006`. Unknown policy or mode names raise compiler errors.

## 1. Build the safe default

Run in an isolated **development** target with Snowflake write permissions.
This repo's schema-generation macro uses explicit custom schema names on dev
targets; check the resolved schemas before running in a shared account.

```bash
dbt build --select +dbt_v2_yaml_payments+ --no-manage-state
```

Expected: **one seed, one model, seven passing data tests**. Six payment IDs are
unique, and every column is non-null. `--no-manage-state` disables service-backed
reuse so the selected resources execute on repeated demo runs.

## 2. Keep the standard policy and introduce a refund

```bash
dbt build --select +dbt_v2_yaml_payments+ --no-manage-state --vars '{"dbt_v2_yaml_macros_demo_policy":"standard","dbt_v2_yaml_macros_demo_mode":"refunded"}'
```

Expected intentional failure: **six tests pass; the status test fails**.
The executed test SQL allows only the standard three statuses.

## 3. Accept that same row through the extended policy

```bash
dbt build --select +dbt_v2_yaml_payments+ --no-manage-state --vars '{"dbt_v2_yaml_macros_demo_policy":"extended","dbt_v2_yaml_macros_demo_mode":"refunded"}'
```

Expected: **all seven tests pass**. No SQL or YAML edits are needed. The
macro-supplied test list and rendered description now both include `refunded`.

Inspect rendered metadata while supplying the same policy:

```bash
dbt ls --select dbt_v2_yaml_payments --resource-type model --output json --output-keys name columns --vars '{"dbt_v2_yaml_macros_demo_policy":"extended","dbt_v2_yaml_macros_demo_mode":"refunded"}'
```

The `payment_status` description should read:
“Allowed payment statuses from the project macro: completed, pending, cancelled, refunded.”
The command's test-node logs also show those four values in the executed SQL.

## 4. Prove an invalid status is still rejected

```bash
dbt build --select +dbt_v2_yaml_payments+ --no-manage-state --vars '{"dbt_v2_yaml_macros_demo_policy":"extended","dbt_v2_yaml_macros_demo_mode":"invalid_status"}'
```

Expected intentional failure: **six tests pass; the status test fails**.
Adding a legitimate status has not disabled validation.

## 5. Always restore safe data and the standard policy

```bash
dbt build --select +dbt_v2_yaml_payments+ --no-manage-state --vars '{"dbt_v2_yaml_macros_demo_policy":"standard","dbt_v2_yaml_macros_demo_mode":"safe"}'
```

Expected: **all seven tests pass**. A test-only command does not restore rows.
The model blocks non-safe modes on targets named `prod`, `production`, `uat`, or
`candidate`; that name check is only a guardrail, not an environment guarantee.
Never run deliberate-failure modes against a production destination.

## Practical boundaries

- Ordinary SQL-model macros and built-in YAML functions such as `var()` already
  existed in v1. The v2 feature here is **calling a project macro from schema YAML**.
- This does not mean all YAML files have the full SQL Jinja context. Check the
  file-support matrix; for example, custom macros in `dbt_project.yml` are limited
  to hooks, and `packages.yml` does not support them.
- Keep YAML-rendering macros deterministic and warehouse-free. This macro only
  reads a variable and returns a list; it runs during parsing.
- Policy variables affect parsing globally. Pass the same policy to builds,
  metadata inspection, and docs generation to keep artifacts consistent.
- `accepted_values` checks non-null values; the separate `not_null` test protects
  against null statuses.
- Production comparison requires a deployed state baseline; see run evidence.

## Official references

- [v2 changes: calling project macros in YAML](https://docs.getdbt.com/docs/dbt-versions/dbt-upgrade/upgrading-to-v2#calling-project-macros-in-yaml-files)
- [Jinja support by file type](https://docs.getdbt.com/reference/jinja-file-support)
- [Macro return types](https://docs.getdbt.com/reference/dbt-jinja-functions/return)
- [Data tests and accepted values](https://docs.getdbt.com/reference/resource-properties/data-tests)
