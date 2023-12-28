set search_path = clique_bait;

select * 
from users
order by user_id;


-- How many users are there?
select count( distinct user_id) unique_users
from users 

-- How many cookies does each user have on average?

with cookie_count as
(
	select user_id, count(cookie_id) cookies_count
	from users
	group by user_id
)
select avg(cookies_count) avg_cookies_count
from cookie_count;


-- What is the unique number of visits by all users per month?

select  
		user_id,
		date_part('month', event_time) month_num,
		count(distinct visit_id) unique_visit
from users u
join events e on u.cookie_id = e.cookie_id
group by user_id, month_num;

-- What is the number of events for each event type?

select user_id, u.cookie_id, start_date, visit_id
from users u
join events e on u.cookie_id = e.cookie_id
order by user_id, start_date

What is the percentage of visits which have a purchase event?
What is the percentage of visits which view the checkout page but do not have a purchase event?
What are the top 3 pages by number of views?
What is the number of views and cart adds for each product category?
What are the top 3 products by purchases?

