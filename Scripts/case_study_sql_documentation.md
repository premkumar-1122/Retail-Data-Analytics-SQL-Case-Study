# Retail Sales Case Study — SQL Documentation

This document explains the SQL script used to clean, transform, and analyze the `case_study` database, which contains three tables:

- **customer_profiles** — customer details (ID, join date, location)
- **product_inventory** — product catalog (ID, category, price)
- **sales_transaction** — individual sales records (transaction ID, customer, product, quantity, price, date)

---

## 1. Database Setup

```sql
CREATE DATABASE case_study;
USE case_study;
```

Creates the working database and selects it for all subsequent operations.

---

## 2. Fixing Corrupted Column Names

When the CSVs were imported, a byte-order-mark (BOM) character (`ï»¿`) got prepended to the first column name in each table. These statements rename the affected ID columns back to clean names.

```sql
ALTER TABLE customer_profiles
RENAME COLUMN `ï»¿CustomerID` TO CustomerID;

ALTER TABLE product_inventory
RENAME COLUMN `ï»¿ProductID` TO ProductID;

ALTER TABLE sales_transaction
RENAME COLUMN `ï»¿TransactionID` TO TransactionID;
```

---

## 3. Data Cleaning

### 3.1 Remove Duplicate Transactions

**Check for duplicates** — finds any `TransactionID` that appears more than once:

```sql
SELECT TransactionID, COUNT(*)
FROM sales_transaction
GROUP BY TransactionID
HAVING COUNT(*) > 1;
```

**Deduplicate** — creates a clean copy of the table keeping only distinct rows, then swaps it in to replace the original:

```sql
CREATE TABLE sales_transaction_nodupe AS
SELECT DISTINCT *
FROM sales_transaction;

DROP TABLE sales_transaction;

ALTER TABLE sales_transaction_nodupe
RENAME TO sales_transaction;
```

**Verify** the fix worked by re-running the duplicate check (should return 0 rows).

---

### 3.2 Fix Incorrect Prices in Sales Transactions

Some transactions were recorded with a price that doesn't match the current price in `product_inventory`. This treats `product_inventory.Price` as the source of truth.

**Identify mismatches:**

```sql
SELECT pi.ProductID, st.TransactionID, st.Price AS TransactionPrice, pi.Price AS InventoryPrice
FROM Sales_Transaction st
JOIN Product_Inventory pi
    ON st.ProductID = pi.ProductID
WHERE st.price <> pi.price;
```

**Correct them** — overwrites the transaction price with the correct inventory price wherever they differ:

```sql
UPDATE Sales_Transaction st
SET Price = (
    SELECT pi.Price
    FROM Product_Inventory pi
    WHERE st.ProductID = pi.ProductID
)
WHERE st.ProductID IN (
    SELECT ProductID
    FROM Product_Inventory
    WHERE st.Price <> Product_Inventory.Price
);
```

---

### 3.3 Identify and Handle Null / Missing Values

**Check for missing join dates in `customer_profiles`:**

```sql
SELECT COUNT(*)
FROM customer_profiles
WHERE JoinDate IS NULL;
```

**Check for blank locations:**

```sql
SELECT COUNT(*)
FROM customer_profiles
WHERE Location = "";
```

**Check for missing transaction IDs:**

```sql
SELECT COUNT(*)
FROM sales_transaction
WHERE (TransactionID IS NULL) OR (TransactionID = "");
```

**Fill blank locations** with a placeholder value:

```sql
UPDATE customer_profiles
SET Location = "Unknown"
WHERE Location = "";
```

---

### 3.4 Standardize Transaction Date Format

The raw `TransactionDate` column is stored as text in `DD/MM/YYYY` format. This converts it into a proper SQL `DATE` type in a new column, then replaces the original table with the corrected version.

```sql
CREATE TABLE sales_transaction_updated AS
SELECT *, STR_TO_DATE(TransactionDate, "%d/%m/%Y") AS transactiondate_updated1
FROM Sales_Transaction;

DROP TABLE sales_transaction;

ALTER TABLE sales_transaction_updated RENAME TO sales_transaction;
```

> After this step, use `transactiondate_updated1` for any date-based analysis.

---

## 4. Exploratory Data Analysis (EDA)

### 4.1 Top-Selling Products (by units and revenue)

```sql
SELECT ProductID,
       SUM(QuantityPurchased) AS TotalUnitsSold,
       SUM(Price * QuantityPurchased) AS TotalSales
FROM Sales_Transaction
GROUP BY ProductID
ORDER BY TotalSales DESC;
```

### 4.2 Most Active Customers (by transaction count)

```sql
SELECT CustomerID, COUNT(*) AS NumberofTransactions
FROM Sales_Transaction
GROUP BY CustomerID
ORDER BY NumberofTransactions DESC;
```

### 4.3 Top-Selling Categories

Joins transactions to inventory to roll sales up by product category.

```sql
SELECT pi.Category,
       SUM(st.QuantityPurchased) AS TotalQuantities,
       SUM(st.Price * st.QuantityPurchased) AS TotalSales
FROM Sales_Transaction st
JOIN Product_Inventory pi
    ON st.ProductID = pi.ProductID
GROUP BY pi.Category
ORDER BY TotalSales DESC;
```

### 4.4 Top 10 Performing Products (by revenue)

