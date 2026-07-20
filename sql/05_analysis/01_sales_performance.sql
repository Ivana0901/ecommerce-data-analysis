-- =========================================================
-- 1. All-Status Item Value Summary
-- Purpose: calculate order and item-value KPIs across all
-- order statuses. This is not treated as finalized revenue
-- because canceled and unavailable orders are included.
-- =========================================================

WITH order_level AS (
    SELECT
        order_id,
        SUM(price) AS order_item_value,
        SUM(freight_value) AS order_freight,
        SUM(price + freight_value) AS order_total_value
    FROM vw_order_details
    WHERE order_item_id IS NOT NULL
    GROUP BY order_id
)
SELECT
    COUNT(*) AS total_orders_with_items,
    ROUND(SUM(order_item_value)::numeric, 2) AS total_item_value,
    ROUND(SUM(order_freight)::numeric, 2) AS total_freight,
    ROUND(
        SUM(order_total_value)::numeric,
        2
    ) AS total_value_including_freight,
    ROUND(
        AVG(order_item_value)::numeric,
        2
    ) AS average_order_item_value
FROM order_level;

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
-- Purpose: analyze the distribution of all orders and the
-- item value associated with each order status
-- =========================================================

WITH order_level AS (
    SELECT
        o.order_id,
        o.order_status,
        COALESCE(SUM(oi.price), 0) AS order_item_value
    FROM orders o
    LEFT JOIN order_items oi
        ON o.order_id = oi.order_id
    GROUP BY
        o.order_id,
        o.order_status
)
SELECT
    order_status,
    COUNT(*) AS total_orders,
    ROUND(
        COUNT(*)::numeric
        / SUM(COUNT(*)) OVER ()
        * 100,
        2
    ) AS order_share_pct,
    ROUND(
        SUM(order_item_value)::numeric,
        2
    ) AS item_value_by_status
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
-- Purpose: calculate primary sales KPIs using only
-- successfully delivered orders
-- =========================================================

WITH order_level AS (
    SELECT
        order_id,
        SUM(price) AS order_revenue,
        SUM(freight_value) AS order_freight,
        SUM(price + freight_value) AS order_total_value
    FROM vw_order_details
    WHERE order_status = 'delivered'
      AND order_item_id IS NOT NULL
    GROUP BY order_id
)
SELECT
    COUNT(*) AS delivered_orders,
    ROUND(SUM(order_revenue)::numeric, 2) AS delivered_revenue,
    ROUND(SUM(order_freight)::numeric, 2) AS delivered_freight,
    ROUND(
        SUM(order_total_value)::numeric,
        2
    ) AS delivered_total_value_including_freight,
    ROUND(
        AVG(order_revenue)::numeric,
        2
    ) AS delivered_average_order_value
FROM order_level;


-- =========================================================
-- 8. Delivered Monthly Sales Trend
-- Purpose: analyze monthly order volume, revenue, and
-- average order value for delivered orders
-- =========================================================

WITH order_level AS (
    SELECT
        order_id,
        DATE_TRUNC(
            'month',
            order_purchase_timestamp
        )::date AS order_month,
        SUM(price) AS order_revenue
    FROM vw_order_details
    WHERE order_status = 'delivered'
      AND order_item_id IS NOT NULL
    GROUP BY
        order_id,
        DATE_TRUNC(
            'month',
            order_purchase_timestamp
        )::date
)
SELECT
    order_month,
    COUNT(*) AS delivered_orders,
    ROUND(
        SUM(order_revenue)::numeric,
        2
    ) AS delivered_revenue,
    ROUND(
        AVG(order_revenue)::numeric,
        2
    ) AS delivered_average_order_value
FROM order_level
WHERE order_month >= DATE '2017-01-01'
  AND order_month < DATE '2018-09-01'
GROUP BY order_month
ORDER BY order_month;

-- =========================================================
-- 9. Delivered Monthly Revenue Growth
-- Purpose: calculate month-over-month delivered revenue
-- growth during the complete reporting period
-- =========================================================

WITH order_level AS (
    SELECT
        order_id,
        DATE_TRUNC(
            'month',
            order_purchase_timestamp
        )::date AS order_month,
        SUM(price) AS order_revenue
    FROM vw_order_details
    WHERE order_status = 'delivered'
      AND order_item_id IS NOT NULL
    GROUP BY
        order_id,
        DATE_TRUNC(
            'month',
            order_purchase_timestamp
        )::date
),
monthly_sales AS (
    SELECT
        order_month,
        COUNT(*) AS delivered_orders,
        SUM(order_revenue) AS delivered_revenue
    FROM order_level
    WHERE order_month >= DATE '2017-01-01'
      AND order_month < DATE '2018-09-01'
    GROUP BY order_month
),
monthly_comparison AS (
    SELECT
        order_month,
        delivered_orders,
        delivered_revenue,
        LAG(delivered_revenue) OVER (
            ORDER BY order_month
        ) AS previous_month_revenue
    FROM monthly_sales
)
SELECT
    order_month,
    delivered_orders,
    ROUND(
        delivered_revenue::numeric,
        2
    ) AS delivered_revenue,
    ROUND(
        (
            100.0
            * (
                delivered_revenue
                - previous_month_revenue
            )
            / NULLIF(previous_month_revenue, 0)
        )::numeric,
        2
    ) AS revenue_growth_pct
FROM monthly_comparison
ORDER BY order_month;