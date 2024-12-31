-- Schema SQL Query SQL ResultsEdit on DB Fiddle
-- Example Query:
-- SELECT
-- 	runners.runner_id,
--     runners.registration_date,
-- 	COUNT(DISTINCT runner_orders.order_id) AS orders
-- FROM pizza_runner.runners
-- INNER JOIN pizza_runner.runner_orders
-- 	ON runners.runner_id = runner_orders.runner_id
-- WHERE runner_orders.cancellation IS NOT NULL
-- GROUP BY
-- 	runners.runner_id,
--     runners.registration_date;


-- A. Pizza Metrics
-- How many pizzas were ordered?
-- How many unique customer orders were made?
-- How many successful orders were delivered by each runner?
-- How many of each type of pizza was delivered?
-- How many Vegetarian and Meatlovers were ordered by each customer?
-- What was the maximum number of pizzas delivered in a single order?
-- For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
-- How many pizzas were delivered that had both exclusions and extras?
-- What was the total volume of pizzas ordered for each hour of the day?
-- What was the volume of orders for each day of the week?



-- cleaning customer_order table
-- select *,
-- case
-- 	when exclusions like '' then NULL
--     else exclusions
-- end as exclusions_updated,
-- case
-- 	when extras like '' then NULL
--     else extras
-- end as extras_updated
-- from customer_orders;

UPDATE customer_orders
SET exclusions = NULL
WHERE exclusions = '';

UPDATE customer_orders
SET extras = NULL
WHERE extras = '';

-- SELECT *
-- FROM customer_orders;


-- 1
select count(order_id) as total_no_of_pizzas_ordered
from customer_orders;

-- 2
SELECT COUNT(*) AS unique_cust_order_pair
FROM (SELECT DISTINCT customer_id, order_id
      FROM customer_orders) AS distinct_pairs;
      
-- cleaning runner_orders
UPDATE runner_orders
SET cancellation = NULL
WHERE cancellation = '';

UPDATE runner_orders
SET cancellation = NULL
WHERE cancellation = 'null';

-- 3
select runner_id, count(order_id) as total_successful_orders
from runner_orders
where cancellation IS NULL
group by runner_id;

-- 4
select pizzaname, count(*)
from
(select co.order_id as orderid, pn.pizza_id as pizzaid, pn.pizza_name as pizzaname
from runner_orders as ro
join customer_orders as co
on ro.order_id = co.order_id
join pizza_names as pn
on co.pizza_id = pn.pizza_id
where cancellation is null) as filtering
group by pizzaname;

-- 5
select pizzaname, count(*)
from
(select co.order_id as orderid, pn.pizza_id as pizzaid, pn.pizza_name as pizzaname
from runner_orders as ro
join customer_orders as co
on ro.order_id = co.order_id
join pizza_names as pn
on co.pizza_id = pn.pizza_id) as filtering
group by pizzaname;

-- 6
select order_id, count(*) as number_of_pizzas_in_single_order
from customer_orders
group by order_id
order by number_of_pizzas_in_single_order desc
limit 1;

-- 7
SELECT 
    customerid, 
    COUNT(CASE WHEN excl_ch = 'change' or extr_ch = 'change' THEN 1 END) AS pizzas_with_changes,
    COUNT(CASE WHEN excl_ch = 'no_change' and extr_ch = 'no_change' THEN 1 END) AS  pizzas_without_changes
FROM (
    SELECT 
        co.customer_id AS customerid,
        co.order_id AS orderid,
        pn.pizza_name AS pizzaname,
        CASE
            WHEN co.exclusions IS NOT NULL THEN 'change'
            ELSE 'no_change'
        END AS excl_ch,
        CASE
            WHEN co.extras IS NOT NULL THEN 'change'
            ELSE 'no_change'
        END AS extr_ch
    FROM runner_orders AS ro
    JOIN customer_orders AS co
        ON ro.order_id = co.order_id
    JOIN pizza_names AS pn
        ON co.pizza_id = pn.pizza_id
    WHERE ro.cancellation IS NULL
) AS filtering
GROUP BY customerid
order by customerid;

-- 8

-- 9
select count(*) as total_count, EXTRACT(HOUR FROM order_time) AS orderhour
FROM customer_orders
group by orderhour
order by orderhour;

-- 10
SELECT 
    EXTRACT(DOW FROM order_time) AS day_of_week,  -- Returns 0 for Sunday, 1 for Monday, ..., 6 for Saturday
    COUNT(*) AS total_orders
FROM customer_orders
GROUP BY day_of_week
ORDER BY day_of_week;
