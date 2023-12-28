set search_path = pizza_runner;

-- How many pizzas were ordered?

select count(pizza_id) total_pizzas_ordered
from customer_orders;


-- How many unique customer orders were made?
select count(distinct order_id) unique_orders
from customer_orders;

-- How many successful orders were delivered by each runner?
select runner_id, count(*) orders_deliever
from runner_orders
where pickup_time != 'null'
group by runner_id
order by orders_deliever desc;

-- How many of each type of pizza was delivered?

select pizza_id, count(*) pizzas_delievered
from customer_orders co
join runner_orders ro 
on co.order_id = ro.order_id
where pickup_time <> 'null'
group by pizza_id
order by pizzas_delievered desc;


-- How many Vegetarian and Meatlovers were ordered by each customer?

select customer_id, 
		sum(case when pizza_name = 'Vegetarian' then 1 else 0 end) Vegetarian,
		sum(case when pizza_name = 'Meatlovers' then 1 else 0 end) Meatlovers
from customer_orders co
join pizza_names pn 
on co.pizza_id = pn.pizza_id 
group by customer_id
order by customer_id;


-- What was the maximum number of pizzas delivered in a single order?

select order_id, count(pizza_id) pizzas_ordered
from customer_orders 
group by order_id
order by pizzas_ordered desc
limit 1;

-- For each customer, how many delivered pizzas had at least 1 change and how many had no changes?

select customer_id, 
		sum(case when (exclusions not in ('null', '') or exclusions <> null)
				  or (extras not in ('null', '') or extras <> null) then 1 else 0 end) changed,
		sum(case when (exclusions  in ('null', '') or exclusions = null)
				  and (extras in ('null', '') or extras = null) then 1 else 0 end) not_changed
from customer_orders co
join runner_orders ro 
on co.order_id = ro.order_id and pickup_time <> 'null'
group by customer_id
;

-- How many pizzas were delivered that had both exclusions and extras?

select count(pizza_id) Pizza_count
from customer_orders co
join runner_orders ro 
on co.order_id = ro.order_id and pickup_time <> 'null'
where (exclusions not in ('null', '') or exclusions <> null)
		and (extras not in ('null','') or extras <> null);


-- What was the total volume of pizzas ordered for each hour of the day?

select extract(hour from order_time) day_hour,
		count(pizza_id) pizza_count
from customer_orders
group by day_hour
order by day_hour;


-- What was the volume of orders for each day of the week?

select extract(dow from order_time) day_of_week,
		count(pizza_id) pizza_count
from customer_orders
group by day_of_week
order by day_of_week;