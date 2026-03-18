# 🛒 Retail Data Analytics: SQL Case Study

## 📌 Introduction & Project Overview

In the rapidly evolving retail sector, businesses continually seek innovative strategies to stay ahead of the competition, improve customer satisfaction, and optimize operational efficiency. Leveraging data analytics has become a cornerstone for achieving these objectives.

This project focuses on a retail company that has observed stagnant growth and declining customer engagement metrics over the past quarters. Initial assessments indicate potential issues in product performance variability, ineffective customer segmentation, and a lack of insights into customer purchasing behavior.

Through a comprehensive data analysis approach using **MySQL**, this case study aims to identify high or low sales products, effectively segment the customer base, and analyze customer behavior to enhance marketing strategies, inventory decisions, and the overall customer experience.

---

## 📂 Dataset Description

The analysis utilizes three core tables:

| Table | Description |
|---|---|
| 📋 **Sales_Transaction** | Records of sales transactions, including transaction ID, customer ID, product ID, quantity purchased, transaction date, and price. |
| 👤 **Customer_Profiles** | Information on customers, including customer ID, age, gender, location, and join date. |
| 📦 **Product_Inventory** | Data on product inventory, including product ID, product name, category, stock level, and price. |

---

## 🛠️ Step-by-Step Methodology

The project was executed in the following phases:

1. **Data Cleaning & Quality Assurance**
   Utilized SQL queries to clean data and perform exploratory data analysis to ensure data quality. This included standardizing date formats, handling null values, and removing duplicates.

2. **Product Performance Analysis**
   Identified high and low sales products to optimize inventory and tailor marketing efforts. Evaluated performance based on total sales volume and overall revenue generation.

3. **Customer Segmentation**
   Segmented customers based on their purchasing behavior for targeted marketing campaigns. The segmentation logic categorized users by total quantity of products purchased:

   | Segment | Criteria |
   |---|---|
   | 🔴 No Orders | 0 purchases |
   | 🟡 Low Value | 1 – 10 purchases |
   | 🟠 Mid Value | 10 – 30 purchases |
   | 🟢 High Value | > 30 purchases |

4. **Customer Behavior Analysis**
   Analyzed patterns in customer behavior for insights on repeat purchases and loyalty.

---

## 💻 SQL Scripts Used

The following key SQL concepts were applied across various scripts in this repository:

- **CTEs & Window Functions:** Used Common Table Expressions and functions like `LAG()` to calculate Month-over-Month growth rates.
- **Data Manipulation (DML):** Applied `UPDATE` statements with subqueries to resolve pricing discrepancies between transaction and inventory tables.
- **Aggregations & Grouping:** Extensively used `SUM()`, `COUNT()`, `MIN()`, and `MAX()` alongside `GROUP BY` and `HAVING` clauses to profile occasional vs. high-frequency customers.
- **Joins:** Merged transaction, inventory, and customer profile tables to provide holistic category-level and demographic insights.

> 📁 Navigate to the `scripts/` folder to view the full `.sql` files for each problem statement.

---

## 📈 Key Findings

- **Product Variability:** Successfully isolated the **top 10 revenue-generating products** and the **bottom 10 slow-moving items**, providing clear directives for inventory management.
- **Targeted Segmentation:** Categorized the customer base into actionable tiers **(Low, Mid, High)**, enabling the marketing team to deploy highly targeted campaigns rather than generic blasts.
- **Loyalty Indicators:** Established clear metrics for customer retention by measuring the days between first and last purchases and tracking the frequency of repeat product purchases.

<p align="center">
  Built with ❤️ using <strong>MySQL</strong> — Turning raw retail data into actionable business intelligence.
</p>
