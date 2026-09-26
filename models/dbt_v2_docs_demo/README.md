# dbt Docs v2 generation demo

## What this demo teaches

This demo explains how dbt generated documentation before dbt v2 Stable and how
dbt Docs v2 works now.

The command still looks familiar:

```bash
dbt docs generate
```

The main change is what happens under the hood.

## Beginner terms

### Documentation

dbt documentation combines model descriptions, column descriptions, tests,
compiled SQL, warehouse columns, and lineage in a searchable website.

### Metadata

Metadata is information about the project, such as model names, descriptions,
columns, tests, and dependencies.

### Artifact

An artifact is a file produced by dbt. It records project or execution
information for another tool to use.

### Parquet

Parquet is a compact column-based file format. It is efficient for analytical
queries.

### DuckDB WASM

DuckDB is a small analytical database. WASM allows it to run inside a browser.
dbt Docs v2 uses DuckDB WASM to query Parquet metadata in the browser.

## The sample dbt flow

```text
dbt_v2_docs_order_events
          |
          v
dbt_v2_docs_orders
          |
          v
dbt_v2_docs_daily_summary
```

The seed contains six sample orders. The first model adds an order date. The
second model creates a daily summary.

## How legacy dbt Docs worked

The legacy flow used large JSON files:

```text
SQL models and YAML descriptions
              |
              v
         dbt docs generate
              |
              v
   manifest.json + catalog.json
              |
              v
      Browser loads the JSON
              |
              v
      Documentation website
```

`manifest.json` contained project structure, descriptions, configurations,
compiled SQL, tests, and dependencies.

`catalog.json` contained warehouse metadata such as relation columns and data
types.

This worked well, but a large project could create large JSON files that the
browser had to load and process.

## How dbt Docs v2 works

The dbt Docs v2 flow uses a Parquet index:

```text
SQL models and YAML descriptions
              |
              v
    dbt v2 compile or build
              |
              v
       Parquet metadata index
              |
              v
 DuckDB WASM queries it in browser
              |
              v
      Documentation website
```

The browser can query the metadata it needs instead of loading the full
`manifest.json` for the documentation interface.

## Important clarification

dbt v2 Stable still produces artifacts. It can still produce JSON artifacts for
compatibility and other workflows.

The important change is:

```text
Legacy docs browser: loads large JSON metadata
Docs v2 browser: queries Parquet metadata with DuckDB WASM
```

The dbt Information Schema is also stored as Parquet. It is a related queryable
interface to project metadata, but it is not the same directory as the static
Docs v2 index.

## Demo files

```text
models/dbt_v2_docs_demo/
├── dbt_v2_docs_orders.sql
├── dbt_v2_docs_daily_summary.sql
├── schema.yml
├── README.md
└── DEMO_GUIDE.md

seeds/dbt_v2_docs_demo/
├── dbt_v2_docs_order_events.csv
└── schema.yml
```

## Step 1. Build the demo and metadata

Run:

```bash
dbt build --select dbt_v2_docs_order_events+ --write-index --generate-info-schema --static-analysis strict
```

What the flags do:

1. `--select dbt_v2_docs_order_events+` builds the seed and everything after it.
2. `--write-index` writes the index used by dbt Docs v2.
3. `--generate-info-schema` writes queryable project metadata as Parquet.
4. `--static-analysis strict` adds column types and column-level lineage.

Expected data:

```text
6 order events
6 prepared orders
3 daily summary rows
```

Expected daily values:

| Order date | Total orders | Completed orders | Total amount |
| --- | ---: | ---: | ---: |
| 2026-02-01 | 2 | 1 | 200.00 |
| 2026-02-02 | 2 | 2 | 255.00 |
| 2026-02-03 | 2 | 1 | 65.00 |

## Step 2. Query the dbt Information Schema

Run:

```bash
dbt show --info models --limit 20
```

This reads project model metadata from Parquet without querying Snowflake.

You can also inspect column lineage:

```bash
dbt show --info column_lineage --limit 100
```

The Information Schema files are written under:

```text
target/info_schema/v1/
```

## Step 3. Generate dbt Docs v2

Run:

```bash
dbt docs generate --no-compile --output-dir target/docs_site
```

The strict build already created the metadata index. `--no-compile` keeps and
uses that existing index, including column-level lineage. `--output-dir` creates
a self-contained site that is safer to publish than the full `target/`
directory.

The validated dbt v2.0.6 site contains:

```text
target/docs_site/
├── assets/
├── info_schema/v1/
└── index.html
```

The Parquet metadata used by the browser is under `info_schema/v1/`. The
remaining `target/` directory can contain compiled SQL, JSON artifacts, and run
outputs, so publish only the self-contained `docs_site/` directory. Internal
folder names can change between dbt v2 releases.

## Step 4. Preview the site

Run:

```bash
dbt docs serve
```

In the documentation site:

1. Open `dbt_v2_docs_daily_summary`.
2. Read the model and column descriptions.
3. Review the attached data tests.
4. Open model lineage.
5. Inspect column lineage for `total_order_amount`.

## Old and new comparison

| Area | Legacy dbt Docs | dbt Docs v2 |
| --- | --- | --- |
| Browser metadata | Large JSON files | Parquet index |
| Browser query engine | JavaScript reads JSON | DuckDB WASM queries Parquet |
| Large projects | More browser memory | More compact and queryable metadata |
| Hosting | Static site | Static site |
| Main command | `dbt docs generate` | `dbt docs generate` |
| Column-level lineage | Not part of the legacy experience | Available with strict static analysis |

## What stays the same

1. Models are still written in SQL.
2. Descriptions and tests are still written in YAML.
3. `ref()` still creates dependencies.
4. `dbt docs generate` still creates a static site.
5. The generated site can still be hosted on a static file host.

## Requirements and limits

1. Use dbt v2 Stable.
2. Sign in to dbt so the project can connect to Snowflake.
3. Run strict static analysis before docs generation when column lineage is
   required.
4. Some complex SQL and Python models may have incomplete column lineage.
5. `dbt docs serve` is intended for local preview, not production hosting.

## Official references

- [dbt Docs commands](https://docs.getdbt.com/reference/commands/cmd-docs)
- [View documentation](https://docs.getdbt.com/docs/build/view-documentation)
- [dbt Information Schema](https://docs.getdbt.com/docs/build/dbt-information-schema)
