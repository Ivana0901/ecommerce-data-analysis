CREATE OR REPLACE VIEW vw_products_clean AS
SELECT
    p.product_id,
    p.product_category_name,
    COALESCE(
        t.product_category_name_english,
        'unknown_category'
    ) AS product_category_name_english_clean,
    p.product_name_lenght,
    p.product_description_lenght,
    p.product_photos_qty,
    p.product_weight_g,
    p.product_length_cm,
    p.product_height_cm,
    p.product_width_cm
FROM products p
LEFT JOIN product_category_name_translation t
    ON TRIM(p.product_category_name) = TRIM(t.product_category_name);
	
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

CREATE OR REPLACE VIEW vw_order_details AS
SELECT
    o.order_id,
    o.customer_id,
    o.order_status,
    o.order_purchase_timestamp,
    o.order_approved_at,
    o.order_delivered_carrier_date,
    o.order_delivered_customer_date,
    o.order_estimated_delivery_date,

    c.customer_unique_id,
    c.customer_zip_code_prefix,
    c.customer_city,
    c.customer_state,

    oi.order_item_id,
    oi.product_id,
    oi.seller_id,
    oi.shipping_limit_date,
    oi.price,
    oi.freight_value,

    p.product_category_name,
    p.product_category_name_english_clean,
    p.product_name_lenght,
    p.product_description_lenght,
    p.product_photos_qty,
    p.product_weight_g,
    p.product_length_cm,
    p.product_height_cm,
    p.product_width_cm,

    s.seller_zip_code_prefix,
    s.seller_city,
    s.seller_state,

    r.review_count,
    r.avg_review_score,
    r.min_review_score,
    r.max_review_score
FROM orders o
LEFT JOIN customers c
    ON o.customer_id = c.customer_id
LEFT JOIN order_items oi
    ON o.order_id = oi.order_id
LEFT JOIN vw_products_clean p
    ON oi.product_id = p.product_id
LEFT JOIN sellers s
    ON oi.seller_id = s.seller_id
LEFT JOIN vw_order_reviews_clean r
    ON o.order_id = r.order_id;

SELECT COUNT(*)
FROM vw_order_details;

SELECT *
FROM vw_order_details
LIMIT 20;