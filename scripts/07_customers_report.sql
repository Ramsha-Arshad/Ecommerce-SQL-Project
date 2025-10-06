-- Step 1: Download and Import CSVs 
-- Use Schema: portfolioproject02
USE portfolioproject02;

-- Step 2: Check all tables
SHOW TABLES IN portfolioproject02;

-- Rename table gold.fact_sales to sales
RENAME TABLE `gold.fact_sales` TO sales;

-- Check rename 
SELECT * FROM sales;

-- Step 3: EDA (Exploratory Data Analysis)
-- 3.1: View sample data from each table
SELECT * FROM customers LIMIT 10;
SELECT * FROM products LIMIT 10;
SELECT * FROM sales LIMIT 10;

-- 3.2: Check Row counts in each table
SELECT COUNT(*) FROM customers;
SELECT COUNT(*) FROM products;
SELECT COUNT(*) FROM sales;

-- 3.3: Check Column Structure(column data types)
DESCRIBE customers;
DESCRIBE products;
DESCRIBE sales;

-- 3.4: Convert data types of date column(sales table)
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

-- 3.5: Check Column Structure After Update
DESCRIBE customers;
DESCRIBE products;
DESCRIBE sales;

-- Step 4: Changes Over Time Analysis
-- 4.1: Sales Performance Over Time (using updated date columns)
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

-- Step 5: Cummulative Analysis
-- 5.1: Total Sales per Month and Running Total of Sales over time
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

-- 5.2: Moving Average Price
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

-- Step 6: Performmance Analysis
-- 6.1:  Yearly Performance of products by 
-- comparing each products's sales to both
-- its average sales performance and the previous year's sales
WITH yearly_product_sales AS
(
SELECT 
YEAR(s.order_date_clean) AS order_year,
p.product_name,
SUM(s.sales_amount) AS current_sales
FROM sales s
LEFT JOIN products p
ON s.product_key=p.product_key
WHERE s.order_date_clean IS NOT NULL
GROUP BY YEAR(s.order_date_clean),p.product_name
)
SELECT 
order_year,
product_name,
current_sales,
ROUND(AVG(current_sales) OVER(PARTITION BY product_name))  AS avg_sales,
ROUND(current_sales-AVG(current_sales) OVER(PARTITION BY product_name)) AS diff_avg,
CASE WHEN current_sales>ROUND(AVG(current_sales) OVER(PARTITION BY product_name)) THEN 'Above Avg'
	 WHEN current_sales<ROUND(AVG(current_sales) OVER(PARTITION BY product_name)) THEN 'Below Avg'	
     ELSE 'Avg'
END AS avg_change,
-- Year-Over-Year Analysis
LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_year) AS prev_yr_sales,
current_sales-LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_year) AS diff_prevyr,
CASE WHEN current_sales>LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_year) THEN 'Increase'
	 WHEN current_sales<LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_year) THEN 'Decrease'	
     ELSE 'No change'
END AS prevyr_change
FROM yearly_product_sales
ORDER BY product_name, order_year
;

/*6.1: Top 10 Selling Products by Sales Amount
6.2: Top 10 Customers by Total Purchase
6.3: Best Performing Product Categories (if category info is available in the products table)
6.4: Customer Segment Performance (if applicable)
6.5: Product-wise Profitability (if cost data is available)*/

-- STEP 7: Part-To-Whole Analysis
-- 7.1: Most contributing categories to the overall sales
WITH category_sales
AS
(
SELECT 
category,
SUM(sales_amount) AS total_sales
FROM sales s
LEFT JOIN Products p
ON s.product_key=p.product_key
GROUP BY category
)
SELECT 
category,
total_sales,
SUM(total_sales) OVER() AS overall_sales,
CONCAT(ROUND(total_sales/SUM(total_sales) OVER()*100,2), '%') AS percentage_of_total
FROM category_sales
ORDER BY 4 DESC
;

-- Step 8: Data Segmentation
-- 8.1: Segment Products into cost ranges
-- and how many products fall into each segment

