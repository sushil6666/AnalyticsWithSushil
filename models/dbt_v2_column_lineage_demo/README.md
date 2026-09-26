# dbt v2 Stable column-level lineage demo

## What this demo teaches

A dbt project contains models. A model is a SQL query that creates a table or
view.

Model lineage answers this question:

```text
Which model provides data to another model?
```

Column-level lineage answers a more detailed question:

```text
Which input columns were used to create this output column?
```

This demo uses simple order data to show both ideas.

## The data flow

```text
Order item CSV file
        |
        v
Enriched order items
        |
        v
Customer order summary
```

The dbt resource names are:

```text
dbt_v2_cll_order_items
        |
        v
dbt_v2_cll_enriched_order_items
        |
        v
dbt_v2_cll_customer_order_summary
```

## What each step does

### 1. Order item seed

A seed is a CSV file that dbt loads into the warehouse as a table.

The seed contains six order items. Important columns include:

```text
quantity
unit_price
order_timestamp
customer_id
```

### 2. Enriched order items model

This model makes a few easy changes:

```sql
order_item_id as line_item_id
quantity * unit_price as line_amount
cast(order_timestamp as date) as order_date
```

These expressions create three useful lineage examples:

1. `order_item_id` is renamed to `line_item_id`
2. `quantity` and `unit_price` create `line_amount`
3. `order_timestamp` creates `order_date`

Some columns, such as `customer_id`, keep the same name and value.

### 3. Customer order summary model

This model creates one row for each customer.

It adds each customer's line amounts together:

```sql
sum(line_amount) as gross_revenue
```

The full lineage for `gross_revenue` is:

```text
quantity and unit_price
          |
          v
      line_amount
          |
          v
     gross_revenue
```

## Files in this demo

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

## Step 1. Build the demo

Run:

```bash
dbt build --select dbt_v2_cll_order_items+ --write-index --generate-info-schema --static-analysis strict
```

What the command does:

1. `dbt build` loads the seed, builds the models, and runs the tests
2. `--select dbt_v2_cll_order_items+` selects the seed and everything after it
3. `--static-analysis strict` asks dbt to understand the SQL before it runs
4. `--generate-info-schema` writes project information to small Parquet files
5. `--write-index` writes the index used by dbt Docs v2

Expected results:

```text
6 seed rows
6 enriched order item rows
3 customer summary rows
26 passing data tests
0 failures
0 warnings
```

Expected customer revenue:

| Customer | Orders | Gross revenue |
| --- | ---: | ---: |
| C-001 | 2 | 142.50 |
| C-002 | 1 | 45.00 |
| C-003 | 1 | 147.50 |

## Step 2. Check the generated column lineage

Run:

```bash
dbt show --info column_lineage --limit 100
```

This command reads the column connections that dbt generated.

Look for these paths:

```text
dbt_v2_cll_order_items.order_item_id
    -> dbt_v2_cll_enriched_order_items.line_item_id

dbt_v2_cll_order_items.quantity
    -> dbt_v2_cll_enriched_order_items.line_amount
    -> dbt_v2_cll_customer_order_summary.gross_revenue

dbt_v2_cll_order_items.unit_price
    -> dbt_v2_cll_enriched_order_items.line_amount
    -> dbt_v2_cll_customer_order_summary.gross_revenue

dbt_v2_cll_order_items.order_timestamp
    -> dbt_v2_cll_enriched_order_items.order_date
    -> dbt_v2_cll_customer_order_summary.first_order_date
```

The output may use these values in the `evolution` column:

| Value | Simple meaning |
| --- | --- |
| `copy` | The value was copied or renamed |
| `mod` | The value was changed by a calculation or function |
| `scan` | The column helped group or scan rows for the result |

## Step 3. Generate dbt Docs v2

Run:

```bash
dbt docs generate --no-compile
```

The earlier build already created column lineage with strict analysis.
`--no-compile` tells dbt to use that existing information.

Preview the site:

```bash
dbt docs serve
```

In dbt Docs v2:

1. Open `dbt_v2_cll_customer_order_summary`
2. Select the Columns tab
3. Select `gross_revenue`
4. Follow it back to `line_amount`
5. Follow `line_amount` back to `quantity` and `unit_price`

You can also inspect:

1. `customer_id` for a column that keeps the same value
2. `line_item_id` for a renamed column
3. `first_order_date` for a date created from a timestamp

## One minute explanation

> We start with six order items in a CSV file. dbt loads the file as a seed.
> The next model calculates line_amount from quantity and unit_price. The final
> model adds line_amount to create gross_revenue for each customer. dbt v2 reads
> the SQL and records which columns created each result. We can see those
> connections in dbt Docs v2 or query them from the dbt Information Schema.

## Requirements

1. Use dbt v2 Stable
2. Sign in to dbt so it can connect to Snowflake
3. Run the strict build before generating dbt Docs v2
