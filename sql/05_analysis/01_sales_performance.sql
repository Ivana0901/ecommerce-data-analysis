-- =========================================================
-- 1. Sales Summary
-- Purpose: calculate core sales KPIs such as total orders,
-- total revenue, total freight, and average order value
-- =========================================================

WITH order_level AS (
    SELECT
        order_id,
        SUM(price) AS order_revenue,
        SUM(freight_value) AS order_freight,
        SUM(price + freight_value) AS order_total_value
    FROM vw_order_details
    GROUP BY order_id
)
SELECT
    COUNT(*) AS total_orders,
    ROUND(SUM(order_revenue)::numeric, 2) AS total_revenue,
    ROUND(SUM(order_freight)::numeric, 2) AS total_freight,
    ROUND(SUM(order_total_value)::numeric, 2) AS total_value_including_freight,
    ROUND(AVG(order_revenue)::numeric, 2) AS average_order_value
FROM order_level;


-- =========================================================
-- 2. Monthly Sales Trend
-- Purpose: analyze how order volume and revenue change over time
-- =========================================================

WITH order_level AS (
    SELECT
        order_id,
        DATE_TRUNC('month', order_purchase_timestamp)::date AS order_month,
        SUM(price) AS order_revenue
    FROM vw_order_details
    GROUP BY order_id, DATE_TRUNC('month', order_purchase_timestamp)::date
)
SELECT
    order_month,
    COUNT(*) AS total_orders,
    ROUND(SUM(order_revenue)::numeric, 2) AS total_revenue,
    ROUND(AVG(order_revenue)::numeric, 2) AS average_order_value
FROM order_level
GROUP BY order_month
ORDER BY order_month;

-- =========================================================
-- 3. Monthly Revenue Growth
-- Purpose: measure month-over-month revenue growth
-- =========================================================

WITH order_level AS (
    SELECT
        order_id,
        DATE_TRUNC('month', order_purchase_timestamp)::date AS order_month,
        SUM(price) AS order_revenue
    FROM vw_order_details
    GROUP BY order_id, DATE_TRUNC('month', order_purchase_timestamp)::date
),
monthly_sales AS (
    SELECT
        order_month,
        SUM(order_revenue) AS total_revenue
    FROM order_level
    GROUP BY order_month
)
SELECT
    order_month,
    ROUND(total_revenue::numeric, 2) AS total_revenue,
    ROUND(
        (
            (total_revenue - LAG(total_revenue) OVER (ORDER BY order_month))
            / LAG(total_revenue) OVER (ORDER BY order_month)
        )::numeric * 100,
        2
    ) AS revenue_growth_pct
FROM monthly_sales
ORDER BY order_month;

-- =========================================================
-- 4. Order Status Mix
-- Purpose: understand the distribution of order statuses
-- and revenue contribution by status
-- =========================================================

WITH order_level AS (
    SELECT
        order_id,
        MAX(order_status) AS order_status,
        SUM(price) AS order_revenue
    FROM vw_order_details
    GROUP BY order_id
)
SELECT
    order_status,
    COUNT(*) AS total_orders,
    ROUND((COUNT(*)::numeric / SUM(COUNT(*)) OVER ()) * 100, 2) AS order_share_pct,
    ROUND(SUM(order_revenue)::numeric, 2) AS total_revenue
FROM order_level
GROUP BY order_status
ORDER BY total_orders DESC;


-- =========================================================
-- 5. Monthly Sales Trend (Filtered)
-- Purpose: analyze monthly revenue and orders after removing
-- partial / edge months that distort the trend
-- =========================================================

WITH order_level AS (
    SELECT
        order_id,
        DATE_TRUNC('month', order_purchase_timestamp)::date AS order_month,
        SUM(price) AS order_revenue
    FROM vw_order_details
    GROUP BY order_id, DATE_TRUNC('month', order_purchase_timestamp)::date
)
SELECT
    order_month,
    COUNT(*) AS total_orders,
    ROUND(SUM(order_revenue)::numeric, 2) AS total_revenue,
    ROUND(AVG(order_revenue)::numeric, 2) AS average_order_value
FROM order_level
WHERE order_month BETWEEN '2017-01-01' AND '2018-08-01'
GROUP BY order_month
ORDER BY order_month;

-- =========================================================
-- 6. Monthly Revenue Growth (Filtered)
-- Purpose: calculate month-over-month revenue growth using
-- only complete months for a cleaner business interpretation
-- =========================================================

WITH order_level AS (
    SELECT
        order_id,
        DATE_TRUNC('month', order_purchase_timestamp)::date AS order_month,
        SUM(price) AS order_revenue
    FROM vw_order_details
    GROUP BY order_id, DATE_TRUNC('month', order_purchase_timestamp)::date
),
monthly_sales AS (
    SELECT
        order_month,
        SUM(order_revenue) AS total_revenue
    FROM order_level
    WHERE order_month BETWEEN '2017-01-01' AND '2018-08-01'
    GROUP BY order_month
)
SELECT
    order_month,
    ROUND(total_revenue::numeric, 2) AS total_revenue,
    ROUND(
        (
            (total_revenue - LAG(total_revenue) OVER (ORDER BY order_month))
            / LAG(total_revenue) OVER (ORDER BY order_month)
        )::numeric * 100,
        2
    ) AS revenue_growth_pct
FROM monthly_sales
ORDER BY order_month;


-- =========================================================
-- 7. Delivered Orders Sales Summary
-- Purpose: calculate core sales KPIs using only delivered orders
-- =========================================================

WITH order_level AS (
    SELECT
        order_id,
        MAX(order_status) AS order_status,
        SUM(price) AS order_revenue,
        SUM(freight_value) AS order_freight,
        SUM(price + freight_value) AS order_total_value
    FROM vw_order_details
    GROUP BY order_id
)
SELECT
    COUNT(*) AS delivered_orders,
    ROUND(SUM(order_revenue)::numeric, 2) AS delivered_revenue,
    ROUND(SUM(order_freight)::numeric, 2) AS delivered_freight,
    ROUND(SUM(order_total_value)::numeric, 2) AS delivered_total_value,
    ROUND(AVG(order_revenue)::numeric, 2) AS delivered_average_order_value
FROM order_level
WHERE order_status = 'delivered';


-- =========================================================
-- 8. Delivered Monthly Sales Trend
-- Purpose: analyze monthly order volume and revenue for delivered orders only
-- =========================================================

WITH order_level AS (
    SELECT
        order_id,
        DATE_TRUNC('month', order_purchase_timestamp)::date AS order_month,
        MAX(order_status) AS order_status,
        SUM(price) AS order_revenue
    FROM vw_order_details
    GROUP BY order_id, DATE_TRUNC('month', order_purchase_timestamp)::date
)
SELECT
    order_month,
    COUNT(*) AS delivered_orders,
    ROUND(SUM(order_revenue)::numeric, 2) AS delivered_revenue,
    ROUND(AVG(order_revenue)::numeric, 2) AS delivered_average_order_value
FROM order_level
WHERE order_status = 'delivered'
  AND order_month BETWEEN '2017-01-01' AND '2018-08-01'
GROUP BY order_month
ORDER BY order_month;