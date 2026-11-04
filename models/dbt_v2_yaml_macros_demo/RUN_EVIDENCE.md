# Run evidence: dbt v2 project macros in YAML

## Environment and scope

Validated on 2026-11-04 against the development Snowflake target `default`, using
six threads. The installed v2 engine reported `2.1.0.dev20261103`.

- Seed: `DBT_DB.dbt_v2_yaml_macros_demo_seed.dbt_v2_yaml_payment_events`
- Model: `DBT_DB.dbt_v2_yaml_macros_demo.dbt_v2_yaml_payments`
- Selection: `+dbt_v2_yaml_payments+`
- State reuse disabled with `--no-manage-state` on all builds.
- Model configuration: table materialization, strict static analysis.
- Each full build selected one seed, one model, and seven data tests.
- No production analytical data was queried. Development previews explicitly
  used `--no-defer`.

## Observed outcomes

| Check | Policy / mode | Observed result | Invocation ID |
| --- | --- | --- | --- |
| Full parse | standard / safe | Passed | `6de4c67f-b3bf-43f4-9a2a-4361b7dd71d2` |
| Initial full build | standard / safe | Seed + model succeeded; 7 tests passed | `3f5553e0-8008-4f6c-8727-3ec31c78ed8f` |
| Refund rejected | standard / refunded | Seed + model succeeded; 6 tests passed, 1 failed | `c45c64ec-1e8c-44df-a90e-7a6460719176` |
| Refund accepted | extended / refunded | Seed + model succeeded; 7 tests passed | `623576fb-6ad6-4866-b297-54c962825872` |
| Rendered metadata | extended / refunded | Description includes refunded | `89c52566-6d4f-4687-ad06-8a707de5c479` |
| Invalid status rejected | extended / invalid_status | Seed + model succeeded; 6 tests passed, 1 failed | `f65057ad-9fb6-44f4-af09-694ad9e16635` |
| Invalid policy | unknown / safe | Failed during schema-YAML rendering as intended | `09708d55-80a4-4184-8cb2-a4fe67d29683` |
| Safe reset, full parse | standard / safe | Seed + model succeeded; 7 tests passed | `f49e6c51-46fe-419c-8f3f-3939cc392019` |
| Final dev profile | standard / safe | 6 rows, 6 unique payments, no nulls or nonstandard statuses | `5a6627fe-09ab-42e8-80d9-7893b2f9d296` |
| Final repeat, full parse | standard / safe | Seed + model succeeded; 7 tests passed | `a44dfd4f-1436-4d1f-92eb-0c4004493d83` |

The only failing data test in both deliberate-failure builds was
`dbt_v2_yaml_payment_status_allowed`. All five null checks and the unique payment
ID check passed. No resources were skipped in the full builds.

The build command summaries reported one command-level warning; the bounded
command output did not expose its text. The structured resource summaries
reported zero warned tests. These results establish passing tests, not a claim
of warning-free project execution.

## How these were executed

The initial and scenario builds used the following command shape, with policy
and mode supplied as shown in the table (the initial build used defaults):

```bash
dbt build --select +dbt_v2_yaml_payments+ --defer --no-manage-state --quiet --warn-error-options '{"error":["NoNodesForSelectionCriteria"]}' --vars '{"dbt_v2_yaml_macros_demo_policy":"extended","dbt_v2_yaml_macros_demo_mode":"refunded"}'
```

The safe reset additionally used `--no-partial-parse`. The final repeat validated
the walkthrough's standalone command without `--defer` or quiet logging:

```bash
dbt build --select +dbt_v2_yaml_payments+ --no-manage-state --no-partial-parse --vars '{"dbt_v2_yaml_macros_demo_policy":"standard","dbt_v2_yaml_macros_demo_mode":"safe"}'
```

## Proof that both YAML consumers change

The standard/refunded build's executed test SQL contained:

```sql
where value_field not in (
    'completed','pending','cancelled'
)
```

The extended/refunded build's executed test SQL contained:

```sql
where value_field not in (
    'completed','pending','cancelled','refunded'
)
```

The named test retained the same unique ID in these builds:
`test.analytics_with_sushil.dbt_v2_yaml_payment_status_allowed.6b338101c5`.
The extended build's test-node output was inspected directly to verify the
executed SQL, not just its pass result.

Rendered metadata from `dbt ls` showed the extended column description:

