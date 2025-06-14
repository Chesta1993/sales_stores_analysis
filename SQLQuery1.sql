
create database sales

use sales

CREATE TABLE sales_store (
transaction_id VARCHAR(15),
customer_id VARCHAR(15),
customer_name VARCHAR(30),
customer_age INT,
gender VARCHAR(15),
product_id VARCHAR(15),
product_name VARCHAR(15),
product_category VARCHAR(15),
quantiy INT,
prce FLOAT,
payment_mode VARCHAR(15),
purchase_date DATE,
time_of_purchase TIME,
status VARCHAR(15)
);

select * from sales_store;

set dateformat dmy
bulk insert sales_store
	from 'F:\sales_store\sales.csv'
	 with (
	 firstrow = 2,
	 fieldterminator =',',
	 rowterminator='\n'
	 );

----Data Cleaning---
---create copy
select * into sales from sales_store

----drop table sales

select * from sales
-----1) Check for duplicates

SELECT transaction_id,COUNT(*)
FROM sales 
GROUP BY transaction_id
HAVING COUNT(transaction_id) >1

with cte as(
select 
*,
ROW_NUMBER() over(partition by transaction_id order by transaction_id) as row_num
from sales)

/*delete from cte
where transaction_id in ('TXN240646','TXN342128','TXN855235','TXN981773')
and row_num =2
*/

select 
*
from cte
where transaction_id in  ('TXN240646','TXN342128','TXN626832','TXN745076','TXN832908','TXN855235','TXN981773');

/*actual duplicates
TXN240646
TXN342128
TXN855235
TXN981773
*/

--2) Correction Of headers

EXEC sp_rename 'sales.quantiy','quantity','Column'

EXEC sp_rename 'sales.prce','price','Column'

---3) Check Datatypes

select 
COLUMN_NAME, DATA_TYPE
from INFORMATION_SCHEMA.COLUMNS
where table_name ='sales'

----4) Check for nulls

--to check null count

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


--treating null values 

SELECT *
FROM sales 
WHERE transaction_id IS NULL
OR
customer_id IS NULL
OR
customer_name IS NULL
OR
customer_age IS NULL
OR
gender IS NULL
OR
product_id IS NULL
OR
product_name IS NULL
OR
product_category IS NULL
OR
quantity IS NULL
or
payment_mode is null
or
purchase_date is null
or 
status is null
or 
price is null

delete from sales
where transaction_id is null ----outlier

SELECT * FROM sales 
Where Customer_name='Ehsaan Ram'

UPDATE sales
SET customer_id='CUST9494'
WHERE transaction_id='TXN977900'

SELECT * FROM sales 
Where Customer_name='Damini Raju'

UPDATE sales
SET customer_id='CUST1401'
WHERE transaction_id='TXN985663'

SELECT * FROM sales 
Where Customer_id='CUST1003'

UPDATE sales
SET customer_name='Mahika Saini',customer_age=35,gender='Male'
WHERE transaction_id='TXN432798'


SELECT * FROM sales

---5) Data Cleaning (Correcting Format)

select distinct gender
from sales

update sales
set gender='M'
where gender='Male'

update sales
set gender='F'
where gender='Female'

select distinct payment_mode
from sales

update sales
set payment_mode='Credit Card'
where payment_mode='CC'
--------------------------------------------------------------------------------------------------------
-------------DATA ANALYSIS-----------

--1. What are the top 5 most selling products by quantity?

select
distinct status
from sales

select top 5
product_name,
sum(quantity) as total_qunatity_sold
from sales
where status='delivered'
group by product_name
order by total_qunatity_sold desc

--Business Problem: We don't know which products are most in demand.

--Business Impact: Helps prioritize stock and boost sales through targeted promotions.

--------------------------------------------------------------------------------------------------------------

-- 2. Which products are most frequently cancelled?

select 
product_name,
COUNT(*) as total_cancelled
from sales
where status='cancelled'
group by product_name
order by total_cancelled desc

--Business Problem: Frequent cancellations affect revenue and customer trust.

--Business Impact: Identify poor-performing products to improve quality or remove from catalog.

-----------------------------------------------------------------------------------------------------------------

-- 3. What time of the day has the highest number of purchases?

select * from sales

select 
	case 
		when DATEPART(HOUR,time_of_purchase) between 0 and 5 then 'Night'
		when DATEPART(HOUR,time_of_purchase) between 6 and 11 then 'Morning'
		when DATEPART(HOUR,time_of_purchase) between 12 and 17 then 'Afternoon'
		when DATEPART(HOUR,time_of_purchase) between 18 and 23 then 'Evening'
	end as time_of_day,
	COUNT(*) as total_orders
