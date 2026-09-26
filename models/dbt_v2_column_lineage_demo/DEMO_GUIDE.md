# dbt v2 Stable column-level lineage presenter guide

## Purpose

Use this guide to show a new dbt user where a final column comes from.


The main example is:

```text
quantity and unit_price
          |
          v
      line_amount
          |
          v
     gross_revenue
```

## Beginner terms

1. A seed is a CSV file that dbt loads into the warehouse.
2. A model is a SQL query that creates a table or view.
3. Model lineage shows which models are connected.
4. Column-level lineage shows which input columns created an output column.
5. Strict static analysis helps dbt understand the SQL expressions.
6. The dbt Information Schema stores project information in queryable tables.

## Demo flow

```text
dbt_v2_cll_order_items
        |
        v
dbt_v2_cll_enriched_order_items
        |
        v
dbt_v2_cll_customer_order_summary
```

The seed contains six order items. The first model creates useful order item
columns. The final model creates one summary row for each customer.

## Files to show

```text
models/dbt_v2_column_lineage_demo/
├── dbt_v2_cll_enriched_order_items.sql
├── dbt_v2_cll_customer_order_summary.sql
└── schema.yml

seeds/dbt_v2_column_lineage_demo/
├── dbt_v2_cll_order_items.csv
└── schema.yml
```

## Step 1. Explain the lineage patterns

Open `dbt_v2_cll_enriched_order_items.sql`.

### Same name and value

```sql
customer_id
```

### Renamed column

```sql
order_item_id as line_item_id
```

### Calculated column

```sql
quantity * unit_price as line_amount
```

### Changed data type

```sql
cast(order_timestamp as date) as order_date
```

Say:

> dbt v2 Stable reads these SQL expressions and records which input columns were
> used for each output column.

## Step 2. Show the final calculation

Open `dbt_v2_cll_customer_order_summary.sql` and show:

```sql
sum(line_amount) as gross_revenue
```

Say:

> The summary adds line_amount for each customer. dbt can trace gross_revenue
> back to line_amount, then back to quantity and unit_price.

## Step 3. Build the demo

Run:

```bash
dbt build --select dbt_v2_cll_order_items+ --write-index --generate-info-schema --static-analysis strict
```

The command does five things:

1. Loads the seed.
2. Builds both models.
3. Runs the attached tests.
4. Uses strict analysis to understand the SQL.
5. Writes the information used by dbt Docs v2.

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

## Step 4. Query the generated lineage

Run:

```bash
dbt show --info column_lineage --limit 100
```

Find these connections:

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

The output can include these `evolution` values:

| Value | Simple meaning |
| --- | --- |
| `copy` | The value was copied or renamed |
| `mod` | A calculation or function changed the value |
| `scan` | The column helped group or scan rows |

## Step 5. Generate dbt Docs v2

Run:

```bash
dbt docs generate --no-compile
```

The strict build already created the column connections. `--no-compile` keeps
and uses that information.

Preview the site:

```bash
dbt docs serve
```

## Step 6. Show the visual lineage

In dbt Docs v2:

1. Open `dbt_v2_cll_customer_order_summary`.
2. Select the Columns tab.
3. Select `gross_revenue`.
4. Follow it to `line_amount`.
5. Follow `line_amount` to `quantity` and `unit_price`.

Then show:

1. `customer_id` for a value that keeps the same name.
2. `line_item_id` for a renamed value.
3. `first_order_date` for a timestamp changed into a date.

## Model lineage and column-level lineage

| Question | Feature |
| --- | --- |
| Which model feeds this model? | Model lineage |
| Which columns created this column? | Column-level lineage |

```text
Model lineage
Order items -> Enriched items -> Customer summary

Column-level lineage
quantity -> line_amount -> gross_revenue
unit_price -> line_amount -> gross_revenue
```

## Why this demo matters

1. Root cause analysis can follow a wrong result back to its inputs.
2. Change impact shows which output columns may be affected by an edit.
3. New team members can understand a column without reading every model.
4. Reviewers can see which downstream values depend on a changed expression.

## Important limits

Column-level lineage is based on SQL that dbt can understand. It may be
incomplete for dynamic SQL, complex Jinja, some lateral joins, hardcoded table
names, Python models, or unsupported warehouse syntax.

A column used only in a filter or join may not appear as output column lineage.
Review strict analysis messages when a path is missing.

## Five minute presentation order

1. Define seed, model, and lineage.
2. Show the three-resource flow.
3. Show the rename, calculation, and date conversion.
4. Show `sum(line_amount) as gross_revenue`.
5. Run the strict build.
6. Query `column_lineage`.
7. Open `gross_revenue` in dbt Docs v2.
8. Close with model lineage versus column-level lineage.

## Troubleshooting

### The strict build fails

1. Confirm you are using dbt v2 Stable.
2. Confirm your dbt session is signed in.
3. Confirm the seed can be loaded.
4. Review the strict analysis message.

### The lineage query returns no rows

1. Run the strict build first.
2. Include `--generate-info-schema`.
3. Confirm the models use `ref()`.

### dbt Docs v2 does not show column lineage

1. Run the strict build before generating docs.
2. Use `dbt docs generate --no-compile`.
3. Review strict analysis messages for unresolved SQL.

### A path is incomplete

Check for dynamic SQL, complex Jinja, Python models, hardcoded relations, or a
column used only in a filter or join.

## Final message

> Model lineage shows which models are connected. Column-level lineage shows
> which exact input columns created a final output column. This helps teams
> understand data, review changes, and debug problems faster.