```text
Allowed payment statuses from the project macro: completed, pending, cancelled, refunded.
```

The invalid-policy parse failed inside the custom macro called from
`schema.yml`, with:

```text
dbt_v2_yaml_macros_demo_policy must be standard or extended
```

No SQL/YAML edits occurred between the standard and extended scenario builds;
only the command variables changed.

## Restored development data

A development-only profile with `dbt show --no-defer` returned:

| Field | Observed value |
| --- | ---: |
| Rows | 6 |
| Distinct payment IDs | 6 |
| Rows with any null field | 0 |
| Total fixture amount | 255.00 |
| Refunded rows | 0 |
| Statuses outside the standard domain | 0 |

The amount was rendered with `to_varchar(sum(payment_amount))` to preserve its
decimal scale in command output. This is a synthetic fixture total, not a revenue
metric. The final repeat rebuilt the same standard/safe fixture successfully.

## Production comparison limitation

After the successful safe reset, the following was attempted:

```bash
dbt compare --select dbt_v2_yaml_payments+ --defer
```

Invocation `c307b394-e862-4558-8057-60ea5dbd7a69` failed with
`InvalidArgument (dbt1007)`:

```text
Compare command requires a state manifest (via --state, --defer-state, or dbt Cloud)
```

No production diff was available to render. A production comparison remains
unverified and needs an available deployed baseline/state manifest.

## Guided screenshot session

On 2026-11-04, the demo was rerun one phase at a time on the development target
`default`. The user confirmed capturing all seven checkpoints. Image contents,
actual filenames, and repository publication have not been independently
verified; the filenames below are the suggested capture names, not image links.

| Screenshot | Suggested filename | Result or content | Fresh invocation ID |
| --- | --- | --- | --- |
| 1 | `01-macro-and-yaml.png` | Project macro beside its description and test-argument call sites | File inspection; no dbt command |
| 2 | `02-safe-baseline-passes.png` | standard / safe: 7 tests passed | `6ddd794f-99ca-4a6c-98cb-a75f5341f65a` |
| 3 | `03-standard-refund-fails.png` | standard / refunded: 6 tests passed, status test failed | `82a1a772-a4c8-46ba-981f-825b316cc4c1` |
| 4 | `04-extended-refund-passes.png` | extended / refunded: 7 tests passed | `a983ea69-1c65-4fe8-9efb-a34f8a32a408` |
| 5 | `05-rendered-description.png` | Rendered payment_status description includes refunded | `58c2bc23-1327-49b6-8a6c-7d52e9f2a1bc` |
| 6 | `06-invalid-status-rejected.png` | extended / invalid_status: 6 tests passed, status test failed | `d835bc66-3149-4c43-892e-b30b32f3c649` |
| 7 | `07-safe-reset-passes.png` | standard / safe restored: 7 tests passed | `3a6371e3-e26b-4131-a978-25d856ba5892` |

All five builds succeeded in creating the seed and model; the two intentional
failures were confined to `dbt_v2_yaml_payment_status_allowed`. Each build used
`--select +dbt_v2_yaml_payments+ --no-manage-state` with explicit policy and mode
variables. No SQL or YAML edits were made between these screenshot phases.
The same command-level warning caveat described above applies.

The final reset completed successfully before the user confirmed screenshot 7.
The model is left in standard/safe mode, with no deliberately invalid status.
No new production comparison was attempted during the screenshot session; the
previous missing-state-manifest limitation remains unresolved.

For publication, add the original captures to a `screenshots/` folder alongside
this document, confirm the actual filenames, and link the images only once they
exist in the repository. Keep commands, policy/mode variables, test names, and
reported warnings visible; redact sensitive account details as needed.


## Attribution and references

Official documentation explicitly identifies project-macro calls in YAML as a
v2 capability unavailable in v1. A specific Summit 2026 announcement was not
independently verified. No v1 engine was run here; the v1 limitation is the
vendor-documented behavior, while the v2 results above were executed.

- [v2 YAML macro support](https://docs.getdbt.com/docs/dbt-versions/dbt-upgrade/upgrading-to-v2#calling-project-macros-in-yaml-files)
- [Jinja support by file type](https://docs.getdbt.com/reference/jinja-file-support)
- [Macro return types](https://docs.getdbt.com/reference/dbt-jinja-functions/return)
