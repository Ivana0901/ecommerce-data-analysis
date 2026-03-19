-- =========================================================
-- 1. Customer Overview
-- Purpose: calculate the number of unique customers and
-- compare it to total orders
-- =========================================================

WITH order_level AS (
    SELECT
        order_id,
        MAX(customer_unique_id) AS customer_unique_id
    FROM vw_order_details
    GROUP BY order_id
)
SELECT
    COUNT(*) AS total_orders,
    COUNT(DISTINCT customer_unique_id) AS unique_customers,
    ROUND((COUNT(*)::numeric / COUNT(DISTINCT customer_unique_id)), 2) AS orders_per_customer_ratio
FROM order_level;

-- =========================================================
-- 2. Repeat vs One-Time Customers
-- Purpose: identify how many customers purchased once
-- versus multiple times
-- =========================================================

WITH order_level AS (
    SELECT
        order_id,
        MAX(customer_unique_id) AS customer_unique_id
    FROM vw_order_details
    GROUP BY order_id
),
customer_orders AS (
    SELECT
        customer_unique_id,
        COUNT(order_id) AS total_orders
    FROM order_level
    GROUP BY customer_unique_id
)
SELECT
    CASE
        WHEN total_orders = 1 THEN 'one_time'
        ELSE 'repeat'
    END AS customer_type,
    COUNT(*) AS total_customers,
    ROUND((COUNT(*)::numeric / SUM(COUNT(*)) OVER ()) * 100, 2) AS customer_share_pct
FROM customer_orders
GROUP BY 1
ORDER BY total_customers DESC;


-- =========================================================
-- 3. Orders per Customer
-- Purpose: measure average customer purchase frequency
-- =========================================================

WITH order_level AS (
    SELECT
        order_id,
        MAX(customer_unique_id) AS customer_unique_id
    FROM vw_order_details
    GROUP BY order_id
),
customer_orders AS (
    SELECT
        customer_unique_id,
        COUNT(order_id) AS total_orders
    FROM order_level
    GROUP BY customer_unique_id
)
SELECT
    ROUND(AVG(total_orders)::numeric, 2) AS avg_orders_per_customer,
    MAX(total_orders) AS max_orders_by_single_customer
FROM customer_orders;


-- =========================================================
-- 4. Orders per Customer Distribution
-- Purpose: analyze how many customers placed 1, 2, 3, or more orders
-- =========================================================

WITH order_level AS (
    SELECT
        order_id,
        MAX(customer_unique_id) AS customer_unique_id
    FROM vw_order_details
    GROUP BY order_id
),
customer_orders AS (
    SELECT
        customer_unique_id,
        COUNT(order_id) AS total_orders
    FROM order_level
    GROUP BY customer_unique_id
)
SELECT
    total_orders,
    COUNT(*) AS total_customers,
    ROUND((COUNT(*)::numeric / SUM(COUNT(*)) OVER ()) * 100, 2) AS customer_share_pct
FROM customer_orders
GROUP BY total_orders
ORDER BY total_orders;


-- =========================================================
-- 5. Review Score Distribution
-- Purpose: analyze the distribution of customer review scores
-- at the order level
-- =========================================================

WITH order_level AS (
    SELECT
        order_id,
        MAX(avg_review_score) AS avg_review_score
    FROM vw_order_details
    GROUP BY order_id
)
SELECT
    avg_review_score AS review_score,
    COUNT(*) AS total_orders,
    ROUND((COUNT(*)::numeric / SUM(COUNT(*)) OVER ()) * 100, 2) AS order_share_pct
FROM order_level
WHERE avg_review_score IS NOT NULL
GROUP BY avg_review_score
ORDER BY avg_review_score;

SELECT * FROM vw_order_details;

-- =========================================================
-- 6. Delivery Time vs Review Score
-- Purpose: evaluate whether longer delivery times are associated
-- with lower customer review scores
-- =========================================================

