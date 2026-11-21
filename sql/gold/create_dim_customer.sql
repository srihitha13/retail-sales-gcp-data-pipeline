CREATE OR REPLACE TABLE `retail-sales-de-srihitha.analytics_gold.dim_customer` AS

WITH deduplicated_customers AS (

    SELECT
        customer_id,
        customer_unique_id,
        customer_zip_code_prefix,
        customer_city,
        customer_state,

        ROW_NUMBER() OVER (
            PARTITION BY customer_id
            ORDER BY customer_id
        ) AS row_num

    FROM `retail-sales-de-srihitha.raw_staging.olist_customers`
)

SELECT
    ROW_NUMBER() OVER (
        ORDER BY customer_id
    ) AS customer_key,

    customer_id,
    customer_unique_id,
    customer_zip_code_prefix,
    customer_city,
    customer_state

FROM deduplicated_customers

WHERE row_num = 1;