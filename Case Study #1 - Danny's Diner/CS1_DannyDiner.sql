/* --------------------
   Case Study Questions
   --------------------*/

-- 1. What is the total amount each customer spent at the restaurant?
-- 2. How many days has each customer visited the restaurant?
-- 3. What was the first item from the menu purchased by each customer?
-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
-- 5. Which item was the most popular for each customer?
-- 6. Which item was purchased first by the customer after they became a member?
-- 7. Which item was purchased just before the customer became a member?
-- 8. What is the total items and amount spent for each member before they became a member?
-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

-- Example Query:
-- SELECT
--   	product_id,
--     product_name,
--     price
-- FROM dannys_diner.menu
-- ORDER BY price DESC
-- LIMIT 5;

-- 1
select s.customer_id, sum(price) as total_amount
from sales as s
join menu as m
on s.product_id = m.product_id
group by s.customer_id
order by total_amount desc;

-- 2
select s.customer_id, count(distinct s.order_date) as no_of_days_visited_distinct
from sales as s
join menu as m
on s.product_id = m.product_id
group by s.customer_id
order by no_of_days_visited_distinct desc;

-- 3
with first_purchased_items as (select s.customer_id as customer, s.product_id as pro,
row_number() over(partition by s.customer_id order by s.order_date, s.product_id) as first_purchased_item
from sales as s
join menu as m
on s.product_id = m.product_id)

select customer, pro
from first_purchased_items
where first_purchased_item = 1;

-- 4
select product_name, total_orders
from (select s.product_id, m.product_name, count(s.product_id) as total_orders
from menu as m
join sales as s
on m.product_id = s.product_id
group by s.product_id, m.product_name 
order by total_orders desc) as subquery;

-- 5
WITH product_counts AS (
    SELECT 
        s.customer_id, 
        m.product_name, 
        COUNT(s.product_id) AS pro_count
    FROM sales AS s
    JOIN menu AS m ON s.product_id = m.product_id
    GROUP BY s.customer_id, m.product_name
)
SELECT 
    customer_id, 
    product_name, 
    pro_count, 
    ranking
FROM (
    SELECT 
        customer_id, 
        product_name, 
        pro_count, 
        RANK() OVER (PARTITION BY customer_id ORDER BY pro_count DESC) AS ranking
    FROM product_counts
) AS ranked_products
WHERE ranking = 1;

-- 6
WITH tab AS (
    SELECT 
        mem.customer_id AS customerid, 
        s.product_id AS productid, 
        m.product_name AS productname, 
        s.order_date AS orderdate, 
        mem.join_date AS joindate
    FROM 
        sales AS s
    JOIN 
        menu AS m
    ON 
        s.product_id = m.product_id
    JOIN 
        members AS mem
    ON 
        mem.customer_id = s.customer_id
    WHERE 
        s.order_date >= mem.join_date
),
ranked_orders AS (
    SELECT 
        customerid, 
        productid, 
        productname, 
        orderdate, 
        joindate,
        ROW_NUMBER() OVER (PARTITION BY customerid ORDER BY orderdate ASC) AS rnk
    FROM 
        tab
)
SELECT 
    customerid, 
    orderdate AS first_order_after_member, 
    productid, 
    productname, 
    joindate
FROM 
    ranked_orders
WHERE 
    rnk = 1
ORDER BY 
    customerid;

-- 7
WITH tab AS (
    SELECT 
        mem.customer_id AS customerid, 
        s.product_id AS productid, 
        m.product_name AS productname, 
        s.order_date AS orderdate, 
        mem.join_date AS joindate
    FROM 
        sales AS s
    JOIN 
        menu AS m
    ON 
        s.product_id = m.product_id
    JOIN 
        members AS mem
    ON 
        mem.customer_id = s.customer_id
    WHERE 
        s.order_date < mem.join_date
),
ranked_orders AS (
    SELECT 
        customerid, 
        productid, 
        productname, 
        orderdate, 
        joindate,
        ROW_NUMBER() OVER (PARTITION BY customerid ORDER BY orderdate desc) AS rnk
    FROM 
        tab
)
SELECT 
    customerid, 
    orderdate AS first_order_after_member, 
    productid, 
    productname, 
    joindate
FROM 
    ranked_orders
WHERE 
    rnk = 1
ORDER BY 
    customerid;

-- 8
select customerid, count(productid), sum(pprice)
from (select s.customer_id as customerid, s.product_id as productid, me.price as pprice
from sales as s
join members as m
on s.customer_id = m.customer_id
join menu as me
on me.product_id = s.product_id
where s.order_date < m.join_date) as table1
group by customerid;

-- 9
select customerid, sum(points)
from
 (SELECT 
        mem.customer_id AS customerid, 
        s.product_id AS productid, 
        m.product_name AS productname, 
        s.order_date AS orderdate, 
        mem.join_date AS joindate,
        case
        	when m.product_name = 'sushi' then (m.price*20)
            else (m.price * 10)
        end as points
    FROM 
        sales AS s
    JOIN 
        menu AS m
    ON 
        s.product_id = m.product_id
    JOIN 
        members AS mem
    ON 
        mem.customer_id = s.customer_id
    WHERE 
        s.order_date >= mem.join_date) as table1
    group by customerid;

-- 10
select customerid, sum(points) as total_points
from
 (SELECT 
        mem.customer_id AS customerid, 
        s.product_id AS productid, 
        m.product_name AS productname, 
        s.order_date AS orderdate, 
        mem.join_date AS joindate,
        (m.price*20) as points
    FROM 
        sales AS s
    JOIN 
        menu AS m
    ON 
        s.product_id = m.product_id
    JOIN 
        members AS mem
    ON 
        mem.customer_id = s.customer_id
    WHERE 
        s.order_date >= mem.join_date and s.order_date >= '2021-01-01' AND s.order_date < '2021-02-01') as table1
    group by customerid
    order by total_points desc;

