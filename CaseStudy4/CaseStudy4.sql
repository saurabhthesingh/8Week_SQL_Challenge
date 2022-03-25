------------------------------------------
--A. Customer Nodes Exploration
------------------------------------------

--1. How many unique nodes are there on the Data Bank system?
SELECT 
  COUNT(DISTINCT node_id) as unique_nodes
FROM data_bank.customer_nodes 

--2. What is the number of nodes per region?
SELECT 
  r.region_id,
  r.region_name,
  COUNT(node_id) as nodes
FROM data_bank.regions r
JOIN data_bank.customer_nodes n
  ON n.region_id = r.region_id
GROUP BY 1,2
ORDER BY 1

--3. How many customers are allocated to each region?
SELECT 
  r.region_id,
  r.region_name,
  COUNT(customer_id) as customers
FROM data_bank.regions r
JOIN data_bank.customer_nodes n
  ON n.region_id = r.region_id
GROUP BY 1,2
ORDER BY 1

--4. How many days on average are customers reallocated to a different node?
WITH cte as (
  SELECT 
    customer_id, node_id, 
    SUM(end_date - start_date) AS diff
  FROM data_bank.customer_nodes
  WHERE end_date != '9999-12-31'
  GROUP BY customer_id, node_id 
  ORDER BY customer_id, node_id
  )
SELECT 
  ROUND(AVG(diff),2) AS avg_reallocation_days
FROM cte;

--5. What is the median, 80th and 95th percentile for this same reallocation days metric for each region?




