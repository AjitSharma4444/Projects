SELECT *
  FROM New_Orders;

--1. Find top 10 highest revenue generating products

select top 10 product_id, FORMAT(sum(sale_price),'C2', 'en-IN') as sales
from new_orders
group by product_id
order by sum(sale_price) desc;

--2. Find top 5 highest selling products in each region

with cte as (
select region, product_id, sum(sale_price) as sales
from new_orders
group by region, product_id)
select * from (
select * 
, row_number() over(partition by region order by sales desc) as rn 
from cte) A
where rn<=5

--3. Find month over month growth comparison for 2022 and 2023 sales eg : Jan 2022 and Jan 2023
with cte as (
select year(order_date) as order_year,month(order_date) as order_month,
sum(sale_price) as sales 
from new_orders
group by year(order_date), month(order_date)
--order by year(order_date), month(order_date)
)

select order_month
, sum(case when order_year=2022 then sales else 0 end) as sales_2022
, sum(case when order_year=2023 then sales else 0 end) as sales_2023
from cte
group by order_month
order by order_month

--4. For each category which month had highest sales
with cte as (
select category, format(order_date,'yyyy-MM') as order_year_month
, format(sum(sale_price), 'c2', 'en-IN') as sales 
from new_orders
group by category, format(order_date,'yyyy-MM')
--order by category, format(order_date,'yyyyMM')
)
select * from (
select *,
row_number() over(partition by category order by sales desc) as rn
from cte
) a
where rn=1

--5. Which sub category had highest growth by profit in 2023 compare to 2022

with cte as (
select sub_category, year(order_date) as order_year,
sum(sale_price) as sales 
from new_orders
group by sub_category, year(order_date)
--order by year(order_date), month(order_date)
)
, cte2 as (
select sub_category
, sum(case when order_year=2022 then sales else 0 end) as sales_2022
, sum(case when order_year=2023 then sales else 0 end) as sales_2023
from cte
group by sub_category
)
select top 1*
,(sales_2023-sales_2022)*100/sales_2022 -- if for percentage wise growth, else can omit /sales_2022
from cte2
order by (sales_2023-sales_2022)*100/sales_2022 desc