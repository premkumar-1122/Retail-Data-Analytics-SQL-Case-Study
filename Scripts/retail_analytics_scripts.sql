
CREATE DATABASE case_study;

USE case_study;

# Rename unclean columns

SELECT *
FROM customer_profiles;

ALTER TABLE customer_profiles
RENAME COLUMN `ï»¿CustomerID` TO CustomerID;

SELECT *
FROM product_inventory;

ALTER TABLE product_inventory
RENAME COLUMN `ï»¿ProductID` TO ProductID;

SELECT *
FROM sales_transaction;

ALTER TABLE sales_transaction
RENAME COLUMN `ï»¿TransactionID` TO TransactionID;

##### Data Cleaning

# 1. Remove duplicate transactions

SELECT TransactionID, count(*)
FROM sales_transaction
GROUP BY TransactionID
HAVING COUNT(*) > 1;

CREATE TABLE sales_transaction_nodupe AS
SELECT DISTINCT *
FROM sales_transaction;

SELECT *
FROM sales_transaction_nodupe;

DROP TABLE sales_transaction;

ALTER TABLE sales_transaction_nodupe
RENAME TO sales_transaction;

SELECT *
FROM sales_transaction;

SELECT TransactionID, COUNT(*)
FROM sales_transaction
GROUP BY TransactionID
HAVING COUNT(*) > 1;

# 2. Identify and Fix Incorrect Prices in Sales Transaction

SELECT *
FROM Sales_Transaction;

SELECT pi.ProductID, st.TransactionID, st.Price AS TransactionPrice, pi.Price AS InventoryPrice
FROM Sales_Transaction st
JOIN Product_Inventory pi
ON st.ProductID = pi.ProductID
WHERE st.price <> pi.price;

UPDATE Sales_Transaction st
SET Price = ( SELECT pi.Price FROM Product_Inventory pi
WHERE st.ProductID = pi.ProductID )
WHERE st.ProductID IN
(SELECT ProductID FROM Product_Inventory
WHERE st.Price <> Product_Inventory.Price
);

SELECT *
FROM Sales_Transaction;

# 3. Identify null values in dataset and replace accordingly

SELECT COUNT(*)
FROM customer_profiles
WHERE JoinDate IS NULL;

SELECT *
FROM customer_profiles;

SELECT COUNT(*)
FROM customer_profiles
WHERE Location = "";

SELECT *
FROM product_inventory;

SELECT *
FROM sales_transaction;

SELECT COUNT(*)
FROM sales_transaction
WHERE (TransactionID IS NULL) OR (TransactionID = "");

UPDATE customer_profiles
SET Location = "Unknown"
WHERE Location = "";

SELECT *
FROM customer_profiles;

CREATE TABLE sales_transaction_updated AS
SELECT *, STR_TO_DATE(TransactionDate, "%d/%m/%Y") AS transactiondate_updated1
FROM Sales_Transaction;

DROP TABLE sales_transaction;

ALTER TABLE sales_transaction_updated RENAME TO sales_transaction;

SELECT *
FROM Sales_Transaction;

## EDA

SELECT ProductID, SUM(QuantityPurchased) AS TotalUnitsSold, SUM(Price * QuantityPurchased) AS TotalSales
FROM Sales_Transaction
GROUP BY ProductID
ORDER BY TotalSales DESC;

SELECT CustomerID, COUNT(*) AS NumberofTransactions
FROM Sales_Transaction
GROUP BY CustomerID
ORDER BY NumberofTransactions DESC;

SELECT pi.Category, SUM(st.QuantityPurchased) AS TotalQuantities, SUM(st.Price * st.QuantityPurchased) AS TotalSales
FROM Sales_Transaction st
JOIN Product_Inventory pi
ON st.ProductID = pi.ProductID
GROUP BY pi.Category
ORDER BY TotalSales DESC;

SELECT ProductID, SUM(QuantityPurchased * Price) AS TotalSales
FROM Sales_Transaction
GROUP BY ProductID
ORDER BY TotalSales DESC
LIMIT 10;

SELECT ProductID, SUM(QuantityPurchased) AS TotalUnitsSold
FROM Sales_Transaction
GROUP BY ProductID
HAVING TotalUnitsSold > 0
ORDER BY TotalUnitsSold ASC
LIMIT 10;

SELECT transactiondate_updated1, COUNT(*) AS Transaction_Count,
SUM(QuantityPurchased) AS TotalUnitsSold, SUM(Price * QuantityPurchased) AS TotalSales
FROM Sales_Transaction
GROUP BY transactiondate_updated1
ORDER BY transactiondate_updated1 DESC;

SELECT CustomerID, COUNT(*) AS NumberofTransactions,
SUM(QuantityPurchased * Price) AS TotalSales
FROM Sales_Transaction
GROUP BY CustomerID
HAVING NumberofTransactions > 10 AND TotalSales > 1000
ORDER BY TotalSales DESC;

SELECT CustomerID, COUNT(*) AS NumberofTransactions,
SUM(QuantityPurchased * Price) AS TotalSales
FROM Sales_Transaction
GROUP BY CustomerID
HAVING NumberofTransactions <= 2
ORDER BY NumberofTransactions ASC, TotalSales DESC;

SELECT CustomerID, ProductID, COUNT(*) AS TimesPurchased
FROM Sales_Transaction
GROUP BY CustomerID, ProductID
HAVING TimesPurchased > 1
ORDER BY TimesPurchased DESC, CustomerID;

SELECT *
FROM Sales_Transaction;

WITH transactionDate AS(
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

WITH monthly_sales AS(
SELECT EXTRACT(MONTH FROM transactiondate_updated1) AS Month_Extracted,
SUM(QuantityPurchased * Price) AS TotalSales
FROM Sales_Transaction
GROUP BY EXTRACT(MONTH FROM transactiondate_updated1)
)
SELECT Month_Extracted, TotalSales,
LAG(TotalSales) OVER(ORDER BY Month_Extracted) AS previous_month_sales,
((TotalSales - LAG(TotalSales) OVER (ORDER BY Month_Extracted)) /
LAG(TotalSales) OVER(ORDER BY Month_Extracted))*100 AS mom_growth_rate
FROM monthly_sales
ORDER BY Month_Extracted;

CREATE TABLE customer_segment AS
SELECT CustomerID,
CASE WHEN TotalQuantity > 30 THEN 'High'
WHEN TotalQuantity BETWEEN 10 AND 30 THEN 'Med'
WHEN TotalQuantity BETWEEN 1 AND 10 THEN 'Low'
ELSE 'None'
END customer_segment1
FROM
(
SELECT a.CustomerID, SUM(b.QuantityPurchased) AS TotalQuantity
FROM customer_profiles a
JOIN sales_transaction b
ON a.CustomerID = b.CustomerID
GROUP BY a.CustomerID
) customer_segment2;

SELECT customer_segment1, COUNT(*)
FROM customer_segment
GROUP BY customer_segment1;
