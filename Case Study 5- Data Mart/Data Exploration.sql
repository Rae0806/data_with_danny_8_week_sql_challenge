set search_path = data_mart;

select * from clean_weekly_sales;
 -- What day of the week is used for each week_date value?

select distinct to_char(week_date, 'day')
from clean_weekly_sales;

-- What range of week numbers are missing from the dataset?
with week_numbers as (
select generate_series(1,52) as week_number
)
select week_number
from week_numbers 
where week_number not in(select distinct week_num from clean_weekly_sales order by week_num)

-- How many total transactions were there for each year in the dataset?

select calendar_year, sum(transactions) total_transactions
from clean_weekly_sales
group by calendar_year

-- What is the total sales for each region for each month?

select region, month_num, sum(sales) total_sales
from clean_weekly_sales
group by region, month_num
order by region,month_num;

-- What is the total count of transactions for each platform

select platform, sum(transactions) total_transaction_count
from clean_weekly_sales
group by platform;

-- What is the percentage of sales for Retail vs Shopify for each month? 

with monthly_sales as 
(select calendar_year, month_num, 
 		sum(case when platform = 'Retail' then sales end):: numeric retail_sales, 
 		sum(case when platform = 'Shopify' then sales end):: numeric shopify_sales,
 		sum(sales) total_sales
from clean_weekly_sales
group by calendar_year, month_num
order by calendar_year, month_num
)

select  calendar_year, month_num, retail_sales,total_sales,
		round(retail_sales/total_sales*100,2) retail_sales_percent,
		100 - round(retail_sales/total_sales*100,2) shopify_sales_percent
from monthly_sales;

-- What is the percentage of sales by demographic for each year in the dataset?
with demographic_sales as
(select calendar_year, 
		sum(case when demographic = 'Families' then sales end):: numeric families_sales,
		sum(case when demographic = 'Couples' then sales end):: numeric couples_sales,
		sum(sales) total_sales
from clean_weekly_sales
where demographic not in ('Unknown')
group by calendar_year
order by calendar_year)

select calendar_year,
		round(families_sales/total_sales*100,2) families_sales_percent,
		100 - round(families_sales/total_sales*100,2) couples_sales_percent
from demographic_sales


-- Which age_band and demographic values contribute the most to Retail sales?

select  age_band, demographic, 
		round(100*sum(sales)/(select sum(sales)::numeric from clean_weekly_sales where platform = 'Retail'),2) total_sales
from clean_weekly_sales
where platform = 'Retail'
group by age_band, demographic
order by total_sales desc;

-- Can we use the avg_transaction column to find the average transaction size for each year for Retail vs Shopify?
-- If not - how would you calculate it instead?

-- We can't use the avg_transaction column to find the average transaction size for each year for retail vs shopify. 
-- Instead we will use sum(sales)/sum(transacations) to calculate the average transaction size.

select 	calendar_year, platform, 
		round(sum(sales)/sum(transactions),2) avg_transaction_size
from clean_weekly_sales
group by calendar_year, platform
order by calendar_year, avg_transaction_size desc;

