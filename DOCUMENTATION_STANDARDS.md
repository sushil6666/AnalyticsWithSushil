# Documentation standards

## Purpose

This file defines the documentation standards for every public demo in this
repository.

Use it when adding or changing:

- A demo
- A root README section
- A demo `README.md`
- A `DEMO_GUIDE.md`
- dbt model or column descriptions
- Commands, expected results, or troubleshooting steps
- Pull request documentation

The goal is simple: every demo should be accurate, easy for a new dbt user to
understand, safe to share publicly, and easy to present.

## 1. Writing style

Use simple English.

Required:

- Define a dbt term before using it with a beginner.
- Use short sentences and short paragraphs.
- Explain one idea at a time.
- Use examples from the demo.
- Put commands, SQL, YAML, and file paths in fenced code blocks.
- Use numbered steps for tasks that must happen in order.
- Use tables only when they make comparison easier.
- Write `dbt` in lowercase.
- Call the current engine `dbt v2 Stable`.

Avoid:

- Unexplained jargon
- Marketing language
- Repeating the same explanation in multiple sections
- Long paragraphs
- Claims that were not validated
- Em dash characters
- En dash characters

Use a normal hyphen for compound words and `->` for text lineage diagrams when
needed.

## 2. Beginner definitions

A public demo guide should define the terms needed for that demo.

Common definitions:

- A seed is a CSV file that dbt loads into the warehouse.
- A model is a SQL query that creates a table or view.
- A data test checks whether data follows a rule.
- Model lineage shows which dbt resources are connected.
- Column-level lineage shows which input columns created an output column.
- Static analysis means dbt reads and checks SQL before the warehouse runs it.
- A dbt variable changes behavior for one command or run.
- A group identifies the team that owns a dbt resource.

Only include definitions that help explain the demo.

## 3. Root README standard

Each featured demo in the root `README.md` should include:

1. A clear demo title
2. One short explanation of the problem
3. The main command
4. The expected result or main learning point
5. Links to the walkthrough and presenter guide

Use this exact visible link sentence for every featured demo:

```markdown
Read the [walkthrough](path/to/README.md) and
[presenter guide](path/to/DEMO_GUIDE.md).
```

Do not use different labels such as `simple walkthrough` or `beginner
walkthrough` in the root README.

Keep the repository structure section updated when files or directories are
added or removed.

## 4. Demo folder standard

A complete public demo should normally contain:

```text
models/<demo_name>/
├── one or more model SQL files
├── schema.yml
├── README.md
└── DEMO_GUIDE.md

seeds/<demo_name>/
├── sample.csv
└── schema.yml
```

Add macros, tests, snapshots, or groups only when the demo requires them.

Use a clear prefix for demo resources so names do not collide with other
projects or packages.

The committed project must use a safe default. A normal project build should not
fail because a demonstration error is active.

## 5. Demo README standard

The demo `README.md` is the self-service walkthrough.

It should help a reader understand and run the demo without a presenter.

Include:

1. What the demo teaches
2. A simple data flow
3. The files included
4. Beginner definitions needed for the demo
5. The build or test command
6. A plain-English explanation of each important flag
7. Expected rows, values, tests, warnings, or errors
8. How to verify the main behavior
9. How to return the demo to a safe state
10. Requirements and important limitations

Do not turn the README into a presentation script. Put speaking notes in
`DEMO_GUIDE.md`.

## 6. Presenter guide standard

The `DEMO_GUIDE.md` is for presenting, teaching, recording, or demonstrating the
feature.

Include:

1. The purpose in one or two sentences
2. Only the beginner definitions required for the presentation
3. A simple demo flow
4. The files or SQL expressions to show
5. Exact commands in presentation order
6. Expected results
7. Short `Say:` notes where they help
8. A safe reset step when the demo can fail intentionally
9. Important limitations
10. A short troubleshooting section
11. One final takeaway

Recommended size:

