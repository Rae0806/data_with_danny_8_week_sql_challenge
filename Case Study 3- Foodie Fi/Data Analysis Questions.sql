
-- How many customers has Foodie-Fi ever had?

SELECT COUNT(distinct customer_id) total_customer
FROM subscriptions ;

-- What is the monthly distribution of trial plan start_date values for our dataset - use the start of the month as the group by value

SELECT  DATEPART(MONTH, start_date) month_num,  
        COUNT(s.plan_id) monthly_distribution
FROM subscriptions s
JOIN plans p 
ON s.plan_id = p.plan_id AND plan_name = 'trial'
GROUP BY DATEPART(MONTH, start_date); 

-- What plan start_date values occur after the year 2020 for our dataset? Show the breakdown by count of events for each plan_name

SELECT plan_name, COUNT(s.plan_id) event_count
FROM subscriptions s
JOIN plans p 
ON s.plan_id = p.plan_id AND DATEPART(YEAR,start_date)> 2020
GROUP BY plan_name;

-- What is the customer count and percentage of customers who have churned rounded to 1 decimal place?

SELECT COUNT(DISTINCT customer_id) cust_count, 
        round(100 * cast(COUNT(DISTINCT customer_id) as float)  / (SELECT COUNT(distinct customer_id) FROM subscriptions ),1) cust_percent
FROM subscriptions s 
JOIN plans p 
ON s.plan_id = p.plan_id and plan_name = 'churn'


-- How many customers have churned straight after their initial free trial - what percentage is this rounded to the nearest whole number?

WITH cte AS 
(SELECT customer_id, start_date, plan_name, LEAD(plan_name) OVER(PARTITION by customer_id order by start_date) next_plan
FROM subscriptions s 
JOIN plans p 
ON s.plan_id = p.plan_id)

SELECT  SUM(case when plan_name = 'trial' and next_plan = 'churn' then 1 else 0 end) cust_count,
        floor(cast(100 * SUM(case when plan_name = 'trial' and next_plan = 'churn' then 1 else 0 end) as numeric) / (SELECT  count(distinct customer_id) FROM subscriptions)) cust_percent
from cte;

-- What is the number and percentage of customer plans after their initial free trial?

WITH ranking AS
(
SELECT customer_id, start_date, plan_name, RANK()OVER(PARTITION BY customer_id ORDER BY start_date) AS rn
FROM subscriptions s
JOIN plans p 
ON s.plan_id = p.plan_id)

SELECT  plan_name, 
        COUNT(plan_name) cust_count_after_trial, 
        100 * cast(COUNT(plan_name) AS float) / (SELECT COUNT(*) FROM ranking WHERE rn = 2) cust_percent_after_trial
FROM ranking
WHERE rn = 2
GROUP BY plan_name;


-- What is the customer count and percentage breakdown of all 5 plan_name values at 2020-12-31?

SELECT  plan_name, 
        COUNT(plan_name) cust_count_2020,
        ROUND(100.0 * COUNT(plan_name) / (SELECT COUNT(*) FROM subscriptions WHERE start_date <= '2020-12-31'),2) cust_percent_2020
FROM subscriptions s
JOIN plans p
ON s.plan_id = p.plan_id and start_date <= '2020-12-31'
GROUP BY plan_name;

-- How many customers have upgraded to an annual plan in 2020?

SELECT SUM(CASE WHEN s.plan_id = 3 THEN 1 ELSE 0 END ) cust_count
FROM subscriptions s
JOIN plans p 
ON s.plan_id = p.plan_id
WHERE DATEPART(YEAR,start_date) = 2020;


-- How many days on average does it take for a customer to an annual plan from the day they join Foodie-Fi?

WITH trial_plan AS
(
SELECT  customer_id,
        start_date 
FROM subscriptions
WHERE plan_id = 0
),
annual_plan AS
(
SELECT  customer_id,
        start_date annual_plan_date
FROM subscriptions 
WHERE plan_id = 3
)

SELECT AVG(coalesce(DATEDIFF(DAY,start_date,annual_plan_date),0)) avg_days_for_annual_plans
FROM trial_plan tp
LEFT JOIN annual_plan ap 
ON tp.customer_id = ap.customer_id;

-- Can you further breakdown this average value into 30 day periods (i.e. 0-30 days, 31-60 days etc)

WITH trial_plan AS
(
SELECT  customer_id,
        start_date 
FROM subscriptions
WHERE plan_id = 0
),
annual_plan AS
(
SELECT  customer_id,
        start_date annual_plan_date
FROM subscriptions 
WHERE plan_id = 3
)

SELECT 
        CONCAT((DATEDIFF(DAY,start_date,annual_plan_date)/30)*30, '-', (DATEDIFF(DAY,start_date,annual_plan_date)/30)*30 + 30 , ' days') days_period,
        COUNT(tp.customer_id) cust_count
FROM trial_plan tp
JOIN annual_plan ap 
ON tp.customer_id = ap.customer_id
GROUP BY DATEDIFF(DAY,start_date,annual_plan_date)/30;

-- How many customers downgraded from a pro monthly to a basic monthly plan in 2020? 

WITH basic_monthly AS
(
SELECT customer_id,
        start_date basic_start
FROM subscriptions
WHERE plan_id = 1 and DATEPART(YEAR,start_date) = 2020
),

pro_monthly AS
(
SELECT customer_id,
        start_date pro_start
FROM subscriptions
WHERE plan_id = 2 AND DATEPART(YEAR,start_date) = 2020
)

SELECT COUNT(*) cust_count
FROM basic_monthly b
JOIN pro_monthly p 
ON b.customer_id = p.customer_id
AND basic_start > pro_start;