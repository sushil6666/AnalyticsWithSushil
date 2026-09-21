{{ config(
    materialized='table',
    schema='dbt_v2_static_analysis_demo',
    static_analysis='strict',
    tags=['dbt_v2_static_analysis_demo']
) }}

select
    cast(event_timestamp as date) as event_date,
    count(*) as total_events,
    count_if(payment_status = 'approved') as approved_events,
    count_if(payment_status = 'declined') as declined_events,
    count_if(payment_status = 'refunded') as refunded_events,
    sum(payment_amount) as total_payment_amount
from {{ ref('dbt_v2_static_analysis_typed_payments') }}
group by 1
