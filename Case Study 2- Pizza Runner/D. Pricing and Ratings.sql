set search_path = pizza_runner;

/* If a Meat Lovers pizza costs $12 and Vegetarian costs $10 and there were no charges for changes 
	- how much money has Pizza Runner made so far if there are no delivery fees? */ 
	
select sum(case when pizza_name = 'Meatlovers' then 12 else 10 end) total_revenue
from customer_orders co
join runner_orders ro on ro.order_id = co.order_id and pickup_time <> 'null'
join pizza_names pn on pn.pizza_id = co.pizza_id

	
-- What if there was an additional $1 charge for any pizza extras?

with price as 
(
select 	 
		sum(case when pizza_name = 'Meatlovers' then 12 else 10 end) cost
from customer_orders co
join pizza_names pn on pn.pizza_id = co.pizza_id
join runner_orders ro on ro.order_id = co.order_id and pickup_time <> 'null'
),
add_charges as 
(
select 	order_id,
		customer_id,
		pizza_id,
		trim(regexp_split_to_table(extras,','))::int extras
from customer_orders
where extras not in('null','')

union all 

select order_id,
		customer_id,
		pizza_id,
		replace(extras,'null',null)::int extras
from customer_orders
where extras in('null','')
),
extra_charge as(
select 
		sum(case when extras is null then 0 else 1 end) extra_charges
from add_charges ac
join runner_orders ro on ro.order_id = ac.order_id and pickup_time <> 'null'
left join pizza_toppings pt on pt.topping_id = ac.extras)

select cost + extra_charges total_revenue
from price, extra_charge


-- Add cheese is $1 extra

with price as 
(
select 	 
		sum(case when pizza_name = 'Meatlovers' then 12 else 10 end) cost
from customer_orders co
join pizza_names pn on pn.pizza_id = co.pizza_id
join runner_orders ro on ro.order_id = co.order_id and pickup_time <> 'null'
),

add_charges as 
(
select 	order_id,
		customer_id,
		pizza_id,
		trim(regexp_split_to_table(extras,','))::int extras
from customer_orders
where extras not in('null','')

union all 

select order_id,
		customer_id,
		pizza_id,
		replace(extras,'null',null)::int extras
from customer_orders
where extras in('null','')
),

extra_charge as(
select 
		sum(case when extras is null then 0 
				 when extras = 4 then 2 else 1 end) extra_charges
from add_charges ac
join runner_orders ro on ro.order_id = ac.order_id and pickup_time <> 'null'
left join pizza_toppings pt on pt.topping_id = ac.extras
)

select cost + extra_charges total_revenue
from price, extra_charge;

/* The Pizza Runner team now wants to add an additional ratings system that allows customers to rate their runner, 
	how would you design an additional table for this new dataset - 
	generate a schema for this new table and insert your own data for ratings for each successful customer order between 1 to 5.
	Using your newly generated table - 
	can you join all of the information together to form a table which has the following information for successful deliveries?
		customer_id
		order_id
		runner_id
		rating
		order_time
		pickup_time
		Time between order and pickup
		Delivery duration
		Average speed
		Total number of pizzas */ 
		
-- Rating Table
create table runner_ratings as 
(select order_id, runner_id, (floor(random()*5)+1)::text rating
from runner_orders
where pickup_time <> 'null');


-- Joined All The Information

select 	customer_id,
		co.order_id,
		ro.runner_id,
		ratings,
		order_time,
		pickup_time :: timestamp,
		pickup_time::timestamp - order_time as time_between_order_pickup,
		duration,
		round(avg(regexp_replace(distance, '[^0-9.]+','')::numeric / regexp_replace(duration,'[^0-9]+','')::numeric ),2) avg_speed,
		count(pizza_id) total_pizzas
from customer_orders co
join runner_orders ro on ro.order_id = co.order_id and pickup_time <>'null'
join runner_ratings rs on rs.order_id = co.order_id
group by customer_id,
		co.order_id,
		ro.runner_id,
		ratings,
		order_time,
		pickup_time,
		time_between_order_pickup,
		duration
order by co.order_id, ro.runner_id;

/* If a Meat Lovers pizza was $12 and Vegetarian $10 fixed prices with no cost for extras 
		and each runner is paid $0.30 per kilometre traveled 
		- how much money does Pizza Runner have left over after these deliveries? */ 
		
select 
		sum(case when pizza_id = 1 then 12 else 10 end)  
		- sum(regexp_replace(distance, '[^0-9.]+','')::numeric * 0.30) left_over_money
from customer_orders co
join runner_orders ro on ro.order_id = co.order_id and pickup_time <> 'null'