from sales
group by 
   case 
		when DATEPART(HOUR,time_of_purchase) between 0 and 5 then 'Night'
		when DATEPART(HOUR,time_of_purchase) between 6 and 11 then 'Morning'
		when DATEPART(HOUR,time_of_purchase) between 12 and 17 then 'Afternoon'
		when DATEPART(HOUR,time_of_purchase) between 18 and 23 then 'Evening'
	end 
order by total_orders desc;

-----------------------------------------
select 
datepart(HOUR,time_of_purchase) as Peak_Time,
COUNT(*) as total_orders
from sales
group by datepart(HOUR,time_of_purchase)
order by Peak_Time desc

--Business Problem Solved: Find peak sales times.

--Business Impact: Optimize staffing, promotions, and server loads.

--------------------------------------------------------------------------------------------------------

--4. Who are the top 5 highest spending customers?

select  top 5
customer_name,
format(sum(price*quantity),'C0','en-IN') as total_spending
from sales
group by customer_name
order by sum(price*quantity) desc;

--Business Problem Solved: Identify VIP customers.

--Business Impact: Personalized offers, loyalty rewards, and retention.

---------------------------------------------------------------------------------------------------------

--5. Which product categories generate the highest revenue?

select 
product_category,
format(sum(price*quantity),'C0','en-IN') as revenue
from sales
group by product_category
order by sum(price*quantity) desc;

--Business Problem Solved: Identify top-performing product categories.

--Business Impact: Refine product strategy, supply chain, and promotions.
--allowing the business to invest more in high-margin or high-demand categories.

------------------------------------------------------------------------------------------------------------

--6. What is the return/cancellation rate per product category?

-----cancellation
select 
product_category,
format(count(case when status='cancelled' then 1 end)*100.0/count(*),'N3') +' ' +'%'   as cancelled_percent
from sales
group by product_category
order by cancelled_percent desc;

------return
select 
product_category,
format(count(case when status='returned' then 1 end)*100.0/count(*),'N3') +' ' +'%'   as return_percent
from sales
group by product_category
order by return_percent desc;

--Business Problem Solved: Monitor dissatisfaction trends per category.


---Business Impact: Reduce returns, improve product descriptions/expectations.
--Helps identify and fix product or logistics issues.

--------------------------------------------------------------------------------------------------------

--7. What is the most preferred payment mode?

select
payment_mode,
count(*) as total_count
from sales
group by payment_mode
order by total_count desc;

--Business Problem Solved: Know which payment options customers prefer.

--Business Impact: Streamline payment processing, prioritize popular modes.

--------------------------------------------------------------------------------------------------------

--8. How does age group affect purchasing behavior?

--select MIN(customer_age) , max(customer_age) from sales

select 
customer_age,
format(sum(price*quantity),'C0','en-IN') as total_purchase
from
(
select 
 price,
 quantity,
 case 
	when customer_age between 18 and 25 then '18-25'
	when customer_age between 26 and 35 then '26-35'
	when customer_age between 36 and 50 then '36-50'
	else '51+'
 end as customer_age
from sales) t
group by customer_age
order by sum(price*quantity) desc;

--Business Problem Solved: Understand customer demographics.

--Business Impact: Targeted marketing and product recommendations by age group.

---------------------------------------------------------------------------------------------------
-- 9. What’s the monthly sales trend?

---Method 1

select 
format(purchase_date,'yyyy-MM') as purchase_Month_Year,
format(SUM(quantity*price),'C0','en-IN') as total_sales,
sum(quantity) as total_quantity
from sales
group by format(purchase_date,'yyyy-MM')
order by purchase_Month_Year;

-----Method 2

select 
--YEAR(purchase_date) as purchase_year,
month(purchase_date) as purchase_month,
format(SUM(quantity*price),'C0','en-IN') as total_sales,
sum(quantity) as total_quantity
from sales
group by month(purchase_date)
order by purchase_month;

--Business Problem: Sales fluctuations go unnoticed.


--Business Impact: Plan inventory and marketing according to seasonal trends.

-------------------------------------------------------------------------------------------------------

---10. Are certain genders buying more specific product categories?

with cte as(
select
*,
LEAD(total_purchase_female) over(partition by product_category order by gender) as total_purchase_male
from
(
select 
product_category,
gender,
COUNT(product_category) as total_purchase_female
from sales
group by product_category,
		 gender
)t)

select 
product_category,
total_purchase_female,
total_purchase_male
from cte
where total_purchase_male is not null

--Business Problem Solved: Gender-based product preferences.

--Business Impact: Personalized ads, gender-focused campaigns.