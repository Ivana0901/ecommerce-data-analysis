SELECT order_id, COUNT(*)
FROM orders
GROUP BY order_id
HAVING COUNT(*) > 1;

SELECT customer_id, COUNT(*)
FROM customers
GROUP BY customer_id
HAVING COUNT(*) > 1;

SELECT product_id, COUNT(*)
FROM products
GROUP BY product_id
HAVING COUNT(*) > 1;

SELECT seller_id, COUNT(*)
FROM sellers
GROUP BY seller_id
HAVING COUNT(*) > 1;

SELECT order_id, order_item_id, COUNT(*)
FROM order_items
GROUP BY order_id, order_item_id
HAVING COUNT(*) > 1;

SELECT order_id, product_id, seller_id, COUNT(*)
FROM order_items
GROUP BY order_id, product_id, seller_id
HAVING COUNT(*) > 1;

SELECT order_id, payment_sequential, COUNT(*)
FROM order_payments
GROUP BY order_id, payment_sequential
HAVING COUNT(*) > 1;

SELECT review_id, COUNT(*)
FROM order_reviews
GROUP BY review_id
HAVING COUNT(*) > 1;

SELECT order_id, COUNT(*)
FROM order_reviews
GROUP BY order_id
HAVING COUNT(*) > 1;

SELECT product_category_name, COUNT(*)
FROM product_category_name_translation
GROUP BY product_category_name
HAVING COUNT(*) > 1;

SELECT geolocation_zip_code_prefix, COUNT(*)
FROM geolocation
GROUP BY geolocation_zip_code_prefix
HAVING COUNT(*) > 1
ORDER BY COUNT(*) DESC
LIMIT 20;

SELECT 
    geolocation_zip_code_prefix,
    geolocation_lat,
    geolocation_lng,
    geolocation_city,
    geolocation_state,
    COUNT(*)
FROM geolocation
GROUP BY 
    geolocation_zip_code_prefix,
    geolocation_lat,
    geolocation_lng,
    geolocation_city,
    geolocation_state
HAVING COUNT(*) > 1;

SELECT product_id, COUNT(*)
FROM vw_products_clean
GROUP BY product_id
HAVING COUNT(*) > 1;

SELECT
    review_id,
    order_id,
    review_score,
    review_comment_title,
    review_comment_message,
    review_creation_date,
    review_answer_timestamp,
    COUNT(*) AS cnt
FROM order_reviews
GROUP BY
    review_id,
    order_id,
    review_score,
    review_comment_title,
    review_comment_message,
    review_creation_date,
    review_answer_timestamp
HAVING COUNT(*) > 1;

SELECT
    order_id,
    COUNT(*) AS total_rows,
    COUNT(DISTINCT review_id) AS distinct_review_ids,
    COUNT(DISTINCT review_score) AS distinct_review_scores
FROM order_reviews
GROUP BY order_id
HAVING COUNT(*) > 1
ORDER BY total_rows DESC, distinct_review_ids DESC
LIMIT 20;

SELECT
    COUNT(*) AS orders_with_multiple_reviews,
    SUM(total_rows) AS total_review_rows_for_these_orders,
    MAX(total_rows) AS max_reviews_per_order
FROM (
    SELECT
        order_id,
        COUNT(*) AS total_rows
    FROM order_reviews
    GROUP BY order_id
    HAVING COUNT(*) > 1
) t;

SELECT
    COUNT(*) AS multi_review_orders,
    COUNT(CASE WHEN distinct_scores = 1 THEN 1 END) AS same_score_orders,
    COUNT(CASE WHEN distinct_scores > 1 THEN 1 END) AS different_score_orders
FROM (
    SELECT
        order_id,
        COUNT(DISTINCT review_score) AS distinct_scores
    FROM order_reviews
    GROUP BY order_id
    HAVING COUNT(*) > 1
) t;

CREATE OR REPLACE VIEW vw_order_reviews_clean AS
SELECT
    order_id,
    COUNT(*) AS review_count,
    ROUND(AVG(review_score)::numeric, 2) AS avg_review_score,
    MIN(review_score) AS min_review_score,
    MAX(review_score) AS max_review_score,
    MIN(review_creation_date) AS first_review_creation_date,
    MAX(review_creation_date) AS last_review_creation_date,
    MIN(review_answer_timestamp) AS first_review_answer_timestamp,
    MAX(review_answer_timestamp) AS last_review_answer_timestamp
FROM order_reviews
GROUP BY order_id;

SELECT order_id, COUNT(*)
FROM vw_order_reviews_clean
GROUP BY order_id
HAVING COUNT(*) > 1;