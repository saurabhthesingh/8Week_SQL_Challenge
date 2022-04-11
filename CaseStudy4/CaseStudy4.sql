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







-------------------------
B. Customer Transactions
--------------------------
--1. What is the unique count and total amount for each transaction type?
SELECT 
  t.txn_type,
  COUNT(*) as txn_count,
  SUM(t.txn_amount) as total_amt
FROM data_bank.customer_transactions t

--2. What is the average total historical deposit counts and amounts for all customers?
WITH deposits AS (
  SELECT 
    customer_id, 
    txn_type, 
    COUNT(*) AS txn_count, 
    AVG(txn_amount) AS avg_amount
  FROM data_bank.customer_transactions
  GROUP BY customer_id, txn_type)

SELECT 
  ROUND(AVG(txn_count),0) AS avg_deposit, 
  ROUND(AVG(avg_amount),2) AS avg_amount
FROM deposits
WHERE txn_type = 'deposit';

--3. For each month - how many Data Bank customers make more than 1 deposit and either 1 purchase or 1 withdrawal in a single month?
WITH monthly_txn AS (
  SELECT 
  	customer_id,
    DATE_PART('month', txn_date) AS month,
    SUM(CASE WHEN txn_type = 'deposit' THEN 0 ELSE 1 END) AS deposit_count,
    SUM(CASE WHEN txn_type = 'purchase' THEN 0 ELSE 1 END) AS purchase_count,
    SUM(CASE WHEN txn_type = 'withdrawal' THEN 0 ELSE 1 END) AS withdrawal_count
  FROM data_bank.customer_transactions
  GROUP BY customer_id, month
 )

SELECT
  month,
  COUNT(DISTINCT customer_id) AS customer_count
FROM monthly_txn
WHERE deposit_count > 1 
  AND (purchase_count > 1 OR withdrawal_count > 1)
GROUP BY month
ORDER BY month;

--4. What is the closing balance for each customer at the end of the month?
with temp as (
  SELECT 
	customer_id,
	TO_CHAR((DATE_TRUNC('month', txn_date) + INTERVAL '1 MONTH - 1 DAY'),'DD/MM/YYYY') AS month_ends,
  -- TO_CHAR(closing_month, 'DD/MM/YYYY') as month_ends,
     SUM(CASE WHEN txn_type = 'deposit' then txn_amount
     	ELSE (-txn_amount)
     END) AS txn_balance
  FROM data_bank.customer_transactions
  GROUP BY 1,2 )
 
 SELECT 
customer_id,
month_ends,
txn_balance,
SUM(txn_balance) OVER 
      (PARTITION BY customer_id ORDER BY month_ends
      ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS closing_balance
FROM temp
GROUP BY 1,2,3
ORDER BY customer_id
ORDER BY customer_id,month_ends

--5. What is the percentage of customers who increase their closing balance by more than 5%?
with temp as
(
  SELECT 
	customer_id,
	TO_CHAR((DATE_TRUNC('month', txn_date) + INTERVAL '1 MONTH - 1 DAY'),'DD/MM/YYYY') AS month_ends,
     SUM(CASE WHEN txn_type = 'deposit' then txn_amount
     	ELSE (-txn_amount)
     END) AS txn_balance
  FROM data_bank.customer_transactions
  GROUP BY 1,2 
)
,
balance as 
( 
SELECT 
customer_id,
month_ends,
txn_balance,
SUM(txn_balance) OVER 
      (PARTITION BY customer_id ORDER BY month_ends
      ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS closing_balance
FROM temp
GROUP BY 1,2,3
)
,
next_balance as (
SELECT 
customer_id,
month_ends,
closing_balance,
LEAD (closing_balance) OVER
	(PARTITION BY customer_id ORDER BY month_ends) AS next_bal,
LEAD (closing_balance) OVER
	(PARTITION BY customer_id ORDER BY month_ends) - closing_balance AS diff  
FROM balance
GROUP BY 1,2,3
)
 ,
last as(
SELECT
customer_id,
month_ends,
closing_balance,
next_bal,
ROUND(100*(next_bal - closing_balance)/ closing_balance::NUMERIC,2) AS change 
FROM next_balance
where next_bal::TEXT NOT LIKE '-%'
GROUP BY 1,2,3,4,5
HAVING  ROUND(100*(next_bal - closing_balance)/ closing_balance::NUMERIC,2) > 5
ORDER BY 1,2
)

select 
ROUND (100*count(*)  / 
	(SELECT COUNT(DISTINCT customer_id::NUMERIC)
    FROM temp),2)
from last
