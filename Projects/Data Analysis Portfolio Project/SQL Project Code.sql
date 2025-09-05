CREATE TABLE Sales_store(

transaction_id varchar(15),
customer_id varchar(15),
customer_name varchar(15),
customer_age INT,
gender varchar(15),
product_id varchar(15),
product_name varchar(15),
product_category varchar(15),
quantiy INT,
prce FLOAT,
payment_mode varchar(15),
purchase_date DATE ,
time_of_purchase TIME,
status varchar(15)
);
 
-- Update Column Character
ALTER TABLE sales_store
ALTER COLUMN customer_name
varchar(50);

SELECT * from sales_store;

SET DATEFORMAT dmy
BULK INSERT sales_store
FROM 'C:\Users\Personal PC\Desktop\New job role expected from Ajit Sharma\SQL Practice\Aug_25_New_Project\Sales.csv'
    WITH (
	    FIRSTROW=2,
		FIELDTERMINATOR=',',
		ROWTERMINATOR='\n'
		);
--YYYY-MM-DD

--Data Cleaning
SELECT * from sales_store;

SELECT * INTO Sales from sales_store;

SELECT * from sales_store;
SELECT * from sales

--Data Cleaning Step 1: - To check for duplicate
--Identify Unique data column (Considering 'transaction_id' here)

SELECT transaction_id, COUNT(*)
FROM Sales
GROUP BY transaction_id
HAVING COUNT(transaction_id) > 1

TXN240646
TXN342128
TXN855235
TXN981773


--Finding Distinct Duplicate transaction_id
WITH CTE AS (
SELECT *,
    ROW_NUMBER() OVER (PARTITION BY transaction_id ORDER BY transaction_id) AS Row_Num
	FROM Sales
  )

SELECT * FROM CTE
WHERE Row_Num >1

--Finding all lines containing duplicate transaction_id

WITH CTE AS (
SELECT *,
    ROW_NUMBER() OVER (PARTITION BY transaction_id ORDER BY transaction_id) AS Row_Num
	FROM Sales
  )
--DELETE FROM CTE -- Delete Duplicating transaction_id from rows 
--WHERE Row_Num=2

SELECT * FROM CTE
WHERE transaction_id IN ('TXN240646',	'TXN342128',	'TXN855235',	'TXN981773')

--Steps 2: - Correction of Headers

SELECT * FROM Sales

Exec sp_rename'sales.quantiy','quantity','COLUMN'

Exec sp_rename'sales.prce','price','COLUMN'

-- Step: - 3 To Check Datatype

SELECT COLUMN_NAME, DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME='Sales'

-- Step 4: - To Check NULL Values

-- to check Null Count

