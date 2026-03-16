SELECT *
FROM vw_order_details
LIMIT 10;

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT order_id) AS distinct_orders,
    COUNT(DISTINCT (order_id, order_item_id)) AS distinct_order_items
FROM vw_order_details;