WITH prod_segments 
AS
(
	SELECT 
	product_name,
	cost,
	CASE WHEN cost<100 THEN 'Below 100'
		 WHEN cost BETWEEN 100 AND 500 THEN '100-500'
		 WHEN cost BETWEEN 500 AND 1000 THEN '500-1000'
         ELSE 'Above 1000'
		 END AS cost_range
	FROM products
)
SELECT
cost_range,
COUNT(cost_range) AS total_products 
FROM prod_segments 
GROUP BY cost_range
ORDER BY 2 DESC
;

-- 8.2: Customer groups based on their spending behaviour
-- VIP: at least 12 months of history and spending more than 5000
-- Regular: at least 12 months of history but spending 5000 or less
-- New: lifespan less than 12 months
-- total number of customers by each group

WITH customer_spending
AS
(
	SELECT 
	c.customer_key,
	SUM(s.sales_amount) AS total_spending,
	MIN(s.order_date_clean) AS first_order,
	MAX(s.order_date_clean) AS last_order,
	TIMESTAMPDIFF(MONTH, MIN(s.order_date_clean), MAX(s.order_date_clean)) AS lifespan
	FROM sales s 
	LEFT JOIN customers c
	ON s.customer_key=c.customer_key
    WHERE s.order_date_clean IS NOT NULL
	GROUP BY c.customer_key
)

, spending_behaviour
AS
(
	SELECT 
	lifespan,
    total_spending,
    customer_key,
   	CASE WHEN lifespan >= 12 AND total_spending > 5000 THEN 'VIP'
		 WHEN lifespan >= 12 AND total_spending <= 5000 THEN 'Regular'
		 WHEN lifespan < 12 THEN 'New'
	END AS customer_segment
	FROM customer_spending
    
) 
SELECT 
customer_segment,
COUNT(customer_key) AS total_customers
FROM spending_behaviour
GROUP BY customer_segment
ORDER BY total_customers DESC
;

-- Step 9: Customer Report
/*
=============================================================================
Customer Report
=============================================================================
Purpose:
	- This report consolidates key customer metrics and behaviour
    
Highlights:
	1. Gathers essential fields such as names, ages, and transaction details.
    2. Segments customers into categories (VIP, Regular, New) and age groups.
    3. Aggregates customer-level metrics:
		- total orders
        - total sales
        - total quantity purchased
        - total products
        - lifespan (in months)
	4. Calculates valuable KPIs:
		- recency(months since last order)
        - average order value
        - average monthly spend
==============================================================================
*/
CREATE VIEW customers_report AS
WITH base_query
AS
/*----------------------------------------------------------------------------
1) Base QUery: Retrieves core columns from tables
----------------------------------------------------------------------------*/ 
(
	SELECT
		s.order_number,
		s.product_key,
		s.order_date_clean AS order_date,
		s.sales_amount,
		s.quantity,
		c.customer_key,
		c.customer_number,
		CONCAT(c.first_name, ' ' ,c.last_name) AS customer_name,
		c.birthdate,
		timestampdiff(year, c.birthdate, NOW()) AS age
	FROM sales s
	LEFT JOIN customers c
	ON c.customer_key=s.customer_key
	WHERE order_date_clean IS NOT NULL
)

, customer_aggregation 
AS
/*----------------------------------------------------------------------------
2) Customer Aggregation: Summarizes key metrics at the customer level
----------------------------------------------------------------------------*/ 
(
	SELECT 
		customer_key,
		customer_number,
		customer_name,
		age,
		COUNT(DISTINCT order_number) AS total_orders,
		SUM(sales_amount) AS total_sales,
		SUM(quantity) AS total_quantity,
		COUNT(DISTINCT product_key) AS total_products,
		MAX(order_date) AS last_order_date,
		TIMESTAMPDIFF(MONTH, MIN(order_date), MAX(order_date)) AS lifespan
	FROM base_query
	GROUP BY 
		customer_key,
		customer_number,
		customer_name,
		age
)
/*----------------------------------------------------------------------------
3) Final Query: Combines all customer results into one output 
----------------------------------------------------------------------------*/
SELECT 
	customer_key,
	customer_number,
	customer_name,
	age,
    CASE 
		 WHEN age < 20 THEN 'Under 20'
		 WHEN age BETWEEN 20 AND 29 THEN '20-29'
         WHEN age BETWEEN 30 AND 39 THEN '30-39'
         WHEN age BETWEEN 40 AND 49 THEN '40-49'
	ELSE '50 and above'
    END AS age_group,
    CASE 
		WHEN lifespan >= 12 AND total_sales > 5000 THEN 'VIP'
		 WHEN lifespan >= 12 AND total_sales <= 5000 THEN 'Regular'
	ELSE 'New'
	END AS customer_segment,
    TIMESTAMPDIFF(month, last_order_date, NOW()) as recency,
	total_orders,
	total_sales,
	total_quantity,
	total_products,
	last_order_date, 
	lifespan,
    -- Compute avergae order value (AOV)
    CASE WHEN total_sales = 0 THEN 0
		 ELSE ROUND(total_sales / total_orders) 
	END AS average_order_value,
	-- Compute average monthly spend
    CASE WHEN lifespan = 0 THEN total_sales
		 ELSE ROUND(total_sales / lifespan)
    END AS avg_monthly_spend
 FROM customer_aggregation
 ;
 
 SELECT * FROM customers_report;
 
 -- Step 10: Product Report
