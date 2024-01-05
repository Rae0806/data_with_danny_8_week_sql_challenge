set search_path = clique_bait;

select * 
from users
order by user_id;


-- How many users are there?

select count(distinct user_id) total_users
from users;

-- How many cookies does each user have on average?

with cookies as (
select  user_id, count(cookie_id) no_of_cookie
from users
group by user_id
order by user_id
)
select
		 round(avg(no_of_cookie),1) avg_cookies_per_user
from cookies;

-- What is the unique number of visits by all users per month?

select date_part('month', event_time) month_num, count(distinct visit_id) unique_visit
from events e
join users u on e.cookie_id = u.cookie_id
group by month_num


-- What is the number of events for each event type?

select event_type, count(event_type) no_of_events
from events
group by event_type
order by event_type

-- What is the percentage of visits which have a purchase event?

select round(100*sum(case when e.event_type = 3 then 1 else 0 end)::numeric / count(e.event_type),2) purchase_event_percent
from events e
join event_identifier ei on ei.event_type = e.event_type

-- What is the percentage of visits which view the checkout page but do not have a purchase event?

select *
from events

-- What are the top 3 pages by number of views?
-- What is the number of views and cart adds for each product category?
-- What are the top 3 products by purchases?
SELECT 
  100 * COUNT(DISTINCT e.visit_id)/
    (SELECT COUNT(DISTINCT visit_id) FROM clique_bait.events) AS percentage_purchase
FROM clique_bait.events AS e
JOIN clique_bait.event_identifier AS ei
  ON e.event_type = ei.event_type
WHERE ei.event_name = 'Purchase';
