-- Step 3: Cummulative Analysis
-- 3.1: Total Sales per Month and Running Total of Sales over time
-- (a) Month wise granuality
SELECT
order_date,
total_sales,
SUM(total_sales) OVER (PARTITION BY order_date ORDER BY order_date) AS running_total_sales
FROM
(
	SELECT 
	  DATE_FORMAT(order_date_clean, '%Y-%m-01') AS order_date,
	  SUM(sales_amount) AS total_sales
	FROM sales
	WHERE order_date_clean IS NOT NULL
	GROUP BY DATE_FORMAT(order_date_clean, '%Y-%m-01')
) t;

-- (b) Year-wise granuality
SELECT
order_date,
total_sales,
SUM(total_sales) OVER (ORDER BY order_date) AS running_total_sales
FROM
(
	SELECT 
	  DATE_FORMAT(order_date_clean, '%Y-01-01') AS order_date,
	  SUM(sales_amount) AS total_sales
	FROM sales
	WHERE order_date_clean IS NOT NULL
	GROUP BY DATE_FORMAT(order_date_clean, '%Y-01-01')
) t;

-- 3.2: Moving Average Price
SELECT
order_date,
total_sales,
ROUND
(AVG(avg_price) OVER (ORDER BY order_date)) AS moving_average_price
FROM
(
	SELECT 
	  DATE_FORMAT(order_date_clean, '%Y-01-01') AS order_date,
	  SUM(sales_amount) AS total_sales,
      AVG(price) AS avg_price
	FROM sales
	WHERE order_date_clean IS NOT NULL
	GROUP BY DATE_FORMAT(order_date_clean, '%Y-01-01')
) t;

