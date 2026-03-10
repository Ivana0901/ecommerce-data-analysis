-- orders → customers
ALTER TABLE orders
ADD CONSTRAINT fk_orders_customer
FOREIGN KEY (customer_id)
REFERENCES customers(customer_id);

-- order_items → orders
ALTER TABLE order_items
ADD CONSTRAINT fk_orderitems_orders
FOREIGN KEY (order_id)
REFERENCES orders(order_id);

-- order_items → products
ALTER TABLE order_items
ADD CONSTRAINT fk_orderitems_products
FOREIGN KEY (product_id)
REFERENCES products(product_id);

-- order_items → sellers
ALTER TABLE order_items
ADD CONSTRAINT fk_orderitems_sellers
FOREIGN KEY (seller_id)
REFERENCES sellers(seller_id);

-- order_payments → orders
ALTER TABLE order_payments
ADD CONSTRAINT fk_payments_orders
FOREIGN KEY (order_id)
REFERENCES orders(order_id);

-- order_reviews → orders
ALTER TABLE order_reviews
ADD CONSTRAINT fk_reviews_orders
FOREIGN KEY (order_id)
REFERENCES orders(order_id);

ALTER TABLE product_category_name_translation
ADD CONSTRAINT pk_product_category_name
PRIMARY KEY (product_category_name);




SELECT COUNT(*) AS unmatched_categories
FROM products p
LEFT JOIN product_category_name_translation t
    ON p.product_category_name = t.product_category_name
WHERE p.product_category_name IS NOT NULL
  AND t.product_category_name IS NULL;



SELECT 
    p.product_category_name,
    COUNT(*) AS product_count
FROM products p
LEFT JOIN product_category_name_translation t
    ON TRIM(p.product_category_name) = TRIM(t.product_category_name)
WHERE p.product_category_name IS NOT NULL
  AND t.product_category_name IS NULL
GROUP BY p.product_category_name
ORDER BY product_count DESC;

SELECT COUNT(*) AS null_categories
FROM products
WHERE product_category_name IS NULL;

SELECT DISTINCT
    '[' || p.product_category_name || ']' AS category_name
FROM products p
LEFT JOIN product_category_name_translation t
    ON TRIM(p.product_category_name) = TRIM(t.product_category_name)
WHERE p.product_category_name IS NOT NULL
  AND t.product_category_name IS NULL;

INSERT INTO product_category_name_translation
    (product_category_name, product_category_name_english)
VALUES
    ('portateis_cozinha_e_preparadores_de_alimentos', 'portable_kitchen_and_food_preparers'),
    ('pc_gamer', 'gaming_pc');


SELECT 
    p.product_category_name,
    COUNT(*) AS product_count
FROM products p
LEFT JOIN product_category_name_translation t
    ON TRIM(p.product_category_name) = TRIM(t.product_category_name)
WHERE p.product_category_name IS NOT NULL
  AND t.product_category_name IS NULL
GROUP BY p.product_category_name
ORDER BY product_count DESC;


SELECT 
    product_id,
    product_category_name,
    product_name_lenght,
    product_description_lenght,
    product_photos_qty,
    product_weight_g,
    product_length_cm,
    product_height_cm,
    product_width_cm
FROM products
WHERE product_category_name IS NULL
LIMIT 20;

SELECT
    COUNT(DISTINCT p.product_id) AS total_null_category_products,
    COUNT(DISTINCT CASE WHEN oi.product_id IS NOT NULL THEN p.product_id END) AS sold_null_category_products,
    COUNT(DISTINCT CASE WHEN oi.product_id IS NULL THEN p.product_id END) AS unsold_null_category_products
FROM products p
LEFT JOIN order_items oi
    ON p.product_id = oi.product_id
WHERE p.product_category_name IS NULL;

SELECT
    COUNT(*) AS total_order_items_null_category,
    ROUND(SUM(oi.price), 2) AS total_sales_null_category,
    ROUND(SUM(oi.freight_value), 2) AS total_freight_null_category
FROM order_items oi
JOIN products p
    ON oi.product_id = p.product_id
WHERE p.product_category_name IS NULL;


WITH total_sales AS (
    SELECT SUM(price) AS total_price
    FROM order_items
),
null_category_sales AS (
    SELECT SUM(oi.price) AS null_price
    FROM order_items oi
    JOIN products p
        ON oi.product_id = p.product_id
    WHERE p.product_category_name IS NULL
)
SELECT
    ROUND(n.null_price, 2) AS null_category_sales,
    ROUND(t.total_price, 2) AS total_sales,
    ROUND((n.null_price / t.total_price) * 100, 2) AS pct_of_total_sales
FROM null_category_sales n
CROSS JOIN total_sales t;

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

SELECT
    product_category_name_english_clean,
    COUNT(*) AS product_count
FROM vw_products_clean
GROUP BY product_category_name_english_clean
HAVING product_category_name_english_clean = 'unknown_category';

SELECT COUNT(*) AS orders_without_customer
FROM orders o
LEFT JOIN customers c
    ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL;

SELECT COUNT(*) AS items_without_order
FROM order_items oi
LEFT JOIN orders o
    ON oi.order_id = o.order_id
WHERE o.order_id IS NULL;

SELECT COUNT(*) AS items_without_product
FROM order_items oi
LEFT JOIN products p
    ON oi.product_id = p.product_id
WHERE p.product_id IS NULL;

SELECT COUNT(*) AS items_without_seller
FROM order_items oi
LEFT JOIN sellers s
    ON oi.seller_id = s.seller_id
WHERE s.seller_id IS NULL;

SELECT COUNT(*) AS payments_without_order
FROM order_payments op
LEFT JOIN orders o
    ON op.order_id = o.order_id
WHERE o.order_id IS NULL;

SELECT COUNT(*) AS reviews_without_order
FROM order_reviews r
LEFT JOIN orders o
    ON r.order_id = o.order_id
WHERE o.order_id IS NULL;

SELECT 
    geolocation_zip_code_prefix,
    COUNT(*) AS cnt
FROM geolocation
GROUP BY geolocation_zip_code_prefix
HAVING COUNT(*) > 1
ORDER BY cnt DESC
LIMIT 10;
