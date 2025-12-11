use portdb;

CREATE TABLE sales_store(
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

SELECT * FROM sales_store;

SET dateformat dmy;

BULK INSERT sales_store
FROM 'C:\DATA\DATASET\sales.csv'
WITH(
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n'
);

exec sp_name 

-- DATA CLEANING
SELECT * FROM sales_store;

-- creating a copy of sales_store
SELECT * INTO sales FROM sales_store;
SELECT * FROM sales;

-- Step 1: Check for duplicates
SELECT transaction_id, COUNT(*)
FROM sales
GROUP BY transaction_id
HAVING COUNT(*) > 1;

-- Remove duplicates
WITH CTE AS (
    SELECT *,
    ROW_NUMBER() OVER (PARTITION BY transaction_id ORDER BY (SELECT NULL)) AS row_num
    FROM sales
)
DELETE FROM CTE
WHERE row_num > 1;

-- Check if duplicates were removed
SELECT *
FROM sales
WHERE transaction_id IN ('TXN240646','TXN342128','TXN855235');


-- step 2 correction of headers

exec sp_rename'sales.quantiy' , 'quantity' , 'COLUMN'

exec sp_rename'sales.prce' , 'price' , 'COLUMN'

-- step 3 : to check datatype

select COLUMN_NAME , DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'sales'

-- step 4: to check null values
-- to check null count
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

-- trating null values

 select * from sales
 where transaction_id is null
 or
 customer_id is null
 or 
 customer_name is null
 or
 customer_age is null
 or
 gender is null
 or 
 product_id is null
 or 
 product_name is null
 or 
 product_category is null
 or 
 quantity is null
 or
 payment_mode is null
 or 
 purchase_date is null
 or 
 time_of_purchase is null
 or 
 status is null
 or 
 price is null 

 -- deleting first row because it is outlier

 delete from sales
 where transaction_id is null

 -- replacing the null
 select * from sales
 where customer_name = 'Ehsaan Ram' 

 update sales
 set customer_id = 'CUST9494'
 where transaction_id = 'TXN977900'

  select * from sales
 where customer_name = 'Damini Raju'
 
 update sales
 set customer_id = 'CUST1401'
 where transaction_id = 'TXN985663'

 select * from sales
 where customer_id = 'CUST1003'

 update sales
 set  customer_name = 'Mahika Saini' , customer_age = '35' , gender= 'Male'
 where transaction_id = 'TXN432798'

 select * from sales

 -- STEP 5 : DATA CLEANING

 select distinct gender from sales

 update sales
 set gender = 'M'
 where gender = 'Male'

 update sales
 set gender = 'F'
 where gender = 'Female'

 -- cleaning payment mode

 select distinct payment_mode
 from sales

 update sales
 set payment_mode = 'Credit Card'
 where payment_mode = 'CC'
 
 --							SOLVING  BUSINESS INSIGHTS QUESTIONS 
-- Data analysis

-- QNO. 1 : What are the top 5 most selling products by quantity
select distinct status from sales
	-- =>
		select top 5 product_name , sum(quantity) as total_quantity_sold
		from sales
		where status = 'delivered'
		group by product_name
		order by total_quantity_sold desc;

	-- Business problem : we don't know which product are most in demand.

	------------------------------------------------------------------------------------------

	-- QNO. 2 which products are most frequently canceled
	 
	 -- =>
		select top 5 product_name , COUNT(*) as frequently_cancelled from sales
		where status = 'cancelled'
		group by product_name
		order by frequently_cancelled desc;
	
	-- Business problem : Frequent cancellations affect revenue and customer trust.

	-- Business impact : identify poor-performing products to improve quality or remove from catalog.

	--------------------------------------------------------------------------------------------------------------

	-- QNO. 3 What time of the dayhas the highest number of purchases?

	-- =>
		select * from sales 

		select 
			case 
				when DATEPART(HOUR , time_of_purchase)between 0 and 5 then 'Night'
				when DATEPART(HOUR , time_of_purchase)between 6 and 11 then 'Morning'
				when DATEPART(HOUR , time_of_purchase)between 12 and 17 then 'Afternoon'
				when DATEPART(HOUR , time_of_purchase)between 18 and 23 then 'Evening'
			END as time_of_day , count(*) as total_orders
		from sales
		group by case 
				when DATEPART(HOUR , time_of_purchase)between 0 and 5 then 'Night'
				when DATEPART(HOUR , time_of_purchase)between 6 and 11 then 'Morning'
				when DATEPART(HOUR , time_of_purchase)between 12 and 17 then 'Afternoon'
				when DATEPART(HOUR , time_of_purchase)between 18 and 23 then 'Evening'
			END
		order by total_orders desc;

		--Business problem : find peak sales time

		-- Business impact : optimize staffing , promotions and server loads.

-----------------------------------------------------------------------------------------------------------------

	-- QNO. 4 Who are the top 5 highest spending customer

	--=> 
	SELECT TOP 5 
    customer_name,
    '$' + FORMAT(SUM(price * quantity), 'N2') AS total_spend
	FROM sales
	GROUP BY customer_name
	ORDER BY SUM(price * quantity) DESC;

	-- Business problem solved : identify vip customers.
	
	-- Business impact : personalized offers , loyalty rewards and retention.

------------------------------------------------------------------------------------------------------------------

	-- QNO. 5 which product categories generate the highes revenue?

	-- => 
		
		select * from sales

		select product_category , 
		'$' + format(sum(price * quantity), 'N2') as highest_revenue
		from sales
		group by  product_category
		order by sum(price * quantity) desc;

	-- business problem solved : identify top-performing product categories.

	-- business impact: refine product strategy , supply chain , and promotions.
	-- allowing the business to invest more in high-margin or high-demand categories.

------------------------------------------------------------------------------------------------------------

-- QNO. 6 what is the return and cancellation rate per product category
select * from sales
	-- =>
	-- cancellation
	select product_category , 
	format(COUNT(case when status = 'cancelled' then 1 end)*100.0/count(*),'N3') + ' %' as cancelled_percent
	from sales
	group by product_category
	order by cancelled_percent desc;

	-- returned
	select product_category , 
	format(COUNT(case when status = 'returned' then 1 end)*100.0/count(*),'N3') + ' %' as returned_percent
	from sales
	group by product_category
	order by returned_percent desc;

	-- business problem solved : monitor dissatisfaction trends per category

	-- business impact: reduce returns , improve product description/ expectations.
	-- helps identify and fix product or logistics issues.

-------------------------------------------------------------------------------------------------------------------------

-- QNO. 7 what is the most preffered payment method?
 -- =>
 select * from sales
 select payment_mode , count(*) as total_count from sales
 group by payment_mode
 order by total_count desc;

 -- business problem solved : know which payment options customers prefer.

 -- business impact : streamline payment processing , prioritize popular modes.

------------------------------------------------------------------------------------------------------------

-- QNO . 8 how does age group affect purchasing behaviour
	select * from sales
	-- =>
	select Min(customer_age) , MAX(customer_age) from sales
	select 
		case
			when customer_age Between 18 and 25 then '18-25'
			when customer_age Between 26 and 35 then '26-35'
			when customer_age Between 36 and 50 then '36-50'
			else '51+'
		end as customer_age ,
		FORMAT(SUM (price * quantity),'C0' , 'en-IN') as total_purchase
		from sales
		group by case
			when customer_age Between 18 and 25 then '18-25'
			when customer_age Between 26 and 35 then '26-35'
			when customer_age Between 36 and 50 then '36-50'
			else '51+'
		end
		order by total_purchase desc

	-- business problem solved : understand customer demographics.

	-- business impact: targetd marketing and product recommendation by age group.

-----------------------------------------------------------------------------------------------------
	
	-- QNO. 9 what's the monthly sales trend?

	select * from sales

	-- =>
	-- 1st method to solve this question
		select 
			format(purchase_date , 'yyyy-MM') as month_year,
			FORMAT(SUM(price * quantity) , 'C0' , 'en-IN') as total_sales,
			SUM(quantity) as total_quantity
			from sales
			group by format(purchase_date , 'yyyy-MM') 

	-- 2nd method
	select 
	YEAR(purchase_date) as purchased_year ,
	MONTH(purchase_date) as purchased_month , 
	FORMAT(SUM(price * quantity), 'C0' , 'en-IN') as total_sales,
	SUM(quantity) as total_quantity 
	from sales
	group by YEAR(purchase_date) , 
	MONTH(purchase_date)
	order by purchased_month

	-- use this query if you want to show 12 months of record only
	select 
	MONTH(purchase_date) as purchased_month , 
	FORMAT(SUM(price * quantity), 'C0' , 'en-IN') as total_sales,
	SUM(quantity) as total_quantity 
	from sales
	group by MONTH(purchase_date)
	order by purchased_month

	-- business problem solved : sales fluctutation go unnoticed.

	-- business impact : plan inventoty and marketing according to seasonal trends.

-----------------------------------------------------------------------------------------------------------------

	-- QNO . 10 Are certain gender buying more specific product categories?
	select * from sales
	-- =>
	-- 1st method
		select gender , 
			product_category ,
			count(product_category) as total_purchase 
			from sales
			group by gender , product_category
			order by gender 

	-- 2nd method (same method but converting into pivot)
	select * 
	from(
		select gender , product_category
		from sales
		) as source_table
	PIVOT (
	count(gender)
	for gender IN ([M],[F])
	) as pivot_table
	order by product_category

	-- business problem solved: gender-based product preference

	-- business impact: personalized ads , gender-focused campaigns.

	

		


		

	


