CREATE OR REPLACE TABLE `retail-sales-de-srihitha.analytics_gold.dim_product` AS

WITH deduplicated_products AS (

    SELECT
        product_id,

        COALESCE(
            product_category_name,
            'Unknown'
        ) AS product_category_name,

        product_weight_g,
        product_length_cm,
        product_height_cm,
        product_width_cm,

        ROW_NUMBER() OVER (
            PARTITION BY product_id
            ORDER BY product_id
        ) AS row_num

    FROM `retail-sales-de-srihitha.raw_staging.olist_products`
)

SELECT
    ROW_NUMBER() OVER (
        ORDER BY product_id
    ) AS product_key,

    product_id,
    product_category_name,
    product_weight_g,
    product_length_cm,
    product_height_cm,
    product_width_cm

FROM deduplicated_products
WHERE row_num = 1;