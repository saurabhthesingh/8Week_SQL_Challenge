--A. Pizza Metrics
--1. How many pizzas were ordered?
SELECT 
  COUNT(pizza_id)
FROM customer_orders ;

--2. How many unique customer orders were made?
SELECT 
  COUNT(DISTINCT order_id)
FROM customer_orders ;

--3. How many successful orders were delivered by each runner?
SELECT
  runner_id,
  COUNT(order_id) 
  WHERE distance != 0
FROM runner_orders ;

--4. How many of each type of pizza was delivered?
SELECT 
  pizza_id,
  COUNT(order_id)
  WHERE distance != 0
FROM customer_orders ;

--5. How many Vegetarian and Meatlovers were ordered by each customer?
SELECT 
  customer_id,
  pizza_name,
  COUNT(order_id) 
FROM customer_orders
JOIN pizza_names 
  ON customer_orders.pizza_id = pizza_names.pizza_id
GROUP BY  pizza_id,pizza_name ;

--6. What was the maximum number of pizzas delivered in a single order?
WITH orders as
(
  SELECT 
    c.order_id,
    COUNT(c.pizza_id) as pizzas_ordered
  WHERE r.distance != 0
    AND r.pickup_time != 0
    AND r.duration != 0
  FROM customer_orders c
  JOIN runner_orders r
    ON c.order_id = r.order_id
 )
SELECT
  MAX(pizzas_ordered) as max_pizzas
FROM orders ;

--7. For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
SELECT 
  c.customer_id,
  SUM(CASE WHEN c.exclusions <> ' ' or c.extras <> ' ' THEN 1
       ELSE 0
       END ) as atleast_1_change,
  SUM(CASE WHEN c.exclusions <> ' ' and c.extras <> ' ' THEN 1
       ELSE 0
       END ) as no_change,
FROM customer_orders c
JOIN runner_orders r
   ON c.order_id = r.order_id
WHERE r.distance != 0
  AND r.pickup_time != 0
  AND r.duration != 0
GROUP BY c.customer_id
ORDER BY c.customer_id ;

--8. How many pizzas were delivered that had both exclusions and extras?
SELECT 
  SUM(CASE WHEN c.exclusions is not null and c.extras is not null THEN 1
       ELSE 0
       END ) as both,
FROM customer_orders c
JOIN runner_orders r
   ON c.order_id = r.order_id
WHERE r.distance != 0
  AND r.pickup_time != 0
  AND r.duration != 0 
  AND r.c.exclusions <> ' '
  AND c.extras <> ' ' ;
  
--9. What was the total volume of pizzas ordered for each hour of the day?
SELECT 
  DATEPART('HOUR',order_date) AS hour_of_day,
  COUNT(order_id) as pizzas_ordered
FROM customer_orders
GROUP BY 1,
ORDER BY 1 ;

--10. What was the volume of orders for each day of the week?
