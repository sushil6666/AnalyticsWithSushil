# dbt v2 Stable column-level lineage presenter guide

## Purpose

This guide helps you present the dbt v2 Stable column-level lineage demo to
someone who is new to dbt.

The demo answers one main question:

```text
Which input columns were used to create a final output column?
```

The main example is `gross_revenue`:

```text
quantity and unit_price
          |
          v
      line_amount
          |
          v
     gross_revenue
```

## The demo story

The demo uses a small order pipeline:

```text
Order item CSV file
        |
        v
Enriched order items
        |
        v
Customer order summary
```

The CSV file contains six order items. The first model cleans and calculates
order item columns. The final model creates one summary row for each customer.

The demo shows how dbt records the connection between input and output columns.

## Beginner terms

Explain these words before starting the demo.

### Seed

A seed is a CSV file that dbt loads into the warehouse as a table.

This demo uses:

```text
dbt_v2_cll_order_items.csv
```

### Model

A model is a SQL query that creates a table or view.

This demo has two models:

```text
dbt_v2_cll_enriched_order_items
dbt_v2_cll_customer_order_summary
```

### Model lineage

Model lineage shows which models provide data to other models.

For this demo:

```text
dbt_v2_cll_order_items
        |
        v
dbt_v2_cll_enriched_order_items
        |
        v
dbt_v2_cll_customer_order_summary
```

### Column-level lineage

Column-level lineage goes one step deeper. It shows which exact input columns
created an output column.

For example:

```text
quantity -> line_amount
unit_price -> line_amount
line_amount -> gross_revenue
```

### Static analysis

Static analysis means dbt reads and understands the SQL before the warehouse
runs it.

Strict static analysis allows dbt to record how selected columns and SQL
expressions connect to output columns.

### dbt Information Schema

The dbt Information Schema is a set of project information tables created by
dbt v2 Stable.

The `dbt.column_lineage` table contains the column connections found by dbt.

### Parquet

Parquet is a compact file format for table-shaped data.

dbt v2 Stable writes project information to Parquet files so tools can query it
efficiently.

## Demo resources

```text
models/dbt_v2_column_lineage_demo/
├── dbt_v2_cll_enriched_order_items.sql
├── dbt_v2_cll_customer_order_summary.sql
├── schema.yml
├── README.md
└── DEMO_GUIDE.md

seeds/dbt_v2_column_lineage_demo/
├── dbt_v2_cll_order_items.csv
└── schema.yml
```

The seed and both models use strict static analysis.

## What each resource does

### Order item seed

The seed contains six order items.

Important columns include:

```text
order_item_id
order_id
customer_id
product_name
quantity
unit_price
order_timestamp
```

The seed YAML declares the Snowflake data type for each column. This helps dbt
understand the schema during strict analysis.

### Enriched order items model

The enriched model creates one row for each order item.

It contains four useful lineage patterns.

#### Column with the same name and value

```sql
customer_id
```

The input and output both use `customer_id`.

#### Renamed column

```sql
order_item_id as line_item_id
```

The value stays the same, but the name changes.

#### Calculated column

```sql
quantity * unit_price as line_amount
```

Two input columns create one output column.

#### Data type change

```sql
cast(order_timestamp as date) as order_date
```

A timestamp column creates a date column.

The model also cleans the product name:

```sql
upper(trim(product_name)) as product_name_clean
```

### Customer order summary model

The summary model creates one row for each customer.

It includes calculations such as:

```sql
count(distinct order_id) as total_orders
sum(quantity) as total_units
sum(line_amount) as gross_revenue
min(order_date) as first_order_date
max(order_date) as last_order_date
```

These expressions show how column lineage continues through summary
calculations.

## Step 1. Show the model flow

Show this diagram:

```text
dbt_v2_cll_order_items
        |
        v
dbt_v2_cll_enriched_order_items
        |
        v
dbt_v2_cll_customer_order_summary
```

