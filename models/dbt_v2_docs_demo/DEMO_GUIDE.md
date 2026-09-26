# dbt Docs v2 generation presenter guide

## Purpose

Use this guide to explain the documentation architecture change to someone who
is new to dbt.

```text
Legacy dbt Docs loaded JSON metadata.
dbt Docs v2 queries Parquet metadata with DuckDB WASM.
```

## Beginner terms

1. Documentation explains models, columns, tests, SQL, and lineage.
2. Metadata is information about the dbt project.
3. An artifact is a file produced by dbt.
4. Parquet is a compact column-based file format.
5. DuckDB WASM is a small database engine that runs in the browser.

## Step 1. Show the sample project

```text
dbt_v2_docs_order_events
          |
          v
dbt_v2_docs_orders
          |
          v
dbt_v2_docs_daily_summary
```

Say:

> The seed contains six sample orders. The first model prepares the orders. The
> final model creates one row for each order date.

Open `schema.yml` and show that dbt documentation starts with model and column
descriptions written by the project team.

## Step 2. Explain the legacy flow

```text
SQL and YAML
     |
     v
manifest.json + catalog.json
     |
     v
Browser loads JSON
     |
     v
Documentation website
```

Say:

> The legacy browser loaded JSON files containing project and warehouse
> metadata. On a large project, those files could become large for the browser to
> download and process.

## Step 3. Explain the dbt Docs v2 flow

```text
SQL and YAML
     |
     v
Parquet metadata index
     |
     v
DuckDB WASM queries Parquet
     |
     v
Documentation website
```

Say:

> dbt Docs v2 creates compact Parquet metadata. DuckDB runs in the browser and
> queries the information needed for the current page.

Clarify:

> dbt v2 still creates artifacts. The documentation browser changed from loading
> the full JSON manifest to querying a Parquet index.

## Step 4. Build the demo and metadata

```bash
dbt build --select dbt_v2_docs_order_events+ --write-index --generate-info-schema --static-analysis strict
```

Explain:

1. The seed and two models are built.
2. Twenty attached data tests run.
3. The Docs v2 index is written.
4. The dbt Information Schema is written as Parquet.
5. Strict analysis adds column types and column-level lineage.

Expected data:

```text
6 order events
6 prepared orders
3 daily summary rows
```

## Step 5. Query the Parquet metadata

```bash
dbt show --info models --limit 20
dbt show --info column_lineage --limit 100
```

Say:

> These commands read project metadata from the dbt Information Schema. They do
> not need to query Snowflake for these results.

## Step 6. Generate dbt Docs v2

```bash
dbt docs generate --no-compile --output-dir target/docs_site
```

Say:

> The strict build already created the metadata index. We use `--no-compile` to
> keep column lineage and `--output-dir` to create a self-contained directory for
> publishing.

```text
target/docs_site/
├── assets/
├── info_schema/v1/
└── index.html
```

Explain:

1. `info_schema/v1/` contains the Parquet metadata used by the browser.
2. `index.html` is the documentation site entry point.
3. The rest of `target/` can contain compiled SQL, JSON, and run outputs.
4. Publish only the self-contained `docs_site/` directory.
5. Internal folder names can change between dbt v2 releases.

## Step 7. Preview the site

```bash
dbt docs serve
```

Open `dbt_v2_docs_daily_summary` and show:

1. Model description
2. Column descriptions
3. Attached tests
4. Compiled SQL
5. Model lineage
6. Column lineage for `total_order_amount`

## Old and new comparison

| Area | Legacy dbt Docs | dbt Docs v2 |
| --- | --- | --- |
| Browser metadata | JSON | Parquet |
| Browser behavior | Loads JSON | Queries Parquet |
| Query engine | None for the metadata files | DuckDB WASM |
| Hosting | Static | Static |
| Main command | `dbt docs generate` | `dbt docs generate` |

## Five minute presentation order

1. Define documentation, metadata, artifact, Parquet, and DuckDB WASM.
2. Show the sample dbt flow.
3. Explain the legacy JSON architecture.
4. Explain the dbt Docs v2 Parquet architecture.
5. Run the strict build.
6. Query the Information Schema.
7. Generate and preview dbt Docs v2.
8. Close with what changed and what stayed the same.

## Troubleshooting

### `dbt docs generate --no-compile` fails

Run the strict build first so an index exists.

### Column lineage is missing

1. Include `--static-analysis strict` in the build.
2. Include `--write-index`.
3. Generate docs with `--no-compile`.
4. Review strict analysis messages.

### The Information Schema query returns no rows

1. Include `--generate-info-schema` in the build.
2. Confirm the build completed successfully.
3. Confirm `target/info_schema/v1/` exists.

### The docs site is not available

Run `dbt docs generate` before `dbt docs serve` and confirm the target directory
is writable.

## Final message

> The dbt authoring experience stays familiar. The main change is under the hood.
> Legacy dbt Docs loaded JSON metadata. dbt Docs v2 queries compact Parquet
> metadata with DuckDB WASM, which scales better for large projects.
