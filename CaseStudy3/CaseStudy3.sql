
--------------------------------
--B. Data Analysis Questions
--------------------------------


--1. How many customers has Foodie-Fi ever had?
SELECT
  COUNT(distinct customer_id) as unique_customers
FROM foodie_fi.subscriptions;

--2. What is the monthly distribution of trial plan start_date values for our dataset - use the start of the month as the group by value
SELECT 
  DATE_PART('month', s.start_date)  month_num,
  TO_CHAR(s.start_date,'MONTH')  month_name,
  COUNT(s.customer_id) as customers
FROM foodie_fi.subscriptions s 
WHERE s.plan_id = 0
GROUP BY 
  DATE_PART('month', s.start_date),
	TO_CHAR(s.start_date,'MONTH');
  
 

--3. What plan start_date values occur after the year 2020 for our dataset? Show the breakdown by count of events for each plan_name
SELECT 
  p.plan_name,
  COUNT(*) as events
FROM foodie_fi.subscriptions s 
JOIN foodie_fi.plans p
  ON s.plan_id = p.plan_id
WHERE s.start_date > '12-31-2020'
GROUP BY p.plan_name,p.plan_id
ORDER BY p.plan_id


--4. What is the customer count and percentage of customers who have churned rounded to 1 decimal place?
SELECT
COUNT(*) as churned,
ROUND(100* COUNT(*) / (SELECT COUNT (Distinct Customer_id) FROM foodie_fi.subscriptions ),1)
FROM foodie_fi.subscriptions
WHERE plan_id = 4

--5. How many customers have churned straight after their initial free trial - what percentage is this rounded to the nearest whole number?
WITH ranking as (
  SELECT 
      s.customer_id,
      s.plan_id,
      p.plan_name,
      RANK() OVER (
              PARTITION BY s.customer_id 
              ORDER BY s.plan_id) as plan_rank
  FROM foodie_fi.subscriptions s
  JOIN foodie_fi.plans p
      ON s.plan_id = p.plan_id
 )
SELECT 
  COUNT(*) as churn_count,
  ROUND(100*COUNT(*) :: NUMERIC/(SELECT COUNT(DISTINCT customer_id) FROM foodie_fi.subscriptions),0) as churn_percentage
FROM ranking
WHERE plan_id = 4 
and plan_rank = 2
    
--6. What is the number and percentage of customer plans after their initial free trial?
WITH next_plan_cte as (
  SELECT 
      customer_id,
      plan_id,
      LEAD(plan_id,1) OVER (
                PARTITION BY customer_id
                ORDER BY plan_id) as next_plan
  FROM foodie_fi.subscriptions
 )
SELECT 
  next_plan,
  COUNT(*) as conversions,
  ROUND(100*COUNT(*) :: NUMERIC/(SELECT COUNT(DISTINCT customer_id) FROM foodie_fi.subscriptions),1) as conv_percentage
FROM next_plan_cte
WHERE next_plan IS NOT NULL
and plan_id = 0
GROUP BY next_plan
ORDER BY next_plan ;
  
  
--7. What is the customer count and percentage breakdown of all 5 plan_name values at 2020-12-31?
--8. How many customers have upgraded to an annual plan in 2020?
--9. How many days on average does it take for a customer to an annual plan from the day they join Foodie-Fi?
--10. Can you further breakdown this average value into 30 day periods (i.e. 0-30 days, 31-60 days etc)
--11. How many customers downgraded from a pro monthly to a basic monthly plan in 2020?
