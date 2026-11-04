# Presenter guide: project macros in YAML

## Opening: 20 seconds

“dbt v2 lets schema YAML call project macros. I can define an allowed-status
policy once and use it for both the column description and the data test.”

Say this is a verified v2 capability. Do not claim a specific Summit announcement
date or imply that SQL-model macros themselves are new.

## Preparation

- Use an isolated development Snowflake destination, never production.
- Open `macros/dbt_v2_yaml_macros_demo/payment_statuses.sql` beside
  `models/dbt_v2_yaml_macros_demo/schema.yml`.
- Have the [walkthrough](README.md) open for copyable commands.
- Keep `--no-manage-state` on each build so demo resources execute again.
- Each build selects only this demo's seed, model, and seven tests.

## Act 1: show the feature, 45 seconds

Point to the macro calls in the column description and in
`accepted_values.arguments.values`. The macro returns a list, and the description
joins that same list. It does not query Snowflake during YAML rendering.

“In v1 these project-macro calls are unavailable in the YAML context. In v2,
macros are registered before this YAML is rendered.”

Build the safe default using walkthrough step 1. Show seven passing tests.
Explain the grain: six payments, one row per payment, five preserved columns.

## Act 2: introduce a valid business change, 45 seconds

Run walkthrough step 2: standard policy, refunded mode.

“Payment P-2006 is now refunded. The standard policy allows only completed,
pending, and cancelled, so the status test should reject the new value.”

Show **six tests passing and the named status test failing**. This is an expected
failure after the deliberately changed row has been written to the dev table.

## Act 3: change policy without editing YAML, 60 seconds

Run walkthrough step 3: extended policy, still refunded mode.

“The input row is still refunded. I changed the policy variable; I did not edit
the test list or its description.”

Show seven passing tests. Run the metadata-inspection command from step 3 and
show `refunded` in the rendered description. The executed status-test SQL also
includes `refunded`. Explain that the macro has one canonical policy definition.

## Act 4: keep the guardrail, 30 seconds

Run walkthrough step 4: extended policy, invalid-status mode.
Show that only the status test fails for `not_a_status`.

“We expanded a legitimate domain; we did not turn off the test.”

## Close and reset, 30 seconds

Run walkthrough step 5. Confirm seven passing tests and a restored standard/safe
fixture. Do not leave the failing version in the development table.

“One project macro, two YAML consumers, and an executable check that stays in
sync with its documentation.”

## Presenter cautions

- This is a YAML-authoring and consistency demo, not a speed/cost benchmark.
- The optional row overrides are presentation controls, not a refund model.
- Keep the same policy variables for builds and metadata/docs inspection.
- Do not generalize schema-YAML macro support to every dbt YAML file.
- See [run evidence](RUN_EVIDENCE.md) for engine version, invocation IDs, test
  outcomes, and production-compare limitations.
