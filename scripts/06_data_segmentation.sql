-- Step 6: Data Segmentation
-- 6.1: Segment Products into cost ranges
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

-- 6.2: Customer groups based on their spending behaviour
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
