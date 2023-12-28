set search_path = pizza_runner;

-- How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)

select
		cast(date_trunc('week', registration_date) + interval '4 days' as date) week_period,
		count(runner_id) runner_count
from runners
group by date_trunc('week', registration_date) + interval '4 days' ;

-- What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?

select 	ro.runner_id,  
		extract(minute from avg(pickup_time :: timestamp  - order_time )) avg_time
from customer_orders co
join runner_orders ro
on co.order_id = ro.order_id and pickup_time <> 'null'
group by ro.runner_id;


--Is there any relationship between the number of pizzas and how long the order takes to prepare?

with preparation_time as 
(select 
		count(pizza_id) no_of_pizzas,
		max(pickup_time :: timestamp - order_time) prep_time
from customer_orders co
join runner_orders ro
on co.order_id = ro.order_id and pickup_time <> 'null'
group by co.order_id)

select no_of_pizzas,
		cast(avg(prep_time) as time) avg_prep_time
from preparation_time
group by no_of_pizzas
order by no_of_pizzas;

-- What was the average distance travelled for each customer?

select customer_id, round(avg(replace(distance, 'km', ' '):: numeric),2) avg_distance_travelled
from runner_orders ro
join customer_orders co
on co.order_id = ro.order_id and pickup_time <> 'null'
group by customer_id;


-- What was the difference between the longest and shortest delivery times for all orders?

select 	
		max(regexp_replace(duration, '[^0-9]+',''):: int) - min(regexp_replace(duration, '[^0-9]+',''):: int) time_diff
from runner_orders 
where duration <> 'null';

--What was the average speed for each runner for each delivery and do you notice any trend for these values?

select 	runner_id,
		order_id,
		max(replace(distance, 'km',' ')::numeric(3,1) / regexp_replace(duration, '[^0-9]+',''):: numeric(3,1))::numeric(3,2) speed
from runner_orders
where pickup_time <> 'null'
group by runner_id,
		 order_id
order by runner_id,
		 order_id

-- What is the successful delivery percentage for each runner?

select runner_id, 
		round(sum(case when pickup_time <> 'null' then 1
		else 0 end) / count(order_id):: numeric,2)* 100 succesful_delivery_percentage
from runner_orders
group by runner_id
order by runner_id;


