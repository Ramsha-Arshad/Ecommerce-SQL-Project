-- Step 2: Changes Over Time Analysis
-- 2.1: Sales Performance Over Time (using updated date columns)
-- (a): Year-wise breakdown of sales performance
SELECT 
YEAR(order_date_clean) AS order_year,
SUM(sales_amount) AS total_sales,
COUNT(DISTINCT customer_key) AS total_customers,
SUM(quantity) AS total_quantity
FROM sales
WHERE order_date_clean IS NOT NULL
GROUP BY YEAR(order_date_clean)
ORDER BY YEAR(order_date_clean)
;

-- (b): Month-wise breakdown (across all years)
SELECT 
MONTH(order_date_clean) AS order_month,
SUM(sales_amount) AS total_sales,
COUNT(DISTINCT customer_key) AS total_customers,
SUM(quantity) AS total_quantity
FROM sales
WHERE order_date_clean IS NOT NULL
GROUP BY MONTH(order_date_clean)
ORDER BY MONTH(order_date_clean)
;

-- (c): Year–Month granularity
SELECT 
DATE_FORMAT(order_date_clean, '%Y-%m') AS order_date,
SUM(sales_amount) AS total_sales,
COUNT(DISTINCT customer_key) AS total_customers,
SUM(quantity) AS total_quantity
FROM sales
WHERE order_date_clean IS NOT NULL
GROUP BY DATE_FORMAT(order_date_clean, '%Y-%m')
ORDER BY DATE_FORMAT(order_date_clean, '%Y-%m')
;

