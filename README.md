Retail Sales Batch ETL & Star Schema Warehouse
Project Overview
This project implements an end-to-end batch data engineering pipeline on Google Cloud using the Olist Brazilian E-Commerce dataset.

The pipeline ingests raw CSV files into Google Cloud Storage, loads them into BigQuery staging tables, transforms the data using SQL, builds an analytical Star Schema, and orchestrates the dimensional-model transformations using Google Cloud Workflows.

The project was built as a self-initiated data engineering portfolio project to demonstrate practical experience with:

Google Cloud Storage (GCS)
BigQuery
ANSI SQL
Dimensional Modeling
Star Schema
Data Profiling
Data Quality Validation
CTEs and Window Functions
Defensive Deduplication
NULL Handling
Google Cloud Workflows
Git and GitHub
Architecture
The data flows through the following layers:

Olist CSV Files
|
v
Google Cloud Storage
raw/YYYY-MM-DD/
|
v
BigQuery
raw_staging
|
v
SQL Transformations
|
v
analytics_gold
|
+---- dim_customer
+---- dim_product
+---- dim_date
+---- fact_sales
|
v
Analytical Queries
Star Schema
architecture/star_schema.png

The central fact table is fact_sales, which is connected to:

dim_customer
dim_product
dim_date
Fact table grain: One row per order line item.

Dataset
The project uses the Olist Brazilian E-Commerce dataset.

The following source files were used:

olist_customers_dataset.csv
olist_orders_dataset.csv
olist_order_items_dataset.csv
olist_products_dataset.csv
Raw CSV files are intentionally excluded from Git using .gitignore.

Source Data Profiling
Before loading the data into Google Cloud, the source CSV files were profiled locally using Python and pandas.

Dataset Rows Columns
Customers 99,441 5
Orders 99,441 8
Order Items 112,650 7
Products 32,951 9
The profiling process checked:

Column names
Data types
NULL values
Full-row duplicates
Business-key duplicates
Referential integrity
Business Key Validation
The following business keys were validated:

Customers: customer_id
Orders: order_id
Products: product_id
Order Items: (order_id, order_item_id)
No duplicate business keys were identified in the source data.

Referential-integrity checks also confirmed:

All orders had a matching customer
All order items had a matching order
All order items had a matching product
Google Cloud Storage Raw Layer
The source CSV files were uploaded to Google Cloud Storage using a date-based raw ingestion structure.

gs://retail-sales-de-srihitha13-raw/
└── raw/
└── 2026-11-20/
├── olist_customers_dataset.csv
├── olist_orders_dataset.csv
├── olist_order_items_dataset.csv
└── olist_products_dataset.csv
This preserves the original source files before transformation.

BigQuery Staging Layer
The raw files were loaded from Google Cloud Storage into the BigQuery raw_staging dataset.

raw_staging
├── olist_customers
├── olist_orders
├── olist_order_items
└── olist_products
Row counts were validated against the local source files after ingestion to ensure that records were not lost during the GCS-to-BigQuery load.

Data Transformations
SQL transformations were implemented using BigQuery Standard SQL.

The transformation logic includes:

Common Table Expressions (CTEs)
ROW_NUMBER() window functions
Defensive deduplication
SAFE_CAST
COALESCE
Surrogate-key generation
Dimensional modeling
Defensive Deduplication
Source profiling showed no duplicate business keys.

However, defensive deduplication was implemented using ROW_NUMBER() so that future source loads containing duplicate records can be handled consistently.

Example:

ROW_NUMBER() OVER (
PARTITION BY customer_id
ORDER BY customer_id
) AS row_num
Only row_num = 1 is retained.

NULL Handling
Data profiling identified several missing values.

For example, product_category_name contained 610 NULL values.

These were standardized using:

COALESCE(product_category_name, 'Unknown')
Missing product measurements such as weight, length, height, and width were preserved as NULL rather than converted to zero because an unknown measurement is not equivalent to a zero measurement.

Gold Star Schema
The final analytical model is stored in the BigQuery analytics_gold dataset.

dim_customer
Contains customer attributes including:

customer_key
customer_id
customer_unique_id
customer_zip_code_prefix
customer_city
customer_state
customer_key acts as the warehouse surrogate key.

dim_product
Contains product attributes including:

product_key
product_id
product_category_name
product_weight_g
product_length_cm
product_height_cm
product_width_cm
dim_date
The date dimension is derived from order_purchase_timestamp.

It contains:

date_key
full_date
day
month
month_name
quarter
year
day_of_week
The date_key follows the YYYYMMDD format.

fact_sales
The central fact table contains:

sales_key
order_id
order_item_id
customer_key
product_key
date_key
order_status
order_purchase_timestamp
quantity
item_price
freight_value
revenue
Fact Table Grain
The grain of fact_sales is:

One row per order line item

This grain was selected because one order can contain multiple products.

For this model:

quantity = 1
revenue = item_price
Freight is retained separately in freight_value.

Analytical Validation
The completed Star Schema was validated using analytical queries.

Use cases tested include:

Revenue by month
Revenue by product category
Revenue by customer state
Order counts
Item quantities
Example relationship:

fact_sales.date_key
|
v
dim_date.date_key
This allows revenue to be analyzed by year, quarter, month, and day.

Workflow Orchestration
Google Cloud Workflows is used to orchestrate the BigQuery transformation process.

The workflow executes the transformations sequentially:

START
|
v
build_dim_customer
|
v
build_dim_product
|
v
build_dim_date
|
v
build_fact_sales
|
v
FINISH
The workflow uses a dedicated service account with permissions required to submit BigQuery jobs and update the analytical tables.

A successful workflow execution rebuilds the complete Star Schema in dependency order.

Evidence
GCS Raw Layer
screenshots/gcs_raw_files.png

BigQuery Gold Tables
screenshots/bigquery_gold_tables.png

Analytical Validation
screenshots/bigquery_validation.png

Successful Workflow Execution
screenshots/workflow_execution_success.png

Repository Structure
retail-sales-gcp-data-pipeline/
│
├── architecture/
│ ├── star_schema.drawio
│ └── star_schema.png
│
├── data/
│ └── raw/
│
├── python/
│ └── profile_raw_data.py
│
├── sql/
│ ├── staging/
│ ├── transformations/
│ ├── gold/
│ │ ├── create_dim_customer.sql
│ │ ├── create_dim_product.sql
│ │ ├── create_dim_date.sql
│ │ └── create_fact_sales.sql
│ └── validation/
│ └── validate_star_schema.sql
│
├── workflows/
│ └── retail_sales_workflow.yaml
│
├── screenshots/
│ ├── gcs_raw_files.png
│ ├── bigquery_gold_tables.png
│ ├── bigquery_validation.png
│ └── workflow_execution_success.png
│
├── README.md
└── .gitignore
How to Reproduce
Obtain the Olist source CSV files.
Place the source files under data/raw/.
Run the Python profiling script:
python python/profile_raw_data.py
Upload the source CSV files to a date-partitioned GCS raw path.
Create the BigQuery raw_staging dataset.
Load the four CSV files into the staging tables.
Create the analytics_gold dataset.
Execute the SQL files under sql/gold/.
Run the validation queries under sql/validation/.
Deploy workflows/retail_sales_workflow.yaml to Google Cloud Workflows.
Execute the workflow and verify successful completion.
Key Learnings
This project demonstrates practical experience with:

Building a cloud-based batch data pipeline
Organizing raw data in Google Cloud Storage
Loading source data into BigQuery
Profiling source data before transformation
Validating business keys and referential integrity
Implementing SQL transformations using CTEs and window functions
Designing a dimensional Star Schema
Defining a fact-table grain
Generating surrogate keys
Handling missing values based on business meaning
Implementing defensive deduplication
Validating analytical relationships
Orchestrating BigQuery transformations using Google Cloud Workflows
Structuring a reproducible data-engineering project in GitHub
Project Status
Completed and tested.

The raw ingestion, staging layer, Star Schema transformations, analytical validation, and workflow orchestration were implemented and successfully executed.