Say:

> The first resource contains sample order items. The second creates useful order
> item columns. The final resource creates one summary row for each customer.

Explain that this is model lineage. It shows the connection between resources,
but it does not yet show which exact columns are connected.

## Step 2. Show the first column connections

Open:

```text
dbt_v2_cll_enriched_order_items.sql
```

Point to:

```sql
order_item_id as line_item_id
quantity * unit_price as line_amount
cast(order_timestamp as date) as order_date
```

Say:

> These three lines show a rename, a calculation, and a data type change. dbt v2
> Stable reads these expressions and records the input columns for each result.

## Step 3. Show the final calculation

Open:

```text
dbt_v2_cll_customer_order_summary.sql
```

Point to:

```sql
sum(line_amount) as gross_revenue
```

Say:

> This adds the line amounts for each customer. The result is gross_revenue.

Show the complete path:

```text
quantity and unit_price
          |
          v
      line_amount
          |
          v
     gross_revenue
```

Explain that dbt can trace `gross_revenue` back through both models to the
original seed columns.

## Step 4. Build the demo and create lineage information

Run:

```bash
dbt build --select dbt_v2_cll_order_items+ --write-index --generate-info-schema --static-analysis strict
```

Explain each part:

1. `dbt build` loads the seed, builds both models, and runs their tests
2. `--select dbt_v2_cll_order_items+` selects the seed and everything after it
3. `--static-analysis strict` asks dbt to understand the SQL expressions
4. `--generate-info-schema` writes project information to Parquet files
5. `--write-index` writes the index used by dbt Docs v2

Expected result:

```text
1 seed built
2 models built
26 data tests passed
0 failures
0 warnings
```

Expected data:

| Customer | Orders | Gross revenue |
| --- | ---: | ---: |
| C-001 | 2 | 142.50 |
| C-002 | 1 | 45.00 |
| C-003 | 1 | 147.50 |

Say:

> The build proves that the seed, models, and tests work. Strict analysis also
> records how each output column was created.

## Step 5. Query the generated column lineage

Run:

```bash
dbt show --info column_lineage --limit 100
```

This reads the generated `dbt.column_lineage` information.

Find these rows:

```text
order_item_id -> line_item_id
customer_id -> customer_id
quantity -> line_amount
unit_price -> line_amount
line_amount -> gross_revenue
order_timestamp -> order_date
order_date -> first_order_date
product_name -> product_name_clean
```

Say:

> We did not write these connections by hand. dbt read the SQL and generated
> them.

## Understanding the evolution values

The output contains an `evolution` column.

| Value | Simple meaning | Example |
| --- | --- | --- |
| `copy` | The value was copied or renamed | `order_item_id` to `line_item_id` |
| `mod` | A calculation or function changed the value | `quantity` to `line_amount` |
| `scan` | The column helped group or scan rows | `customer_id` in a grouped summary |

The exact value describes how dbt saw the column being used in the SQL.

## Step 6. Generate dbt Docs v2

Run:

```bash
dbt docs generate --no-compile
```

Explain why `--no-compile` is used:

> The strict build already created the column connections. This command keeps
> and uses that existing information.

Preview the site:

```bash
dbt docs serve
```

## Step 7. Show lineage in dbt Docs v2

In dbt Docs v2:

1. Open `dbt_v2_cll_customer_order_summary`
2. Select the Columns tab
3. Select `gross_revenue`
4. Follow it to `line_amount`
5. Follow `line_amount` to `quantity` and `unit_price`

Then show three more examples.

### Same value

Open `customer_id`.

Explain that the value keeps the same name as it moves through the models.

### Renamed value

Open `line_item_id`.

Explain that it comes from `order_item_id`.

### Changed data type

Open `first_order_date`.

Explain that it comes from `order_date`, which comes from `order_timestamp`.

## Model lineage and column-level lineage

Use this comparison:

