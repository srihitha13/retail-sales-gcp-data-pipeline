CREATE OR REPLACE TABLE
  `retail-sales-de-srihitha.analytics_gold.fact_sales` AS

WITH deduplicated_orders AS (

    SELECT
        order_id,
        customer_id,
        order_status,
        SAFE_CAST(order_purchase_timestamp AS TIMESTAMP)
            AS order_purchase_timestamp,

        ROW_NUMBER() OVER (
            PARTITION BY order_id
            ORDER BY SAFE_CAST(
                order_purchase_timestamp AS TIMESTAMP
            ) DESC
        ) AS row_num

    FROM
        `retail-sales-de-srihitha.raw_staging.olist_orders`
),

clean_orders AS (

    SELECT
        order_id,
        customer_id,
        order_status,
        order_purchase_timestamp

    FROM deduplicated_orders
    WHERE row_num = 1
      AND order_purchase_timestamp IS NOT NULL
),

deduplicated_order_items AS (

    SELECT
        order_id,
        order_item_id,
        product_id,
        SAFE_CAST(price AS NUMERIC) AS item_price,
        SAFE_CAST(freight_value AS NUMERIC) AS freight_value,

        ROW_NUMBER() OVER (
            PARTITION BY order_id, order_item_id
            ORDER BY product_id
        ) AS row_num

    FROM
        `retail-sales-de-srihitha.raw_staging.olist_order_items`
),

clean_order_items AS (

    SELECT
        order_id,
        order_item_id,
        product_id,
        item_price,
        freight_value

    FROM deduplicated_order_items
    WHERE row_num = 1
)

SELECT
    ROW_NUMBER() OVER (
        ORDER BY
            order_items.order_id,
            order_items.order_item_id
    ) AS sales_key,

    order_items.order_id,
    order_items.order_item_id,

    customers.customer_key,
    products.product_key,
    dates.date_key,

    orders.order_status,
    orders.order_purchase_timestamp,

    1 AS quantity,

    order_items.item_price,
    order_items.freight_value,

    order_items.item_price AS revenue

FROM clean_order_items AS order_items

INNER JOIN clean_orders AS orders
    ON order_items.order_id = orders.order_id

INNER JOIN
    `retail-sales-de-srihitha.analytics_gold.dim_customer`
    AS customers
    ON orders.customer_id = customers.customer_id

INNER JOIN
    `retail-sales-de-srihitha.analytics_gold.dim_product`
    AS products
    ON order_items.product_id = products.product_id

INNER JOIN
    `retail-sales-de-srihitha.analytics_gold.dim_date`
    AS dates
    ON DATE(orders.order_purchase_timestamp) = dates.full_date;