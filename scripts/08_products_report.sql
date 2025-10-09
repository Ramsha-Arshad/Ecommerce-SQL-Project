-- Step 8: Product Report
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
  