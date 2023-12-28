set search_path = pizza_runner;


-- What are the standard ingredients for each pizza?

with cte as 
(select 
	trim(unnest(string_to_array(toppings, ',')))::int toppings,
 	count(*) toppings_count
from pizza_recipes pr
group by trim(unnest(string_to_array(toppings, ',')))::int 
)

select topping_name
from cte 
join pizza_toppings pt
on cte.toppings = pt.topping_id
where toppings_count > 1

 




-- What was the most commonly added extra?
with added_extras as
(select 
		trim(unnest(string_to_array(extras, ','))) ::int extras,
		count(*) extras_count
from customer_orders co
where extras not in ('null', '')
group by trim(unnest(string_to_array(extras, ','))) ::int
order by extras_count desc
limit 1
)

select topping_name most_added_extra
from added_extras 
join pizza_toppings pt
on pt.topping_id = added_extras.extras


-- What was the most common exclusion?

with common_exclusion as
(SELECT TRIM(UNNEST(STRING_TO_ARRAY(EXCLUSIONS,','))):: int EXCLUSION,
	COUNT(*) EXCLUSION_COUNT
FROM CUSTOMER_ORDERS
WHERE EXCLUSIONS NOT IN('null','')
GROUP BY TRIM(UNNEST(STRING_TO_ARRAY(EXCLUSIONS,','))):: int
 )
SELECT TOPPING_NAME
FROM COMMON_EXCLUSION CE
JOIN PIZZA_TOPPINGS PT ON PT.TOPPING_ID = CE.EXCLUSION
WHERE EXCLUSION_COUNT > 1
ORDER BY EXCLUSION_COUNT DESC
LIMIT 1;

/* Generate an order item for each record in the customers_orders table in the format of one of the following:
	Meat Lovers
	Meat Lovers - Exclude Beef
	Meat Lovers - Extra Bacon
	Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers */
	
	
	
with extras as
(
select 
		order_id,
		pizza_id,
		trim(regexp_split_to_table(extras, ','))::int extra
from customer_orders co
where extras not in('null','')
),

added_extras as 
(
select 	order_id,
		pizza_id,
		' - Extra ' || string_agg(topping_name,', ') added_extra
from extras
join pizza_toppings pt on extras.extra = pt.topping_id
group by order_id, pizza_id
),

exclusions as
(
select 
		order_id,
		pizza_id,
		trim(regexp_split_to_table(exclusions, ',')):: int exclusion
from customer_orders co
where exclusions not in('null','')
),

excluded as
(
select 	order_id,
		pizza_id,
		' - Exclude ' || string_agg(distinct topping_name,', ') excluded
from exclusions
join pizza_toppings pt on exclusions.exclusion = pt.topping_id
group by order_id, pizza_id
)


select 	distinct co.order_id,
		concat(case when pizza_name = 'Meatlovers' then 'Meat Lovers' else pizza_name end, '',
		coalesce(added_extra,'') ,'',
		coalesce(excluded,'') ) order_item
from customer_orders co
left join added_extras ae on co.order_id=ae.order_id and co.pizza_id = ae.pizza_id 
left join excluded ed on co.order_id = ed.order_id and co.pizza_id = ed.pizza_id
join pizza_names pn on pn.pizza_id = co.pizza_id
	
	
	
/* Generate an alphabetically ordered comma separated ingredient list for each pizza order from the customer_orders table 
	and add a 2x in front of any relevant ingredients
For example: "Meat Lovers: 2xBacon, Beef, ... , Salami" */

with extras as
(
select 
		order_id,
		pizza_id,
		trim(regexp_split_to_table(extras, ','))::int extra
from customer_orders co
where extras not in('null','')
),
added_extras as
(
select 	order_id,
		pizza_id,
		topping_id,
		topping_name added_extra
from extras
join pizza_toppings pt on extras.extra = pt.topping_id
),
exclusions as
(
select 
		order_id,
		pizza_id,
		trim(regexp_split_to_table(exclusions, ',')):: int exclusion
from customer_orders co
where exclusions not in('null','')
),
excluded as 
(select 	order_id,
		pizza_id,
		topping_id,
		topping_name excluded
from exclusions
join pizza_toppings pt on exclusions.exclusion = pt.topping_id
),
orders as
(
select 	co.order_id,
		co.pizza_id,
		trim(regexp_split_to_table(toppings, ','))::int toppings
from customer_orders co 
join pizza_recipes pr on co.pizza_id = pr.pizza_id
),
ingredient as
(select o.order_id,
		o.pizza_id,
		toppings topping_id,
		topping_name
from orders o
left join excluded exc on exc.order_id = o.order_id and exc.pizza_id = o.pizza_id and exc.topping_id = o.toppings
join pizza_toppings pt on pt.topping_id = o.toppings
where exc.excluded is null

union all

select order_id,
		pizza_id,
		topping_id,
		added_extra topping_name
from added_extras
),
order_with_extras_exclusions as 
(
select 	order_id,
		pizza_name,
		topping_name,
		count(topping_id) n
from ingredient i
join pizza_names pn on pn.pizza_id = i.pizza_id
group by order_id, pizza_name, topping_name
)		
select 	order_id,
		concat(case when pizza_name = 'Meatlovers' then 'Meat Lovers' else pizza_name end, ': ',
		string_agg(case when n >1 then n || 'X '|| topping_name else topping_name end, ', ') )
from order_with_extras_exclusions 
group by order_id,pizza_name


-- What is the total quantity of each ingredient used in all delivered pizzas sorted by most frequent first?
with extras as 
(select order_id,
		pizza_id,
		trim(regexp_split_to_table(extras, ','))::int extra
from customer_orders
where extras not in ('null','')
),

exclusions as 
(
select 	order_id,
		pizza_id,
		trim(regexp_split_to_table(exclusions, ','))::int exclusion
from customer_orders
where exclusions not in ('null','')
),
orders as
(
select 	order_id,
		co.pizza_id,
		trim(regexp_split_to_table(toppings, ','))::int toppings
from customer_orders co
join pizza_recipes pr on co.pizza_id = pr.pizza_id
),
orders_with_extras_exclusions as
(select 	o.order_id,
		o.pizza_id,
		toppings topping_id
from orders o
left join exclusions exc on exc.order_id = o.order_id and exc.pizza_id = o.pizza_id and exc.exclusion = o.toppings
where exclusion is null

union all

select order_id,
		pizza_id,
		extra topping_id
from extras 
)		
select 
		topping_name,
		count(ow.topping_id) n
from orders_with_extras_exclusions ow
join runner_orders ro on ow.order_id = ro.order_id
join pizza_toppings pt on pt.topping_id = ow.topping_id
where pickup_time <> 'null'
group by topping_name
order by count(ow.topping_id) desc



