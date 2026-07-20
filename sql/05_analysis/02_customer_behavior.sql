-- =========================================================
-- CUSTOMER BEHAVIOR ANALYSIS
-- Reporting period: January 2017 through August 2018
-- Primary population: successfully delivered orders
-- =========================================================


-- =========================================================
-- 1. Customer Overview
-- Purpose: calculate delivered orders, unique customers,
-- and average delivered orders per customer
-- =========================================================

WITH order_level AS (
    SELECT
        order_id,
        MAX(customer_unique_id) AS customer_unique_id
    FROM vw_order_details
    WHERE order_status = 'delivered'
      AND order_purchase_timestamp >= TIMESTAMP '2017-01-01'
      AND order_purchase_timestamp < TIMESTAMP '2018-09-01'
      AND customer_unique_id IS NOT NULL
    GROUP BY order_id
)
SELECT
    COUNT(*) AS total_delivered_orders,
    COUNT(DISTINCT customer_unique_id) AS unique_customers,
    ROUND(
        COUNT(*)::numeric
        / NULLIF(COUNT(DISTINCT customer_unique_id), 0),
        2
    ) AS avg_delivered_orders_per_customer
FROM order_level;


-- =========================================================
-- 2. Repeat vs One-Time Customers
-- Purpose: identify the proportion of customers who placed
-- one delivered order versus multiple delivered orders
-- =========================================================

WITH order_level AS (
    SELECT
        order_id,
        MAX(customer_unique_id) AS customer_unique_id
    FROM vw_order_details
    WHERE order_status = 'delivered'
      AND order_purchase_timestamp >= TIMESTAMP '2017-01-01'
      AND order_purchase_timestamp < TIMESTAMP '2018-09-01'
      AND customer_unique_id IS NOT NULL
    GROUP BY order_id
),
customer_orders AS (
    SELECT
        customer_unique_id,
        COUNT(*) AS total_delivered_orders
    FROM order_level
    GROUP BY customer_unique_id
)
SELECT
    CASE
        WHEN total_delivered_orders = 1 THEN 'one_time'
        ELSE 'repeat'
    END AS customer_type,
    COUNT(*) AS total_customers,
    ROUND(
        COUNT(*)::numeric
        / SUM(COUNT(*)) OVER ()
        * 100,
        2
    ) AS customer_share_pct
FROM customer_orders
GROUP BY
    CASE
        WHEN total_delivered_orders = 1 THEN 'one_time'
        ELSE 'repeat'
    END
ORDER BY total_customers DESC;


-- =========================================================
-- 3. Orders per Customer Summary
-- Purpose: measure average and maximum delivered-order
-- frequency per customer
-- =========================================================

WITH order_level AS (
    SELECT
        order_id,
        MAX(customer_unique_id) AS customer_unique_id
    FROM vw_order_details
    WHERE order_status = 'delivered'
      AND order_purchase_timestamp >= TIMESTAMP '2017-01-01'
      AND order_purchase_timestamp < TIMESTAMP '2018-09-01'
      AND customer_unique_id IS NOT NULL
    GROUP BY order_id
),
customer_orders AS (
    SELECT
        customer_unique_id,
        COUNT(*) AS total_delivered_orders
    FROM order_level
    GROUP BY customer_unique_id
)
SELECT
    ROUND(
        AVG(total_delivered_orders)::numeric,
        2
    ) AS avg_delivered_orders_per_customer,
    MAX(total_delivered_orders) AS max_delivered_orders_by_customer
FROM customer_orders;


-- =========================================================
-- 4. Orders per Customer Distribution
-- Purpose: show how many customers placed one, two, three,
-- or more delivered orders
-- =========================================================

WITH order_level AS (
    SELECT
        order_id,
        MAX(customer_unique_id) AS customer_unique_id
    FROM vw_order_details
    WHERE order_status = 'delivered'
      AND order_purchase_timestamp >= TIMESTAMP '2017-01-01'
      AND order_purchase_timestamp < TIMESTAMP '2018-09-01'
      AND customer_unique_id IS NOT NULL
    GROUP BY order_id
),
customer_orders AS (
    SELECT
        customer_unique_id,
        COUNT(*) AS total_delivered_orders
    FROM order_level
    GROUP BY customer_unique_id
)
SELECT
    total_delivered_orders,
    COUNT(*) AS total_customers,
    ROUND(
        COUNT(*)::numeric
        / SUM(COUNT(*)) OVER ()
        * 100,
        2
    ) AS customer_share_pct
FROM customer_orders
GROUP BY total_delivered_orders
ORDER BY total_delivered_orders;


-- =========================================================
-- 5. Review Score Distribution
-- Purpose: analyze review scores for delivered orders
-- during the complete reporting period
-- =========================================================

WITH order_level AS (
    SELECT
        order_id,
        MAX(avg_review_score) AS avg_review_score
    FROM vw_order_details
    WHERE order_status = 'delivered'
      AND order_purchase_timestamp >= TIMESTAMP '2017-01-01'
      AND order_purchase_timestamp < TIMESTAMP '2018-09-01'
    GROUP BY order_id
)
SELECT
    avg_review_score AS review_score,
    COUNT(*) AS total_reviewed_orders,
    ROUND(
        COUNT(*)::numeric
        / SUM(COUNT(*)) OVER ()
        * 100,
        2
    ) AS reviewed_order_share_pct
FROM order_level
WHERE avg_review_score IS NOT NULL
GROUP BY avg_review_score
ORDER BY avg_review_score;