| Demo type | Recommended guide size |
| --- | ---: |
| Simple demo | 150 to 250 lines |
| Medium demo | 200 to 300 lines |
| Complex operational demo | 250 to 400 lines |

A guide may be longer when the feature truly needs more setup, but it should not
repeat the README.

Remove:

- Repeated file-by-file explanations already in the README
- Repeated SQL examples
- Old validation history
- Old feature branch names
- Personal environment names
- Hardcoded warehouse relation names
- Personal notification results
- Troubleshooting that does not apply to the public demo

## 7. dbt command standard

Use current dbt syntax.

Required:

- Use `--select` or `-s`.
- Do not use `--models`, `--model`, or `-m`.
- Use commands that were tested in the project.
- Explain unusual flags in the demo README.
- Keep selectors focused on the demo.
- Include a reset command when the demo intentionally causes an error.

Example:

```bash
dbt build --select demo_seed+
```

For dbt v2 column-level lineage, use the validated sequence:

```bash
dbt build --select demo_seed+ --write-index --generate-info-schema --static-analysis strict
dbt show --info column_lineage --limit 100
dbt docs generate --no-compile
```

Do not claim a command succeeds unless it was run successfully.

## 8. SQL and YAML documentation standard

Model descriptions should explain:

- The purpose of the model
- The row grain
- Important calculations or behavior

Column descriptions should explain meaning or transformation. Do not only
repeat the column name.

Use `data_tests:` for new tests unless the existing project convention requires
another supported form.

For seeds used by strict static analysis, declare warehouse column types when
needed so dbt can understand the upstream schema.

Keep SQL examples grounded in actual models and columns. Do not invent columns
that are not present in the demo.

## 9. Public repository safety

Do not publish:

- Passwords, tokens, or private keys
- Private account or environment identifiers
- Internal hostnames
- Hardcoded development schemas
- Personal data
- Private warehouse relation names
- Old incident details that do not help the demo
- Temporary feature branch names in permanent documentation

Use generic terms such as `deployment environment`, `team email`, and `Slack
channel` unless a real value is required and safe to publish.

Keep generated directories out of source control:

```text
target/
logs/
dbt_packages/
```

## 10. Validation standard

Match validation to the change.

For SQL models, seeds, tests, or YAML that changes behavior:

1. Run the focused `dbt build`.
2. Confirm models, seeds, and tests completed as expected.
3. Verify important values or errors.
4. Verify special metadata such as column lineage when applicable.

For YAML structure changes:

```bash
dbt parse
```

For Markdown-only changes, a dbt build is not required.

For all public documentation changes:

1. Check links and file paths.
2. Check commands against current files.
3. Check expected results against validated results.
4. Search for stale model names.
5. Search for merge conflict markers.
6. Search for em dash and en dash characters.
7. Remove private environment details.
8. Review the final Git diff.

## 11. Git standard

Do not commit directly to `main`.

Use a focused branch name:

```text
feat/<clear-task-name>
fix/<clear-task-name>
docs/<clear-task-name>
```

Use Conventional Commit messages:

```text
feat: add dbt v2 column lineage demo
docs: streamline public demo guides
fix: correct demo selector
```

Before raising a pull request:

1. Pull the latest `main`.
2. Resolve every merge conflict.
3. Search for conflict markers.
4. Confirm the working tree is clean.
5. Confirm the branch is up to date.

## 12. Pull request standard

Use an outcome-based title.

The description should include:

1. What changed
2. Why it is useful
3. Important implementation details
4. Validation commands
5. Validation results
6. Known limitations or follow-up work

End PR copy with:

```text
Co-authored by dbt Wizard
```

Do not include results that were not observed.

## 13. Definition of done

A public demo is ready when:

- The normal build uses a safe default.
- The demo behavior was validated.
- The README supports self-service learning.
- The presenter guide supports a short live demo.
- The root README links use the standard wording.
- Commands use current dbt syntax.
- Expected results match observed results.
- No private environment details are present.
- No em dash or en dash characters are present.
- No merge conflict markers are present.
- The branch is clean and current with `main`.
