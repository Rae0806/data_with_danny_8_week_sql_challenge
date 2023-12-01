set search_path = data_mart;

/* 
This technique is usually used when we inspect an important event and 
want to inspect the impact before and after a certain point in time.

Taking the week_date value of 2020-06-15 as the baseline week 
where the Data Mart sustainable packaging changes came into effect.

We would include all week_date values for 2020-06-15 as the start of the period after the change 
and the previous week_date values would be before

Using this analysis approach - answer the following questions:
*/
with before_change as
(select *
from clean_weekly_sales
where week_date < '2020-06-15'
),

after_change as (
select *
from clean_weekly_sales
where week_date >= '2020-06-15')


-- What is the total sales for the 4 weeks before and after 2020-06-15? What is the growth or reduction rate in actual values and percentage of sales?

with cte as 
(select 
	sum(case when week_date between date '2020-06-15' - interval '4 week' and date '2020-06-15' then sales end):: numeric before_4_weeks,
	sum(case when week_date between date '2020-06-15' and date '2020-06-15' + interval '4 week' then sales end):: numeric after_4_weeks
from clean_weekly_sales
where date_part('year',week_date) = 2020)

select * , ((after_4_weeks - before_4_weeks)/before_4_weeks)*100 percent_change
from cte


-- What about the entire 12 weeks before and after?


with cte as 
(select 
	sum(case when week_date between date '2020-06-15' - interval '12 week' and date '2020-06-15' then sales end):: numeric before_12_weeks,
	sum(case when week_date between date '2020-06-15' and date '2020-06-15' + interval '12 week' then sales end):: numeric after_12_weeks
from clean_weekly_sales
where date_part('year',week_date) = 2020)
select * , ((after_12_weeks - before_12_weeks)/before_12_weeks)*100 percent_change
from cte


-- How do the sale metrics for these 2 periods before and after compare with the previous years in 2018 and 2019? 
-- for 4 week period
with cte as
(select *, (select extract(week from '2020-06-15'::date)) as week_number
from clean_weekly_sales
),

yearly_sales as 
(select calendar_year, 
		sum(case when week_num between week_number - 3 and week_number - 1 then sales end) :: numeric before_sales,
		sum(case when week_num between week_number and week_number + 4 then sales end):: numeric after_sales
from cte
group by calendar_year
)

select calendar_year, before_sales, after_sales,
		(after_sales - before_sales) / before_sales *100 percent_change
from yearly_sales

-- 12 week_period
with cte as
(select *, (select extract(week from '2020-06-15'::date)) as week_number
from clean_weekly_sales
),

yearly_sales as 
(select calendar_year, 
		sum(case when week_num between week_number - 11 and week_number - 1 then sales end) :: numeric before_sales,
		sum(case when week_num between week_number and week_number + 12 then sales end):: numeric after_sales
from cte
group by calendar_year
)

select calendar_year, before_sales, after_sales,
		(after_sales - before_sales) / before_sales *100 percent_change
from yearly_sales
