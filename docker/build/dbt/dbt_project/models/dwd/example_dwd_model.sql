{{ config(
    materialized='table',
    engine='OLAP',
    keys=['transaction_id'],
    distributed_by=['transaction_id'],
    buckets=4
) }}

WITH raw_data AS (
    SELECT *
    FROM {{ source('paimon_ods', 'ewallet_transaction_details') }}
)

SELECT
    transaction_id,
    user_id,
    amount,
    currency,
    status,
    transaction_time AS ods_ingested_at,
    CURRENT_TIMESTAMP() AS dwd_updated_at
FROM raw_data
WHERE status = 'SUCCESS'
