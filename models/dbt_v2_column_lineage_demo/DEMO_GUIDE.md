# dbt v2 Stable column-level lineage presenter guide

## Goal

Show a new dbt user how one final column can be traced back to the columns that
created it.

The main example is `gross_revenue`.

```text
quantity and unit_price
          |
          v
      line_amount
          |
          v
     gross_revenue
```

## Before the demo

Explain these three words:

1. A seed is a CSV file that dbt loads into the warehouse
2. A model is a SQL query that creates a table or view
3. Lineage shows where data comes from and where it goes

## Step 1. Show the three resources

Show this flow:

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

> The first resource contains sample order items. The second resource adds new
> columns. The final resource creates one summary row for each customer.

## Step 2. Show the calculation

Open `dbt_v2_cll_enriched_order_items.sql`.

Point to:

```sql
quantity * unit_price as line_amount
```

Say:

> This creates line_amount. Each line amount comes from quantity and unit_price.

Also show:

```sql
order_item_id as line_item_id
cast(order_timestamp as date) as order_date
```

Explain:

1. The first line renames a column
2. The second line changes a timestamp into a date

## Step 3. Show the customer summary

Open `dbt_v2_cll_customer_order_summary.sql`.

Point to:

```sql
sum(line_amount) as gross_revenue
```

Say:

> This adds all line amounts for one customer. The result is gross_revenue.

## Step 4. Build the demo

Run:

```bash
dbt build --select dbt_v2_cll_order_items+ --write-index --generate-info-schema --static-analysis strict
```

Explain the command in simple terms:

1. Build the seed and both models
2. Run all attached tests
3. Read the SQL in strict mode
4. Record the column connections
5. Write the information used by dbt Docs v2

Expected result:

```text
1 seed built
2 models built
26 data tests passed
0 failures
0 warnings
```

Say:

> The build proves that the data and tests work. Strict analysis also records
> how each output column was created.

## Step 5. Show the recorded connections

Run:

```bash
dbt show --info column_lineage --limit 100
```

Find these rows:

```text
order_item_id -> line_item_id
quantity -> line_amount
unit_price -> line_amount
line_amount -> gross_revenue
order_timestamp -> order_date
order_date -> first_order_date
```

Say:

> We did not type these connections by hand. dbt read the SQL and created them.

If the output shows `copy`, `mod`, or `scan`, explain:

1. `copy` means the value was copied or renamed
2. `mod` means a calculation or function changed the value
3. `scan` means the column helped group or scan the rows

## Step 6. Show dbt Docs v2

Run:

```bash
dbt docs generate --no-compile
dbt docs serve
```

Explain why `--no-compile` is used:

> The strict build already created the column connections. This command keeps
> and uses that existing information.

In dbt Docs v2:

1. Open `dbt_v2_cll_customer_order_summary`
2. Select Columns
3. Select `gross_revenue`
4. Follow it to `line_amount`
5. Follow `line_amount` to `quantity` and `unit_price`

Then inspect:

1. `customer_id` to show a column that keeps the same value
2. `line_item_id` to show a renamed column
3. `first_order_date` to show a timestamp changed into a date

## Final message

Say:

> Model lineage shows which models are connected. Column-level lineage goes one
> step deeper. It shows which exact input columns created a final output column.

## Troubleshooting

1. Confirm you are using dbt v2 Stable
2. Confirm your dbt session is signed in
3. Run the strict build before `dbt docs generate --no-compile`
4. Check strict analysis messages if a connection is missing
5. Some complex SQL and Python models may not provide complete column lineage
