-- Step 4: Performmance Analysis
-- 4.1:  Yearly Performance of products by 
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