| Question | Feature |
| --- | --- |
| Which model feeds this model? | Model lineage |
| Which columns created this column? | Column-level lineage |

Simple example:

```text
Model lineage
Order items -> Enriched items -> Customer summary

Column-level lineage
quantity -> line_amount -> gross_revenue
unit_price -> line_amount -> gross_revenue
```

## Why this demo is useful

### Root cause analysis

If `gross_revenue` is wrong, column-level lineage shows that the investigation
should include `line_amount`, `quantity`, and `unit_price`.

### Change impact

Before changing `unit_price`, a developer can see that the change may affect
`line_amount` and `gross_revenue`.

### Documentation

A new team member can understand where a column comes from without reading every
model first.

### Safer code review

A reviewer can see which downstream columns may change when an input expression
changes.

### Faster debugging

The lineage gives a clear path to follow instead of searching the whole project.

## What column-level lineage does not show

Column-level lineage reflects column connections from model `select`
statements.

It does not mean that every SQL use appears as an output lineage edge. For
example, a column used only in a filter or join may not appear as output column
lineage.

Lineage can also be incomplete when dbt cannot fully understand the SQL.
Examples include:

1. Some complex Jinja-generated SQL
2. Some complex lateral joins
3. Dynamic SQL
4. Hardcoded table names instead of `ref()`
5. Python models
6. Warehouse syntax that static analysis cannot resolve

When dbt cannot determine a connection, review the strict analysis messages.

## Column descriptions

A column that is copied or renamed can inherit its description from an upstream
column when the lineage is known.

This helps teams document a column once and reuse that meaning downstream.

A changed column should still have a clear description that explains the new
calculation or meaning.

## One minute presentation

> This demo starts with six order items in a CSV seed. The enriched model creates
> line_amount from quantity and unit_price. The summary model adds line_amount to
> create gross_revenue for each customer. dbt v2 Stable reads the SQL with strict
> static analysis and records the column connections. We can query those
> connections from the dbt Information Schema or view them in dbt Docs v2. Model
> lineage shows which models are connected. Column-level lineage shows which
> exact input columns created a final output column.

## Suggested presentation order

1. Explain seed, model, and lineage
2. Show the three-resource model flow
3. Show the rename, calculation, and date conversion
4. Show `sum(line_amount) as gross_revenue`
5. Run the strict build
6. Query `column_lineage`
7. Explain `copy`, `mod`, and `scan`
8. Generate dbt Docs v2
9. Follow `gross_revenue` to its original columns
10. Close with model lineage versus column-level lineage

## Troubleshooting

### The strict build fails

1. Confirm you are using dbt v2 Stable
2. Confirm your dbt session is signed in
3. Confirm Snowflake credentials are valid
4. Confirm the seed can be created
5. Review the strict analysis error message

### `dbt show --info column_lineage` returns no rows

1. Run the strict build first
2. Include `--generate-info-schema`
3. Confirm the build completed successfully
4. Confirm the models use `ref()` for dependencies

### dbt Docs v2 does not show column lineage

1. Run the strict build before generating docs
2. Use `dbt docs generate --no-compile`
3. Confirm the strict build wrote the Information Schema
4. Review strict analysis messages for unresolved SQL

### A column path is incomplete

1. Confirm the SQL uses `ref()`
2. Check whether the column is only used in a filter or join
3. Check for dynamic SQL or complex Jinja
4. Review strict analysis messages
5. Remember that Python model lineage may be incomplete

### The expected values are different

1. Confirm the seed still contains six rows
2. Confirm `line_amount` is `quantity * unit_price`
3. Confirm `gross_revenue` is `sum(line_amount)`
4. Rebuild the full selected graph

## Final message

Use this closing statement:

> Model lineage shows which models are connected. Column-level lineage goes one
> step deeper. It shows which exact input columns created a final output column.
> This helps teams understand data, review changes, and debug problems faster.
