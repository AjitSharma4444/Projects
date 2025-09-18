use Supply_Chain_Analysis;

-- create table Supply_Chain_Analysis (
-- ' product_type varchar(50),
-- ' sku varchar(50),
-- ' price double,
-- ' availability bigint,
-- ' number_of_products_sold bigint,
-- ' revenue_generated double,
-- ' customer_demographics varchar(50),
-- ' stock_levels bigint,
-- ' lead_times bigint,
-- ' order_quantities bigint,
-- ' shipping_times bigint,
-- ' shipping_carriers varchar(50),
-- ' shipping_costs double,
-- ' supplier_name varchar(50),
-- ' location varchar(50),
-- ' lead_time bigint,
-- ' production_volumes bigint,
-- ' manufacturing_lead_time bigint,
-- ' manufacturing_costs double,
-- ' inspection_results varchar(50),
-- ' defect_rates double,
-- ' transportation_modes varchar(50),
-- ' routes varchar(50),
-- ' costs double)

-- Import data from csv file

SELECT * FROM supply_chain_analysis.supply_chain_analysis;

-- truncate supply_chain_analysis; # to append with cleaned data

select *
from supply_chain_analysis
where customer_demographics is NULL;

-- 1. What are the top-performing and underperforming product types by revenue, volume, and profit margin?
-- (a.) Identify which SKUs or product types are driving revenue vs. those generating low or negative returns.

select Product_type, format(SUM(Revenue_generated),'c0', 'en-IN') AS Revenue
FROM supply_chain_analysis.supply_chain_analysis
Group by  Product_type;

-- (b.) Detect stockouts or overstock issues linked to underperformance.
-- find low_sales_threshold: 
select distinct number_of_products_sold from supply_chain_analysis;

select max(number_of_products_sold) as high_sales_threshold,
min(number_of_products_sold) as low_sales_threshold
from supply_chain_analysis;
 -- high_sales_threshold	low_sales_threshold
 -- 900 (996)						10 (8)
  -- max_stock_levels	min_stock_levels
  -- 100	                 0 
-- '	product_type	high_sales_threshold	low_sales_threshold	max_stock_levels	min_stock_levels
-- '	haircare		946							8					100						0
-- '	skincare		996							65					96						1
-- '	cosmetics		987							25					100						4




select * from (
SELECT 
    sku,
    product_type,
    stock_levels,
    number_of_products_sold,
    revenue_generated,
    price,
   CASE 
        WHEN stock_levels = 0 AND number_of_products_sold > 0 THEN 'Stockout'    
        WHEN stock_levels > 100 AND number_of_products_sold < 10 THEN 'Overstock Underperformance'
        Else 'Normal'
   END AS stock_performance_flag
FROM 
    supply_chain_analysis) as a
    where stock_performance_flag in ( 'Stockout', 'Overstock Underperformance');

-- (c. ) Future Prediction Use:Use historical sales, availability, and price data to forecast demand and plan stock or promotions.
-- (d. ) Predict product cannibalization or seasonal trends.🚚 

-- 2. How efficient and cost-effective are the current shipping carriers and transportation routes?

-- 1 Purpose: This will help identify which carrier is fastest and most affordable on average.
-- ✅ . Average Shipping Time and Cost by Carrier
SELECT 
    shipping_carriers,
    ROUND(AVG(shipping_times), 2) AS avg_shipping_time,
    ROUND(AVG(costs), 2) AS avg_shipping_cost
FROM supply_chain_analysis
GROUP BY shipping_carriers
ORDER BY avg_shipping_cost ASC, avg_shipping_time ASC;

-- 2. This helps assess which routes are more efficient and cost-effective.
-- Average Shipping Time and Cost by Route

SELECT 
    routes,
    ROUND(AVG(shipping_times), 2) AS avg_shipping_time,
    ROUND(AVG(costs), 2) AS avg_shipping_cost
FROM supply_chain_analysis
GROUP BY routes
ORDER BY avg_shipping_cost ASC, avg_shipping_time ASC;

-- 3 Reveals the best-performing carrier-route combinations.
-- Average Shipping Time and Cost by Carrier & Route Combination
SELECT 
    shipping_carriers,
    routes,
    ROUND(AVG(shipping_times), 2) AS avg_shipping_time,
    ROUND(AVG(costs), 2) AS avg_shipping_cost,
    COUNT(*) AS shipment_count
FROM supply_chain_analysis
GROUP BY shipping_carriers, routes
ORDER BY avg_shipping_cost ASC, avg_shipping_time ASC;

-- 4. Identify shipments where time and cost are most optimized.
-- Top 5 Most Cost-Effective Shipments (Lowest Cost per Day)

SELECT 
    sku,
    shipping_carriers,
    location,
    routes,
    shipping_times,
    costs,
    ROUND(costs / NULLIF(shipping_times, 0), 2) AS cost_per_day
FROM supply_chain_analysis
ORDER BY cost_per_day ASC
LIMIT 5;

-- 5. Gives a holistic view of the dataset.
-- Summary Stats (All Carriers and Routes)
SELECT 
    COUNT(*) AS total_shipments,
    ROUND(AVG(shipping_times), 2) AS overall_avg_shipping_time,
    ROUND(AVG(costs), 2) AS overall_avg_cost
FROM supply_chain_analysis;







-- 3. Are supplier and manufacturing lead times aligned with demand and stock levels?Current Scenario 

-- We need to analyze the relationship between:

-- 1.Lead Time (Supplier): Lead time
-- 2.Manufacturing Lead Time: Manufacturing lead time
-- 3.Demand indicators: Number of products sold, Revenue generated
-- 4.Stock levels: Stock levels

-- Calculate average daily sales to understand consumption rate:
	-- Average Daily Sales = Number of products sold / 30 (assume 30 days)

-- Calculate how many days of stock are left:
	-- Stock Coverage (days) = Stock levels / Average Daily Sales

-- Compare stock coverage with lead times:
	-- If Stock Coverage < (Lead time + Manufacturing lead time) → Stock will run out before replenishment → Not aligned
SELECT
    SKU,
    Product_type,
    Stock_levels,
    Number_of_products_sold,
    Lead_time,
    Manufacturing_lead_time,
    (Number_of_products_sold / 30.0) AS avg_daily_sales,
    CASE 
        WHEN (Number_of_products_sold / 30.0) = 0 THEN NULL
        ELSE Stock_levels / (Number_of_products_sold / 30.0)
    END AS stock_coverage_days,
    (Lead_time + Manufacturing_lead_time) AS total_lead_time_days,
    CASE 
        WHEN (Stock_levels / NULLIF(Number_of_products_sold, 0) * 30.0) < (lead_time + Manufacturing_lead_time) THEN 'Not aligned'
        ELSE 'Aligned'
    END AS alignment_status
FROM supply_chain_analysis
ORDER BY alignment_status, SKU;


-- 4. How does product quality (defect rates & inspection results) affect returns, reputation, and overall costs?

SELECT Defects_n_inspection_category, round(sum(revenue_generated),2) as Sales_Revenue, round(sum(Total_cost),2) as Total_Cost
FROM
 (SELECT product_type, defect_rates, inspection_results, revenue_generated, costs,
(CASE
	WHEN inspection_results = 'Fail' and defect_rates > 4 THEN 'Highy_defective_failed'
    WHEN inspection_results = 'Fail' and defect_rates between 1 and 4 THEN 'Average_defective_failed'
    WHEN inspection_results = 'Fail' and defect_rates < 1 THEN 'Minimum_defective_failed'
    WHEN inspection_results = 'Pass' and defect_rates > 4 THEN 'Highy_defective_passed'
    WHEN inspection_results = 'Pass' and defect_rates between 1 and 4 THEN 'Average_defective_passed'
    WHEN inspection_results = 'Pass' and defect_rates < 1 THEN 'Minimum_defective_passed'
    Else 'in_transit_not_yet_delivered'
END) AS Defects_n_inspection_category    
from supply_chain_analysis) as sales_count 
GROUP BY Defects_n_inspection_category
;

select supplier_name, inspection_results, count(inspection_results) Inspection_count, round(avg(defect_rates),3) avg_defects, round(sum(revenue_generated),2) Revenue, round(sum(costs),2) Total_cost
from supply_chain_analysis
group by supplier_name, inspection_results
order by inspection_results;