-- =========================================================
-- 6. Delivery Time vs Review Score
-- Purpose: evaluate whether longer delivery times are
-- associated with lower customer review scores
-- =========================================================

WITH order_level AS (
    SELECT
        order_id,
        MAX(order_purchase_timestamp) AS order_purchase_timestamp,
        MAX(order_delivered_customer_date) AS order_delivered_customer_date,
        MAX(avg_review_score) AS avg_review_score
    FROM vw_order_details
    WHERE order_status = 'delivered'
      AND order_purchase_timestamp >= TIMESTAMP '2017-01-01'
      AND order_purchase_timestamp < TIMESTAMP '2018-09-01'
    GROUP BY order_id
),
delivery_metrics AS (
    SELECT
        order_id,
        avg_review_score,
        (
            order_delivered_customer_date::date
            - order_purchase_timestamp::date
        ) AS delivery_days
    FROM order_level
    WHERE order_delivered_customer_date IS NOT NULL
      AND order_purchase_timestamp IS NOT NULL
      AND avg_review_score IS NOT NULL
      AND order_delivered_customer_date::date
          >= order_purchase_timestamp::date
),
delivery_buckets AS (
    SELECT
        order_id,
        avg_review_score,
        delivery_days,
        CASE
            WHEN delivery_days BETWEEN 0 AND 3
                THEN '0-3 days'
            WHEN delivery_days BETWEEN 4 AND 7
                THEN '4-7 days'
            WHEN delivery_days BETWEEN 8 AND 14
                THEN '8-14 days'
            WHEN delivery_days BETWEEN 15 AND 21
                THEN '15-21 days'
            ELSE '22+ days'
        END AS delivery_time_bucket
    FROM delivery_metrics
)
SELECT
    delivery_time_bucket,
    COUNT(*) AS total_orders,
    ROUND(
        COUNT(*)::numeric
        / SUM(COUNT(*)) OVER ()
        * 100,
        2
    ) AS order_share_pct,
    ROUND(
        AVG(delivery_days)::numeric,
        2
    ) AS avg_delivery_days,
    ROUND(
        AVG(avg_review_score)::numeric,
        2
    ) AS avg_review_score
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
-- 7. Customer Type Experience Summary
-- Purpose: compare review scores and delivery times between
-- one-time and repeat customers
-- =========================================================

WITH order_level AS (
    SELECT
        order_id,
        MAX(customer_unique_id) AS customer_unique_id,
        MAX(avg_review_score) AS avg_review_score,
        (
            MAX(order_delivered_customer_date)::date
            - MAX(order_purchase_timestamp)::date
        ) AS delivery_days
    FROM vw_order_details
    WHERE order_status = 'delivered'
      AND order_purchase_timestamp >= TIMESTAMP '2017-01-01'
      AND order_purchase_timestamp < TIMESTAMP '2018-09-01'
      AND customer_unique_id IS NOT NULL
    GROUP BY order_id
),
customer_orders AS (
    SELECT
        customer_unique_id,
        COUNT(*) AS total_delivered_orders
    FROM order_level
    GROUP BY customer_unique_id
),
customer_type_orders AS (
    SELECT
        o.order_id,
        o.customer_unique_id,
        o.avg_review_score,
        o.delivery_days,
        CASE
            WHEN c.total_delivered_orders = 1 THEN 'one_time'
            ELSE 'repeat'
        END AS customer_type
    FROM order_level o
    JOIN customer_orders c
        ON o.customer_unique_id = c.customer_unique_id
)
SELECT
    customer_type,
    COUNT(*) AS total_delivered_orders,
    COUNT(*) FILTER (
        WHERE avg_review_score IS NOT NULL
    ) AS total_reviewed_orders,
    ROUND(
        (
            AVG(avg_review_score) FILTER (
                WHERE avg_review_score IS NOT NULL
            )
        )::numeric,
        2
    ) AS avg_review_score,
    COUNT(*) FILTER (
        WHERE delivery_days >= 0
    ) AS orders_with_delivery_data,
    ROUND(
        (
            AVG(delivery_days) FILTER (
                WHERE delivery_days >= 0
            )
        )::numeric,
        2
    ) AS avg_delivery_days
FROM customer_type_orders
GROUP BY customer_type
ORDER BY total_delivered_orders DESC;


-- =========================================================
-- 8. Customer Geography Summary
-- Purpose: analyze delivered orders and unique customers
-- by customer state
-- =========================================================

WITH order_level AS (
    SELECT
        o.order_id,
        c.customer_unique_id,
        c.customer_state
    FROM orders o
    JOIN customers c
        ON o.customer_id = c.customer_id
    WHERE o.order_status = 'delivered'
      AND o.order_purchase_timestamp >= TIMESTAMP '2017-01-01'
      AND o.order_purchase_timestamp < TIMESTAMP '2018-09-01'
      AND c.customer_state IS NOT NULL
),
state_summary AS (
    SELECT
        customer_state,
        COUNT(DISTINCT customer_unique_id) AS unique_customers,
        COUNT(*) AS delivered_orders
    FROM order_level
    GROUP BY customer_state
)
SELECT
    customer_state,
    unique_customers,
    delivered_orders,
    ROUND(
        delivered_orders::numeric
        / SUM(delivered_orders) OVER ()
        * 100,
        2
    ) AS delivered_order_share_pct
FROM state_summary
ORDER BY delivered_orders DESC;