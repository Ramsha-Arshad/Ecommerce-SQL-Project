-- Step 1.1: Download and Import CSVs 
-- Use Schema: portfolioproject02
USE portfolioproject02;

-- Step 1.2: Check all tables
SHOW TABLES IN portfolioproject02;

-- Rename table gold.fact_sales to sales
RENAME TABLE `gold.fact_sales` TO sales;

-- Check rename 
SELECT * FROM sales;

-- Step 1.3: EDA (Exploratory Data Analysis)
-- (a): View sample data from each table
SELECT * FROM customers LIMIT 10;
SELECT * FROM products LIMIT 10;
SELECT * FROM sales LIMIT 10;

-- (b): Check Row counts in each table
SELECT COUNT(*) FROM customers;
SELECT COUNT(*) FROM products;
SELECT COUNT(*) FROM sales;

-- (c): Check Column Structure(column data types)
DESCRIBE customers;
DESCRIBE products;
DESCRIBE sales;

-- (d): Convert data types of date column(sales table)
-- Safe Update Mode Fix

SET SQL_SAFE_UPDATES = 0;

ALTER TABLE sales 
ADD COLUMN order_date_clean DATE,
ADD COLUMN shipping_date_clean DATE,
ADD COLUMN due_date_clean DATE;

UPDATE sales
SET order_date_clean = STR_TO_DATE(order_date, '%Y-%m-%d'),
    shipping_date_clean = STR_TO_DATE(shipping_date, '%Y-%m-%d'),
    due_date_clean = STR_TO_DATE(due_date, '%Y-%m-%d')
WHERE order_date IS NOT NULL AND order_date != '';

-- Re-enable Safe Update Mode
SET SQL_SAFE_UPDATES = 1;

-- (e): Check Column Structure After Update
DESCRIBE customers;
DESCRIBE products;
DESCRIBE sales;