DECLARE @SQL NVARCHAR(MAX) = '';
SELECT @SQL = STRING_AGG(
    'SELECT ''' + COLUMN_NAME + ''' AS ColumnName,
	COUNT(*) AS NullCount
	FROM ' + QUOTENAME(TABLE_SCHEMA) + '.sales
	WHERE ' + QUOTENAME(COLUMN_NAME) + ' IS NULL',
	' UNION ALL '

)

WITHIN GROUP (ORDER BY COLUMN_NAME)
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'sales';

-- Execute the dynamic SQL 
EXEC sp_executesql @SQL;

-- treating null values

SELECT * 
FROM sales
WHERE customer_age IS NULL
OR 
customer_id IS NULL
OR 
customer_name IS NULL
OR 
gender IS NULL
OR 
payment_mode IS NULL
OR 
price IS NULL
OR 
product_category IS NULL
OR 
product_id IS NULL
OR 
product_name IS NULL
OR 
purchase_date IS NULL
OR 
quantity IS NULL
OR 
status IS NULL
OR 
time_of_purchase IS NULL
OR 
transaction_id IS NULL

DELETE FROM sales
WHERE transaction_id IS NULL

SELECT * FROM Sales
WHERE customer_name = 'Ehsaan Ram'

UPDATE Sales
SET customer_id = 'CUST9494'
WHERE transaction_id = 'TXN977900'

SELECT * FROM Sales
WHERE customer_name = 'Damini Raju'
UPDATE Sales
SET customer_id = 'CUST1401'
WHERE transaction_id = 'TXN985663'

SELECT * FROM Sales
WHERE customer_id = 'CUST1003'

UPDATE Sales
SET customer_name = 'Mahika Saini', customer_age = 35, gender = 'Male'
WHERE transaction_id = 'TXN432798'

-- Step 5: - Data Cleaning for Gender & Payment_Mode

SELECT DISTINCT gender
from sales

UPDATE Sales
SET gender = 'Male'
WHERE gender = 'M'


UPDATE Sales
SET gender = 'Female'
WHERE gender = 'F'


SELECT DISTINCT payment_mode
FROM sales

UPDATE Sales
SET payment_mode = 'Credit Card'
WHERE payment_mode = 'CC'

SELECT * FROM Sales

--04. Solving Business Insights Questions

--Data Analysis

--1. What are the top 5 most selling products by quantity?

SELECT TOP 5 product_name, SUM(quantity) AS total_quantity_sold
FROM Sales
WHERE status = 'delivered'
GROUP BY product_name
ORDER BY total_quantity_sold DESC;

--Business Problem - we don't know which products are most in demand.
--Business Impact - Helps prioritize stock and boost sales through targeted promotions.

--2. Which products are most frequently cancelled?

SELECT TOP 5 product_name, COUNT(*) AS total_cancelled
FROM sales
WHERE status = 'cancelled'
GROUP BY product_name
ORDER BY total_cancelled DESC

--Business Problem - Frequent cancellations affect revenue and customer trust.
--Business Impact - Identify poor-performing products to improve quality or remove from catalog.

--3. What time of the day has the highest number of purchases?

SELECT * FROM Sales
   -- Highest number of purchases
   SELECT
       CASE
	       WHEN DATEPART(HOUR,time_of_purchase) BETWEEN 0 AND 5 THEN 'NIGHT'
		   WHEN DATEPART(HOUR,time_of_purchase) BETWEEN 6 AND 11 THEN 'MORNING'
		   WHEN DATEPART(HOUR,time_of_purchase) BETWEEN 12 AND 17 THEN 'AFTERNOON'
		   WHEN DATEPART(HOUR,time_of_purchase) BETWEEN 18 AND 23 THEN 'EVENING'
	   END AS time_of_day,
	   COUNT(*) AS total_orders
   FROM Sales
   GROUP BY 
       CASE
	       WHEN DATEPART(HOUR,time_of_purchase) BETWEEN 0 AND 5 THEN 'NIGHT'
		   WHEN DATEPART(HOUR,time_of_purchase) BETWEEN 6 AND 11 THEN 'MORNING'
		   WHEN DATEPART(HOUR,time_of_purchase) BETWEEN 12 AND 17 THEN 'AFTERNOON'
		   WHEN DATEPART(HOUR,time_of_purchase) BETWEEN 18 AND 23 THEN 'EVENING'
       END
  ORDER BY total_orders DESC

-- Business Problem solved: - find peak sales time.
-- Business Impact: - Optimize staffing, promotions, and server loads.

--4 Who are the top 5 highest spending customers?

SELECT * FROM Sales;
SELECT TOP 5 customer_name, 
    FORMAT(SUM(price * quantity), 'C0', 'en-IN') AS total_spend
FROM Sales
GROUP BY customer_name
ORDER BY SUM(price * quantity) DESC;

--Business Problem Solved: Identify VIP customers.
--Business Impact: Personalized offers, loyalty rewards, and retention.

--5. Which Product categories generate the highest revenue?

SELECT * FROM Sales;

SELECT product_category, 
       FORMAT(SUM(price * quantity), 'C0', 'en-IN') AS Revenue
FROM Sales
GROUP BY product_category
ORDER BY SUM(price * quantity) DESC

--Business Problem Solved: Identify top-performing product categories.
--Business Impact: Refine product strategy, supply chain, and promotions.
--allowing the business to invest more in high-margin or high-demand categories.

--6. What is the return/cancellation rate per product category?

SELECT * FROM Sales
--cancellation
SELECT product_category,
    FORMAT(COUNT(CASE WHEN status='cancelled' THEN 1 END)*100.0/COUNT(*), 'N3') + '%' AS Cancelled_percent
FROM Sales
GROUP BY product_category
ORDER BY Cancelled_percent DESC

--cancellation
SELECT product_category,
    FORMAT(COUNT(CASE WHEN status='returned' THEN 1 END)*100.0/COUNT(*), 'N3') + '%' AS Returned_percent
FROM Sales
GROUP BY product_category
ORDER BY Returned_percent DESC

--Business Problem Solved: Monitor dissatisfaction trends per categories

--Business Impact: Reduce returns, improve product descriptions / expectations.
--Helps identify and fix product or logistics issues.

--7. What is the most preferred payment mode?
SELECT * FROM Sales;

SELECT Payment_mode, COUNT(payment_mode) As total_count
FROM Sales
GROUP BY payment_mode
ORDER BY total_count DESC

--Business Problem Solved: Know which payment options customers prefer.
--Business Impact: Streamline payment processing, prioritize popular modes.

-- 8 How does age group affect purchasing behavior?
SELECT * FROM Sales

SELECT
	CASE 
		WHEN customer_age BETWEEN 18 AND 25 THEN '18-25'
		WHEN customer_age BETWEEN 26 AND 35 THEN '26-35'
		WHEN customer_age BETWEEN 36 AND 50 THEN '36-50'
		ELSE '51+'
	END AS customer_age,
	FORMAT (SUM(price*quantity), 'C0', 'en-IN') AS total_purchase
FROM Sales
GROUP BY CASE 
		WHEN customer_age BETWEEN 18 AND 25 THEN '18-25'
		WHEN customer_age BETWEEN 26 AND 35 THEN '26-35'
		WHEN customer_age BETWEEN 36 AND 50 THEN '36-50'
		ELSE '51+'
	END
ORDER BY total_purchase DESC

--Business Problem Solved: Understand customer demographics.
--Business Impact: Targeted marketing and product recommendations by age group.

--9. What's the monthly sales trend?

SELECT * FROM Sales
 --Method 1

SELECT 
	FORMAT(purchase_date, 'yyyy-MM') AS Month_Year,
	FORMAT(SUM(price*quantity),'C0', 'en-IN') AS total_sales,
	SUM(quantity) AS total_quantity
FROM Sales
GROUP BY FORMAT(purchase_date, 'yyyy-MM')

 --Method 2

 SELECT
	--YEAR(purchase_date) AS Years,
	MONTH(purchase_date) AS Months,
	FORMAT(SUM(price*quantity), 'C0', 'en-IN') AS total_sales,
	SUM(quantity) AS total_quantity
FROM Sales
GROUP BY MONTH(purchase_date)
ORDER BY Months

--Business Problem: Sales fluctuations go unnoticed.
--Business Impact: Plan Inventory and marketing according to seasonal trends.

--10. Are certain genders buying more specific product categories?

SELECT * FROM sales
--Method 1
SELECT gender, product_category, COUNT(product_category) AS total_purchase
FROM Sales
GROUP BY gender, product_category
ORDER BY gender;

--Method 2
SELECT *
FROM (
	SELECT gender, product_category
	FROM Sales
	) AS source_table
PIVOT (
	COUNT(gender)
	FOR gender IN ([Male], [Female])
	) AS pivot_table
ORDER BY product_category