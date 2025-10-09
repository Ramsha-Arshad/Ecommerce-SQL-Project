-- STEP 5: Part-To-Whole Analysis
-- 5.1: Most contributing categories to the overall sales
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

