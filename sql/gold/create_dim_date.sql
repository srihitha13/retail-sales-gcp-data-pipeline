CREATE OR REPLACE TABLE `retail-sales-de-srihitha.analytics_gold.dim_date` AS

WITH order_dates AS (

    SELECT DISTINCT
        DATE(SAFE_CAST(order_purchase_timestamp AS TIMESTAMP)) AS full_date

    FROM `retail-sales-de-srihitha.raw_staging.olist_orders`

    WHERE order_purchase_timestamp IS NOT NULL
)

SELECT
    CAST(FORMAT_DATE('%Y%m%d', full_date) AS INT64) AS date_key,
    full_date,
    EXTRACT(DAY FROM full_date) AS day,
    EXTRACT(MONTH FROM full_date) AS month,
    FORMAT_DATE('%B', full_date) AS month_name,
    EXTRACT(QUARTER FROM full_date) AS quarter,
    EXTRACT(YEAR FROM full_date) AS year,
    FORMAT_DATE('%A', full_date) AS day_of_week

FROM order_dates

WHERE full_date IS NOT NULL
ORDER BY full_date;