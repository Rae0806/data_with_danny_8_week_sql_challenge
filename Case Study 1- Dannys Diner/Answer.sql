
-- What is the total amount each customer spent at the restaurant?

select customer_id, sum(price) total_amount_spent
from sales 
join menu on sales.product_id = menu.product_id
group by customer_id
order by customer_id

-- How many days has each customer visited the restaurant?

select customer_id, count(distinct order_date) days_visited
from sales
group by customer_id

-- What was the first item from the menu purchased by each customer?
with ranking as
(
	select *, rank()over(partition by customer_id order by order_date) as rn
	from sales
	join menu on sales.product_id =  menu.product_id
)

	select customer_id, product_name
	from ranking
	where rn = 1;

-- What is the most purchased item on the menu and how many times was it purchased by all customers?

select product_name, count(sales.product_id) purchase_count
from sales 
join menu on menu.product_id = sales.product_id
group by product_name
order by purchase_count desc
limit 1;

-- Which item was the most popular for each customer?
with cust_purchase as 
(
select customer_id, product_name, count(sales.product_id) purchase_count,
		rank()over(partition by customer_id order by count(sales.product_id) desc) as rn
from sales
join menu on menu.product_id = sales.product_id
group by customer_id, product_name

)
select customer_id, product_name
from cust_purchase
where rn = 1;

-- Which item was purchased first by the customer after they became a member?

with order_after_memmbership as(
select s.customer_id, product_name, order_date, join_date,row_number()over(partition by s.customer_id order by order_date) as rn
from sales s
join menu m on s.product_id = m.product_id
join members b on b.customer_id = s.customer_id and join_date < order_date
)
select customer_id, product_name
from order_after_memmbership
where rn = 1;

-- Which item was purchased just before the customer became a member?

with order_before_memmbership as(
select s.customer_id, product_name, order_date, join_date,row_number()over(partition by s.customer_id order by order_date desc) as rn
from sales s
join menu m on s.product_id = m.product_id
join members b on b.customer_id = s.customer_id and join_date < order_date
)
select customer_id, product_name
from order_before_memmbership
where rn = 1;

-- What is the total items and amount spent for each member before they became a member?

select sales.customer_id, count(sales.product_id) total_items,  sum(price) total_amount
from sales
join menu on sales.product_id = menu.product_id
join members on members.customer_id = sales.customer_id and order_date < join_date
group by sales.customer_id

-- If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

select customer_id, sum(case when product_name = 'sushi' then price * 20
						 else price * 10 end) as points
from sales
join menu on sales.product_id = menu.product_id
group by customer_id
order by  customer_id 

-- In the first week after a customer joins the program (including their join date) they earn 2x points on all items, 
--  not just sushi - how many points do customer A and B have at the end of January?

select sales.customer_id, 
	sum(case when order_date between join_date and (join_date + interval '6 days'):: date then price * 20
			 when product_name = 'sushi' then price * 20
			 else price * 10 end) points
from sales
join menu on sales.product_id = menu.product_id and extract(month from order_date) <= 1
join members on members.customer_id = sales.customer_id
group by sales.customer_id;


-- Bonus Questions

-- join all things

select  sales.customer_id, order_date, product_name, price, 
		case when join_date > order_date then 'N'
			 when join_date <= order_date then 'Y'
			 else 'N' end as member
from sales
join menu on sales.product_id = menu.product_id 
left join members on members.customer_id = sales.customer_id
order by sales.customer_id, order_date;


-- rank all things
with joined_all as
(select  sales.customer_id, order_date, product_name, price, 
		case when join_date > order_date then 'N'
			 when join_date <= order_date then 'Y'
			 else 'N' end as member
from sales
join menu on sales.product_id = menu.product_id 
left join members on members.customer_id = sales.customer_id
order by sales.customer_id, order_date
)

select *, case when member = 'Y' then rank()over(partition by customer_id,member order by order_date)
				when member ='N' then null
				end ranking
from joined_all;

