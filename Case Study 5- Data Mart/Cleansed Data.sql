set search_path = data_mart;

-- Data Cleansing Step

create table clean_weekly_sales as (
with date_cte as
(select *,to_date(week_date, 'DD MM YY') formatted_date
from weekly_sales)
select  formatted_date as week_date,
		extract (week from formatted_date) week_num,
		extract(month from formatted_date) month_num,
		extract(year from formatted_date) calendar_year,
		region,
		platform,
		case when segment = 'null' then 'Unknown'
			 else segment end segment,
		case when right(segment,1)= '1' then 'Young Adults'
			 when right(segment,1) = '2' then 'Middle Aged'
			 when right(segment,1) in ('3','4') then 'Retirees'
			 else 'Unknown' end age_band,
		case when left(segment,1)= 'C' then 'Couples'
			 when left(segment,1)= 'F' then 'Families'
			 else 'Unknown' end demographic,
		customer_type,
		transactions,
		sales,
		round((sales/transactions),2) avg_transactions
from date_cte
	)
