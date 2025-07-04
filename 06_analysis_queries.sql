--------------------------------
-- Exploratory Data Analysis
--------------------------------

-- Get unique repair statuses from the warranty table
SELECT DISTINCT repair_status 
FROM warranty;

-- Get unique store names from the stores table
SELECT DISTINCT store_name 
FROM stores;

-- Get unique category names from the category table
SELECT DISTINCT category_name 
FROM category;

-- Get unique product names from the products table
SELECT DISTINCT product_name 
FROM products;

-- Count the total number of sales
SELECT COUNT(*) AS total_sales 
FROM sales;


-- Planning Time: 0.087 ms
-- Execution Time: 206.932 ms
SELECT * 
FROM sales 
WHERE product_id = 310;


CREATE INDEX sales_product_id ON sales(product_id);

-- Planning Time: 1.417 ms
-- Execution Time: 8.865 ms
SET STATISTICS IO ON;
SET STATISTICS TIME ON;

SELECT * 
FROM sales 
WHERE product_id = 201;

SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;


-- Planning Time: 0.096 ms
-- Execution Time: 156.822 ms

SELECT * 
FROM sales 
WHERE store_id = 10;

CREATE INDEX sales_store_id ON sales(store_id)

-- Planning Time: 1.452 ms
-- Execution Time: 9.076 ms
    SELECT * 
FROM sales 
WHERE store_id = 31;


-- Planning Time: 0.129 ms
-- Execution Time: 133.589 ms
SELECT * 
FROM sales 
WHERE sale_date = '2020-04-18';

CREATE INDEX sales_sale_date ON sales(sale_date)

-- Planning Time: 1.422 ms
-- Execution Time: 0.997 ms
EXPLAIN ANALYZE
SELECT * 
FROM sales 
WHERE sale_date = '2020-04-18';


-- Planning Time: 0.105 ms
-- Execution Time: 260.194 ms
SELECT * 
FROM sales  
WHERE quantity > 2;

CREATE INDEX sales_quantity ON sales(quantity);

-- Planning Time: 0.128 ms
-- Execution Time: 161.133 ms
SET STATISTICS IO ON;
SET STATISTICS TIME ON;

SELECT * 
FROM sales 
WHERE quantity > 2;

SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;

--------------------------------
-- sql basic queries
---------------------------------


-- 1. Find the number of stores in each country
SELECT 
    country, 
    COUNT(store_id) AS total_stores
FROM stores
GROUP BY country
ORDER BY total_stores DESC;


-- 2. Calculate the total number of units sold by each store
SELECT 
    store_id, 
    SUM(quantity) AS total_units_sold
FROM sales
GROUP BY store_id
ORDER BY total_units_sold DESC;


-- 3. Identify how many sales occurred in December 2023
SELECT 
    COUNT(*) AS total_sales
FROM sales
WHERE FORMAT(sale_date, 'yyyy-MM') = '2023-12';


-- 4. Determine how many stores have never had a warranty claim filed
SELECT 
    COUNT(*) AS stores_without_warranty_claims
FROM stores
WHERE store_id NOT IN (
    SELECT DISTINCT s.store_id
    FROM sales s
    JOIN warranty w ON s.sale_id = w.sale_id
);


-- 5. Calculate the percentage of warranty claims marked as 'Warranty Void'
SELECT 
    ROUND(
        CAST(COUNT(*) AS FLOAT) * 100 / 
        NULLIF((SELECT COUNT(*) FROM warranty), 0), 2
    ) AS warranty_void_percentage
FROM warranty
WHERE repair_status = 'Warranty Void';


-- 6. Identify which store had the highest total units sold in the last year
SELECT TOP 1 
    store_id, 
    SUM(quantity) AS total_units
FROM sales
WHERE sale_date >= DATEADD(YEAR, -1, GETDATE())
GROUP BY store_id
ORDER BY total_units DESC;


-- 7. Count the number of unique products sold in the last year
SELECT 
    COUNT(DISTINCT product_id) AS unique_products_sold
FROM sales
WHERE sale_date >= DATEADD(YEAR, -1, GETDATE());


-- 8. Find the average price of products in each category
SELECT 
    c.category_id,
    c.category_name,
    ROUND(AVG(p.price), 2) AS avg_price
FROM category c
JOIN products p ON p.category_id = c.category_id
GROUP BY c.category_id, c.category_name
ORDER BY avg_price DESC;


-- 9. How many warranty claims were filed in 2024?
SELECT 
    COUNT(*) AS claims_in_2024
FROM warranty
WHERE YEAR(claim_date) = 2024;


