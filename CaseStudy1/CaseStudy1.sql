--8 Week Sql Challenge

--Case Study #1 - Danny's Diner

--1. What is the total amount each customer spent at the restaurant?
SELECT 
customer_id,
sum(price) as total_amt
FROM sales s
inner join menu m 
on s.product_id = m.product_id
GROUP BY customer_id ;


--2. How many days has each customer visited the restaurant?
SELECT 
s.customer_id,
count(distinct s.order_date) as days
FROM sales s
GROUP BY customer_id ;


--3. What was the first item from the menu purchased by each customer?
with cte_ranked as 
(
SELECT 
s.customer_id,
s.order_date,
m.product_name,
RANK OVER() (PARTITION BY s.customer_id ORDER BY s.order_date) AS ranking
FROM sales s
INNER JOIN menu m 
on s.product_id = m.product_id
)
SELECT 
customer_id,
product_name
FROM cte_ranked 
where ranking = 1
group by customer_id,product_name ;


--4. What is the most purchased item on the menu and how many times was it purchased by all customers?
WITH cte_ranked as 
(
SELECT
m.product_name,
COUNT(m.product_id) as total_qty,
RANK OVER()  AS ranking
FROM  menu 
GROUP BY m.product_name
)
SELECT 
product_name,
total_qty
FROM cte_ranked 
where ranking = 1


-- 5. Which item was the most popular for each customer?
WITH cte_ranked as 
(
SELECT
s.customer_id,
m.product_name,
COUNT(m.product_id) as total_qty,
RANK OVER() (PARTITION BY s.customer_id ORDER BY total_qty) AS ranking
FROM sales s
INNER JOIN menu m 
on s.product_id = m.product_id
GROUP BY s.customer_id,m.product_name
)
SELECT 
customer_id,
product_name,
total_qty
FROM cte_ranked 
where ranking = 1

--6. Which item was purchased first by the customer after they became a member?
WITH cte_ranked as 
(
SELECT
customer_id,
product_name,
order_date,
RANK OVER() (PARTITION BY s.customer_id ORDER BY s.order_date) AS ranking
FROM sales 
INNER JOIN members on customer_id = customer_id
INNER JOIN menu on product_id = product_id
where order_date >= join_date
)
SELECT
customer_id,
product_name
FROM cte_ranked 
where ranking= 1

--7. Which item was purchased just before the customer became a member?
WITH cte_ranked as 
(
SELECT
customer_id,
product_name,
order_date,
RANK OVER() (PARTITION BY s.customer_id ORDER BY s.order_date) AS ranking
FROM sales 
INNER JOIN members on customer_id = customer_id
INNER JOIN menu on product_id = product_id
where order_date < join_date
)
SELECT
customer_id,
product_name
FROM cte_ranked 
where ranking= 1

--8. What is the total items and amount spent for each member before they became a member?
SELECT
customer_id,
count(product_name) as total_qty,
sum(price) as total_amt
where order_date < join_date
FROM sales 
INNER JOIN members on customer_id = customer_id
INNER JOIN menu on product_id = product_id
GROUP BY customer_id

--9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
with cte_points (
SELECT 
* ,
case when product_id = 1 then price*20 else price*10 
end as points
FROM sales
INNER JOIN menu on product_id = product_id
)
select 
customer_id,
SUM(points) as total_points
from cte_points 
Group by customer_id

--10.In the first week after a customer joins the program (including their join date) they earn 2x points on all items, 
not just sushi - how many points do customer A and B have at the end of January?