```sql
SELECT ProductID, SUM(QuantityPurchased * Price) AS TotalSales
FROM Sales_Transaction
GROUP BY ProductID
ORDER BY TotalSales DESC
LIMIT 10;
```

### 4.5 Bottom 10 Underperforming Products (by units sold)

```sql
SELECT ProductID, SUM(QuantityPurchased) AS TotalUnitsSold
FROM Sales_Transaction
GROUP BY ProductID
HAVING TotalUnitsSold > 0
ORDER BY TotalUnitsSold ASC
LIMIT 10;
```

### 4.6 Daily Sales Summary

Transaction count, units sold, and revenue per day, most recent first.

```sql
SELECT transactiondate_updated1,
       COUNT(*) AS Transaction_Count,
       SUM(QuantityPurchased) AS TotalUnitsSold,
       SUM(Price * QuantityPurchased) AS TotalSales
FROM Sales_Transaction
GROUP BY transactiondate_updated1
ORDER BY transactiondate_updated1 DESC;
```

### 4.7 High-Value Repeat Customers

Customers with more than 10 transactions **and** over $1,000 in total spend.

```sql
SELECT CustomerID,
       COUNT(*) AS NumberofTransactions,
       SUM(QuantityPurchased * Price) AS TotalSales
FROM Sales_Transaction
GROUP BY CustomerID
HAVING NumberofTransactions > 10 AND TotalSales > 1000
ORDER BY TotalSales DESC;
```

### 4.8 One-Time / Low-Engagement Customers

Customers with two or fewer transactions.

```sql
SELECT CustomerID,
       COUNT(*) AS NumberofTransactions,
       SUM(QuantityPurchased * Price) AS TotalSales
FROM Sales_Transaction
GROUP BY CustomerID
HAVING NumberofTransactions <= 2
ORDER BY NumberofTransactions ASC, TotalSales DESC;
```

### 4.9 Repeat Purchases of the Same Product

Identifies customer–product pairs purchased more than once — useful for spotting loyal product preferences.

```sql
SELECT CustomerID, ProductID, COUNT(*) AS TimesPurchased
FROM Sales_Transaction
GROUP BY CustomerID, ProductID
HAVING TimesPurchased > 1
ORDER BY TimesPurchased DESC, CustomerID;
```

### 4.10 Customer Purchase Lifespan

Uses a CTE to find each customer's first and last purchase date, and the number of days between them (i.e., how long they've been active).

```sql
WITH transactionDate AS (
    SELECT CustomerID, transactiondate_updated1
    FROM Sales_Transaction
)
SELECT CustomerID,
       MIN(transactiondate_updated1) AS FirstPurchase,
       MAX(transactiondate_updated1) AS LastPurchase,
       (MAX(transactiondate_updated1) - MIN(transactiondate_updated1)) AS DaysBetweenPurchase
FROM transactionDate
GROUP BY CustomerID
HAVING (MAX(transactiondate_updated1) - MIN(transactiondate_updated1)) > 0
ORDER BY DaysBetweenPurchase DESC;
```

### 4.11 Month-over-Month (MoM) Sales Growth

Uses a CTE plus the `LAG()` window function to compare each month's total sales against the previous month and calculate a percentage growth rate.

```sql
WITH monthly_sales AS (
    SELECT EXTRACT(MONTH FROM transactiondate_updated1) AS Month_Extracted,
           SUM(QuantityPurchased * Price) AS TotalSales
    FROM Sales_Transaction
    GROUP BY EXTRACT(MONTH FROM transactiondate_updated1)
)
SELECT Month_Extracted,
       TotalSales,
       LAG(TotalSales) OVER (ORDER BY Month_Extracted) AS previous_month_sales,
       ((TotalSales - LAG(TotalSales) OVER (ORDER BY Month_Extracted))
            / LAG(TotalSales) OVER (ORDER BY Month_Extracted)) * 100 AS mom_growth_rate
FROM monthly_sales
ORDER BY Month_Extracted;
```

### 4.12 Customer Segmentation by Purchase Volume

Builds a permanent `customer_segment` table classifying each customer into **High**, **Med**, **Low**, or **None** based on total quantity purchased across all transactions.

| Segment | Total Quantity Purchased |
|---------|---------------------------|
| High    | > 30                      |
| Med     | 10 – 30                   |
| Low     | 1 – 10                    |
| None    | 0 / no purchases          |

```sql
CREATE TABLE customer_segment AS
SELECT CustomerID,
    CASE
        WHEN TotalQuantity > 30 THEN 'High'
        WHEN TotalQuantity BETWEEN 10 AND 30 THEN 'Med'
        WHEN TotalQuantity BETWEEN 1 AND 10 THEN 'Low'
        ELSE 'None'
    END AS customer_segment1
FROM (
    SELECT a.CustomerID, SUM(b.QuantityPurchased) AS TotalQuantity
    FROM customer_profiles a
    JOIN sales_transaction b
        ON a.CustomerID = b.CustomerID
    GROUP BY a.CustomerID
) customer_segment2;
```

**Segment counts:**

```sql
SELECT customer_segment1, COUNT(*)
FROM customer_segment
GROUP BY customer_segment1;
```

---

## Summary of Workflow

1. **Setup** — create database, fix corrupted column names.
2. **Clean** — remove duplicate transactions, correct mismatched prices, handle nulls/blanks, standardize date formats.
3. **Analyze** — explore top/bottom products and categories, customer activity patterns, sales trends over time, and customer segmentation.