-- 10. For each store, identify the best-selling day of the week (by quantity sold)
WITH RankedDays AS (
    SELECT 
        store_id,
        DATENAME(WEEKDAY, sale_date) AS day_name,
        SUM(quantity) AS total_quantity,
        RANK() OVER (
            PARTITION BY store_id 
            ORDER BY SUM(quantity) DESC
        ) AS rnk
    FROM sales
    GROUP BY store_id, DATENAME(WEEKDAY, sale_date)
)
SELECT 
    store_id, 
    day_name, 
    total_quantity
FROM RankedDays
WHERE rnk = 1;

--11. Show total revenue per country
SELECT 
    st.country,
    SUM(p.price * s.quantity) AS total_revenue
FROM sales s
JOIN products p ON s.product_id = p.product_id
JOIN stores st ON s.store_id = st.store_id
GROUP BY st.country
ORDER BY total_revenue DESC;

--12. Find top 3 products sold by quantity
SELECT TOP 3 
    p.product_name,
    SUM(s.quantity) AS total_sold
FROM sales s
JOIN products p ON s.product_id = p.product_id
GROUP BY p.product_name
ORDER BY total_sold DESC;

--13. Identify cities with no sales at all
SELECT 
    store_name, 
    city 
FROM stores
WHERE store_id NOT IN (
    SELECT DISTINCT store_id FROM sales
);

--14. Category-wise revenue in the last 2 years
SELECT 
    c.category_name,
    SUM(p.price * s.quantity) AS total_category_revenue
FROM sales s
JOIN products p ON s.product_id = p.product_id
JOIN category c ON p.category_id = c.category_id
WHERE s.sale_date >= DATEADD(YEAR, -2, GETDATE())
GROUP BY c.category_name
ORDER BY total_category_revenue DESC;

--15. 15. Monthly claim count trend for this year
SELECT 
    FORMAT(claim_date, 'yyyy-MM') AS claim_month,
    COUNT(*) AS claims_count
FROM warranty
WHERE YEAR(claim_date) = YEAR(GETDATE())
GROUP BY FORMAT(claim_date, 'yyyy-MM')
ORDER BY claim_month;

--16. Identify the store with the highest average sale value
SELECT TOP 1 
    s.store_id, 
    AVG(p.price * s.quantity) AS avg_sale_value
FROM sales s
JOIN products p ON s.product_id = p.product_id
GROUP BY s.store_id
ORDER BY avg_sale_value DESC;

--17. Find the top 5 products with the highest warranty claims
SELECT TOP 5 
    p.product_name,
    COUNT(w.claim_id) AS total_claims
FROM warranty w
JOIN sales s ON w.sale_id = s.sale_id
JOIN products p ON s.product_id = p.product_id
GROUP BY p.product_name
ORDER BY total_claims DESC;

--18. Identify the month with the highest sales in the last year
SELECT TOP 1
    FORMAT(sale_date, 'yyyy-MM') AS sale_month,
    SUM(quantity) AS total_units_sold
FROM sales
WHERE sale_date >= DATEADD(YEAR, -1, GETDATE())
GROUP BY FORMAT(sale_date, 'yyyy-MM')
ORDER BY total_units_sold DESC;

--------------------------------
--Business Problems
--------------------------------

-- 20. find number of stores in each country
SELECT country, count(store_id) AS total_stores
FROM stores
GROUP BY country
ORDER BY total_stores DESC;

-- 21. Calculate the total number of units sold by each store.
SELECT store_id, sum(quantity) AS total_unit_sold
FROM sales
GROUP BY store_id
ORDER BY total_unit_sold DESC;

-- 22. Identify how many sales occurred in December 2023.
SELECT COUNT(*) AS total_sales
FROM sales
WHERE FORMAT(sale_date, 'yyyy-MM') = '2023-12';  
       
-- 23. Determine how many stores have never had a warranty claim filed.
SELECT COUNT(*) AS total_store
FROM stores
WHERE store_id NOT IN (
			SELECT DISTINCT s.store_id
			FROM sales AS s
			RIGHT JOIN warranty AS w
			ON s.sale_id = w.sale_id
						);

-- 24. Calculate the percentage of warranty claims marked as "Rejected"
SELECT 
    ROUND(
        CAST(COUNT(claim_id) AS FLOAT) / NULLIF((SELECT COUNT(*) FROM warranty), 0) * 100, 2
    ) AS rejected_percentage
FROM warranty
WHERE repair_status = 'Rejected';

-- 25. Identify which store had the highest total units sold in the last year.
SELECT store_id, SUM(quantity) AS total_unit
FROM sales
WHERE sale_date >= (CURRENT_DATE - INTERVAL '1 year')
GROUP BY store_id
ORDER BY total_unit DESC
LIMIT 1;

