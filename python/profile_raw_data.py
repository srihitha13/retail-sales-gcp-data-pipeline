import pandas as pd
from pathlib import Path

data_folder = Path("data/raw")

files = [
    "olist_customers_dataset.csv",
    "olist_orders_dataset.csv",
    "olist_order_items_dataset.csv",
    "olist_products_dataset.csv",
]

for file in files:
    file_path = data_folder / file

    print("\n" + "=" * 70)
    print(f"FILE: {file}")
    print("=" * 70)

    df = pd.read_csv(file_path)

    print(f"\nRows: {df.shape[0]}")
    print(f"Columns: {df.shape[1]}")

    print("\nCOLUMN NAMES:")
    print(df.columns.tolist())

    print("\nDATA TYPES:")
    print(df.dtypes)

    print("\nNULL COUNTS:")
    print(df.isnull().sum())

    print("\nDUPLICATE ROWS:")
    print(df.duplicated().sum())

    print("\nFIRST 5 ROWS:")
    print(df.head())

    print("\n" + "=" * 70)
print("BUSINESS KEY AND RELATIONSHIP VALIDATION")
print("=" * 70)

customers = pd.read_csv(data_folder / "olist_customers_dataset.csv")
orders = pd.read_csv(data_folder / "olist_orders_dataset.csv")
order_items = pd.read_csv(data_folder / "olist_order_items_dataset.csv")
products = pd.read_csv(data_folder / "olist_products_dataset.csv")


# --------------------------------------------------
# 1. BUSINESS KEY DUPLICATES
# --------------------------------------------------

print("\n1. BUSINESS KEY DUPLICATES")

customer_duplicates = customers.duplicated(
    subset=["customer_id"]
).sum()

order_duplicates = orders.duplicated(
    subset=["order_id"]
).sum()

product_duplicates = products.duplicated(
    subset=["product_id"]
).sum()

order_item_duplicates = order_items.duplicated(
    subset=["order_id", "order_item_id"]
).sum()

print("Duplicate customer_id:", customer_duplicates)
print("Duplicate order_id:", order_duplicates)
print("Duplicate product_id:", product_duplicates)
print(
    "Duplicate order_id + order_item_id:",
    order_item_duplicates
)


# --------------------------------------------------
# 2. RELATIONSHIP / FOREIGN KEY CHECKS
# --------------------------------------------------

print("\n2. RELATIONSHIP VALIDATION")

invalid_customer_orders = orders[
    ~orders["customer_id"].isin(customers["customer_id"])
]

invalid_order_items = order_items[
    ~order_items["order_id"].isin(orders["order_id"])
]

invalid_product_items = order_items[
    ~order_items["product_id"].isin(products["product_id"])
]

print(
    "Orders with missing customer:",
    len(invalid_customer_orders)
)

print(
    "Order items with missing order:",
    len(invalid_order_items)
)

print(
    "Order items with missing product:",
    len(invalid_product_items)
)