WITH order_level AS (
    SELECT
        order_id,
        MAX(order_status) AS order_status,
        MAX(order_purchase_timestamp) AS order_purchase_timestamp,
        MAX(order_delivered_customer_date) AS order_delivered_customer_date,
        MAX(avg_review_score) AS avg_review_score
    FROM vw_order_details
    GROUP BY order_id
),
delivery_metrics AS (
    SELECT
        order_id,
        avg_review_score,
        (order_delivered_customer_date::date - order_purchase_timestamp::date) AS delivery_days
    FROM order_level
    WHERE order_status = 'delivered'
      AND order_delivered_customer_date IS NOT NULL
      AND order_purchase_timestamp IS NOT NULL
      AND avg_review_score IS NOT NULL
),
delivery_buckets AS (
    SELECT
        order_id,
        avg_review_score,
        delivery_days,
        CASE
            WHEN delivery_days BETWEEN 0 AND 3 THEN '0-3 days'
            WHEN delivery_days BETWEEN 4 AND 7 THEN '4-7 days'
            WHEN delivery_days BETWEEN 8 AND 14 THEN '8-14 days'
            WHEN delivery_days BETWEEN 15 AND 21 THEN '15-21 days'
            ELSE '22+ days'
        END AS delivery_time_bucket
    FROM delivery_metrics
)
SELECT
    delivery_time_bucket,
    COUNT(*) AS total_orders,
    ROUND(AVG(delivery_days)::numeric, 2) AS avg_delivery_days,
    ROUND(AVG(avg_review_score)::numeric, 2) AS avg_review_score
FROM delivery_buckets
GROUP BY delivery_time_bucket
ORDER BY
    CASE
        WHEN delivery_time_bucket = '0-3 days' THEN 1
        WHEN delivery_time_bucket = '4-7 days' THEN 2
        WHEN delivery_time_bucket = '8-14 days' THEN 3
        WHEN delivery_time_bucket = '15-21 days' THEN 4
        ELSE 5
    END;


-- =========================================================
-- 7. Review Score by Customer Type
-- Purpose: compare average review scores between one-time
-- and repeat customers
-- =========================================================

WITH order_level AS (
    SELECT
        order_id,
        MAX(customer_unique_id) AS customer_unique_id,
        MAX(avg_review_score) AS avg_review_score
    FROM vw_order_details
    GROUP BY order_id
),
customer_orders AS (
    SELECT
        customer_unique_id,
        COUNT(order_id) AS total_orders
    FROM order_level
    GROUP BY customer_unique_id
),
order_customer_type AS (
    SELECT
        o.order_id,
        o.customer_unique_id,
        o.avg_review_score,
        CASE
            WHEN c.total_orders = 1 THEN 'one_time'
            ELSE 'repeat'
        END AS customer_type
    FROM order_level o
    JOIN customer_orders c
        ON o.customer_unique_id = c.customer_unique_id
    WHERE o.avg_review_score IS NOT NULL
)
SELECT
    customer_type,
    COUNT(*) AS total_reviewed_orders,
    ROUND(AVG(avg_review_score)::numeric, 2) AS avg_review_score
FROM order_customer_type
GROUP BY customer_type
ORDER BY total_reviewed_orders DESC;


-- =========================================================
-- 8. Delivery Time by Customer Type
-- Purpose: compare average delivery time between one-time
-- and repeat customers
-- =========================================================

WITH order_level AS (
    SELECT
        order_id,
        MAX(customer_unique_id) AS customer_unique_id,
        MAX(order_status) AS order_status,
        MAX(order_purchase_timestamp) AS order_purchase_timestamp,
        MAX(order_delivered_customer_date) AS order_delivered_customer_date
    FROM vw_order_details
    GROUP BY order_id
),
customer_orders AS (
    SELECT
        customer_unique_id,
        COUNT(order_id) AS total_orders
    FROM order_level
    GROUP BY customer_unique_id
),
order_customer_type AS (
    SELECT
        o.order_id,
        o.customer_unique_id,
        CASE
            WHEN c.total_orders = 1 THEN 'one_time'
            ELSE 'repeat'
        END AS customer_type,
        (o.order_delivered_customer_date::date - o.order_purchase_timestamp::date) AS delivery_days
    FROM order_level o
    JOIN customer_orders c
        ON o.customer_unique_id = c.customer_unique_id
    WHERE o.order_status = 'delivered'
      AND o.order_delivered_customer_date IS NOT NULL
      AND o.order_purchase_timestamp IS NOT NULL
)
SELECT
    customer_type,
    COUNT(*) AS total_delivered_orders,
    ROUND(AVG(delivery_days)::numeric, 2) AS avg_delivery_days
FROM order_customer_type
GROUP BY customer_type
ORDER BY total_delivered_orders DESC;