-- 26. Count the number of unique products sold in the last year.
SELECT COUNT(DISTINCT product_id)
FROM sales
WHERE sale_date >= (SELECT CURRENT_DATE - INTERVAL '1 YEAR');

-- 27. Find the average price of products in each category.
SELECT c.category_id, c.category_name, ROUND(AVG(price):: NUMERIC ,2) AS avg_price
FROM products AS p
JOIN category AS c
ON p.category_id = c.category_id
GROUP BY c.category_id, c.category_name
ORDER BY avg_price DESC;

-- 28. How many warranty claims were filed in 2024?
SELECT COUNT(*)
FROM warranty
WHERE EXTRACT(YEAR FROM claim_date) = 2024;

-- 29. For each store, identify the best-selling day based on highest quantity sold.
SELECT store_id, DATENAME(WEEKDAY, sale_date) AS day_name, total_quantity
FROM (
    SELECT 
        store_id, 
        DATENAME(WEEKDAY, sale_date) AS day_name, 
        SUM(quantity) AS total_quantity,
        RANK() OVER(PARTITION BY store_id ORDER BY SUM(quantity) DESC) AS rank
    FROM sales
    GROUP BY store_id, DATENAME(WEEKDAY, sale_date)
) AS t
WHERE rank = 1;

-- 30. Identify the least selling product in each country for each year based on total units sold.
WITH product_rank AS(
SELECT 
st.country, 
EXTRACT(YEAR FROM sale_date) AS sale_year, 
p.product_name, 
SUM(quantity) AS total_unit_sold,
RANK() OVER(PARTITION BY country, EXTRACT(YEAR FROM sale_date) ORDER BY SUM(quantity)) AS least_sold_product
FROM products AS p
JOIN sales AS s
ON p.product_id = s.product_id
JOIN stores AS st
ON st.store_id = s.store_id
GROUP BY st.country, EXTRACT(YEAR FROM sale_date), p.product_name
)
SELECT * FROM product_rank
WHERE least_sold_product = 1;

-- 31. Calculate how many warranty claims were filed within 180 days of a product sale.

SELECT 
    COUNT(*) AS claims_within_180_days
FROM warranty AS w
LEFT JOIN sales AS s
    ON w.sale_id = s.sale_id
WHERE w.claim_date - s.sale_date > 0 
  AND w.claim_date - s.sale_date <= 180;

-- 32. Determine how many warranty claims were filed for products launched in the last two years.
SELECT 
    p.product_name,
    COUNT(w.claim_id) AS total_claims
FROM warranty AS w
RIGHT JOIN sales AS s
    ON w.sale_id = s.sale_id
JOIN products AS p
    ON p.product_id = s.product_id
WHERE p.launch_date >= CURRENT_DATE - INTERVAL '2 years'
GROUP BY p.product_name
HAVING COUNT(w.claim_id) > 0;

-- 33. List the months in the last three years where sales exceeded 5,000 units in the USA.

SELECT 
    TO_CHAR(s.sale_date, 'MM-YYYY') AS months,
    SUM(s.quantity) AS total_sold
FROM sales AS s
JOIN stores AS st
ON s.store_id = st.store_id
WHERE st.country = 'United States' 
  AND s.sale_date >= CURRENT_DATE - INTERVAL '3 years'
GROUP BY TO_CHAR(s.sale_date, 'MM-YYYY')
HAVING SUM(s.quantity) > 5000
ORDER BY TO_DATE(TO_CHAR(s.sale_date, 'MM-YYYY'), 'MM-YYYY');

-- 34. Identify the product category with the most warranty claims filed in the last two years.
SELECT 
    c.category_name,
    COUNT(w.claim_id) AS warranty_claims
FROM category AS c
JOIN products AS p
    ON c.category_id = p.category_id
JOIN sales AS s
    ON p.product_id = s.product_id
JOIN warranty AS w
    ON s.sale_id = w.sale_id
WHERE w.claim_date >= CURRENT_DATE - INTERVAL '2 years'
GROUP BY c.category_name
ORDER BY warranty_claims DESC
LIMIT 1; 

-- 35. Determine the percentage chance of receiving warranty claims after each purchase for each country.
SELECT 
    country,
    total_sold,
    total_claim,
    ROUND((total_claim::numeric) / (total_sold::numeric) * 100, 2) AS percentage_of_risk
FROM (
    SELECT
        st.country,
        SUM(s.quantity) AS total_sold,
        COUNT(w.claim_id) AS total_claim
    FROM stores AS st
    JOIN sales AS s
        ON s.store_id = st.store_id
    JOIN warranty AS w
        ON s.sale_id = w.sale_id
    GROUP BY st.country
) AS subquery
ORDER BY percentage_of_risk DESC;