/*
=============================================================================
Product Report
=============================================================================
Purpose:
	- This report consolidates key product metrics and behaviour
    
Highlights:
	1. Gathers essential fields such as product name, category, sub-category, and cost.
    2. Segments products by revenue to identify High-Performers, Mid-Range, or Low-Performers 
    3. Aggregates product-level metrics:
		- total orders
        - total sales
        - total quantity sold
        - total customers (unique)
        - lifespan (in months)
	4. Calculates valuable KPIs:
		- recency(months since last sales)
        - average order revenue (AOR)
        - average monthly revenue
==============================================================================
*/
CREATE VIEW products_report AS
WITH base_query
AS
/*----------------------------------------------------------------------------
1) Base QUery: Retrieves core columns from sales and product tables
----------------------------------------------------------------------------*/ 
(
	SELECT
		s.order_number,
		s.order_date_clean AS order_date,
        s.customer_key,
		s.sales_amount,
		s.quantity,
        p.product_key,
		p.product_name,
		p.category,
        p.subcategory,
        p.cost
	FROM sales s
	LEFT JOIN products p
	ON s.product_key = p.product_key
	WHERE order_date_clean IS NOT NULL
)

, product_aggregation 
AS
/*----------------------------------------------------------------------------
2) Product Aggregation: Summarizes key metrics at the product level
----------------------------------------------------------------------------*/ 
(
	SELECT 
		product_key,
		product_name,
		category,
        subcategory,
        cost,
        TIMESTAMPDIFF(MONTH, MIN(order_date), MAX(order_date)) AS lifespan,
		MAX(order_date) AS last_sale_date,
        COUNT(DISTINCT order_number) AS total_orders,
        COUNT(DISTINCT customer_key) AS total_customers,
		SUM(sales_amount) AS total_sales,
		SUM(quantity) AS total_quantity,
		ROUND(AVG(CAST(sales_amount AS FLOAT) / NULLIF(quantity,0)),1) AS avg_selling_price
	FROM base_query
	GROUP BY 
		product_key,
		product_name,
		category,
        subcategory,
        cost
) 
/*----------------------------------------------------------------------------
3) Final Query: Combines all product results into one output 
----------------------------------------------------------------------------*/ 
SELECT 
	product_key,
	product_name,
	category,
	subcategory,
	cost,
    last_sale_date,
	TIMESTAMPDIFF(month, last_sale_date, NOW()) as recency_in_months,
    CASE 
		 WHEN total_sales > 50000 THEN 'High-Performer'
		 WHEN total_sales >= 10000 THEN 'Mid-Range'
		 ELSE 'Low Performer'
    END AS product_segment,
    lifespan,
	total_orders,
	total_sales,
	total_quantity,
	total_customers,
	avg_selling_price, 
    -- Compute avergae order revenue (AOR)
    CASE WHEN total_orders = 0 THEN 0
		 ELSE ROUND(total_sales / total_orders) 
	END AS average_order_revenue,
	-- Compute average monthly revenue
    CASE WHEN lifespan = 0 THEN total_sales
		 ELSE ROUND(total_sales / lifespan)
    END AS avg_monthly_revenue
FROM product_aggregation
;
  