-- 36. Analyze the year-by-year growth ratio for each store.
WITH yearly_sale AS (
    SELECT 
        st.store_id,
        st.store_name,
        EXTRACT(YEAR FROM s.sale_date) AS year_of_sale,
        SUM(s.quantity * p.price) AS total_sale
    FROM stores AS st
    JOIN sales AS s
        ON s.store_id = st.store_id
    JOIN products AS p
        ON p.product_id = s.product_id
    GROUP BY st.store_id, st.store_name, year_of_sale
    ORDER BY st.store_id, year_of_sale
),
growth_ratio AS (
    SELECT 
        store_name,
        year_of_sale,
        total_sale,
        LAG(total_sale) OVER (PARTITION BY store_name ORDER BY year_of_sale) AS prev_sale
    FROM yearly_sale
)
SELECT
    store_name,
    year_of_sale,
    prev_sale,
    total_sale AS curr_sale,
    ROUND(((total_sale - prev_sale)::numeric /prev_sale::numeric) * 100, 2) AS growth_ratio_YOY
FROM growth_ratio
WHERE prev_sale IS NOT NULL
ORDER BY store_name, year_of_sale;

-- 37. Calculate the correlation between product price and warranty claims for products sold 
-- in the last five years, segmented by price range.

SELECT 
    CASE 
        WHEN p.price < 500 THEN 'Low Cost'
        WHEN p.price BETWEEN 500 AND 1000 THEN 'Moderate Cost'
        ELSE 'High Cost'
    END AS price_segment,
    c.category_name,
    COUNT(w.claim_id) AS total_claims,
    COUNT(s.sale_id) AS total_sales,
    ROUND(
        CAST(COUNT(w.claim_id) AS FLOAT) / NULLIF(COUNT(s.sale_id), 0) * 100, 2
    ) AS claim_rate_percentage,
    ROUND(AVG(CAST(p.price AS FLOAT)), 2) AS avg_price_in_segment
FROM products AS p
JOIN sales AS s
    ON p.product_id = s.product_id
LEFT JOIN warranty AS w
    ON w.sale_id = s.sale_id
JOIN category AS c
    ON p.category_id = c.category_id
WHERE s.sale_date >= DATEADD(YEAR, -5, GETDATE())
GROUP BY 
    CASE 
        WHEN p.price < 500 THEN 'Low Cost'
        WHEN p.price BETWEEN 500 AND 1000 THEN 'Moderate Cost'
        ELSE 'High Cost'
    END,
    c.category_name
ORDER BY claim_rate_percentage DESC;

-- 38. Identify the store with the highest percentage of "Completed" claims relative to total claims filed
WITH completed AS (
    SELECT
        s.store_id,
        COUNT(w.claim_id) AS completed
from sales as s
right join warranty as w
on s.sale_id = w.sale_id
where w.repair_status = 'Completed'
group by 1), 

total_repaired 
as
(select
s.store_id,
count(w.claim_id) as total_repaired
from sales as s
right join warranty as w
on s.sale_id = w.sale_id
group by 1)

select 
tr.store_id,
tr.total_repaired,
c.completed,
ROUND(c.completed::numeric/tr.total_repaired::numeric * 100, 2) as percentage_of_completed
from completed as c
join total_repaired as tr
on c.store_id = tr.store_id
order by 4 desc

-- OR --

WITH claim_counts AS (
    SELECT
        s.store_id,
        COUNT(w.claim_id) AS total_repaired,
        SUM(CASE WHEN w.repair_status = 'Completed' THEN 1 ELSE 0 END) AS completed
    FROM sales AS s
    RIGHT JOIN warranty AS w
        ON s.sale_id = w.sale_id
    GROUP BY s.store_id
)
SELECT 
    store_id,
    total_repaired,
    completed,
    ROUND(completed::numeric/total_repaired::numeric * 100, 2) as percentage_of_completed
FROM claim_counts
ORDER BY percentage_of_completed DESC;


-- 39. Write a query to calculate the monthly running total of sales for each store 
-- over the past four years and compare trends during this period. 
WITH monthly_sales AS (
    SELECT
        s.store_id,
        EXTRACT(YEAR FROM s.sale_date) AS year,
        EXTRACT(MONTH FROM s.sale_date) AS month,
        SUM(p.price * s.quantity) AS total_sales
    FROM sales AS s
    JOIN products AS p
        ON s.product_id = p.product_id
    WHERE s.sale_date >= CURRENT_DATE - INTERVAL '4 years'
    GROUP BY s.store_id, year, month
    ORDER BY s.store_id, year, month
)
SELECT
    store_id, 
    year, 
    month, 
    total_sales, 
    SUM(total_sales) OVER(PARTITION BY store_id ORDER BY year, month) AS running_total
FROM monthly_sales
ORDER BY store_id, year, month;





 



 



