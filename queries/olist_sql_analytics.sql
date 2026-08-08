SHOW VARIABLES LIKE 'local_infile';
SELECT VERSION();
SET GLOBAL local_infile = 1;
SHOW VARIABLES LIKE 'local_infile';
DROP DATABASE IF EXISTS olist_ecommerce;

CREATE DATABASE olist_ecommerce;

USE olist_ecommerce;

CREATE TABLE olist_customers_dataset (
    customer_id             VARCHAR(50) PRIMARY KEY,
    customer_unique_id      VARCHAR(50),
    customer_zip_code_prefix VARCHAR(10),
    customer_city           VARCHAR(100),
    customer_state          VARCHAR(5)
);

SHOW TABLES;

CREATE TABLE olist_orders_dataset (
    order_id                       VARCHAR(50) PRIMARY KEY,
    customer_id                    VARCHAR(50),
    order_status                   VARCHAR(20),
    order_purchase_timestamp       DATETIME,
    order_approved_at              DATETIME,
    order_delivered_carrier_date   DATETIME,
    order_delivered_customer_date  DATETIME,
    order_estimated_delivery_date  DATETIME
);

CREATE TABLE olist_order_items_dataset (
    order_id            VARCHAR(50),
    order_item_id       INT,
    product_id          VARCHAR(50),
    seller_id           VARCHAR(50),
    shipping_limit_date DATETIME,
    price               DECIMAL(10,2),
    freight_value       DECIMAL(10,2)
);

CREATE TABLE olist_order_payments_dataset (
    order_id             VARCHAR(50),
    payment_sequential   INT,
    payment_type         VARCHAR(20),
    payment_installments INT,
    payment_value        DECIMAL(10,2)
);

CREATE TABLE olist_products_dataset (
    product_id                 VARCHAR(50) PRIMARY KEY,
    product_category_name      VARCHAR(100),
    product_name_lenght        INT,
    product_description_lenght INT,
    product_photos_qty         INT,
    product_weight_g           INT,
    product_length_cm          INT,
    product_height_cm          INT,
    product_width_cm           INT
);

CREATE TABLE product_category_name_translation (
    product_category_name         VARCHAR(100) PRIMARY KEY,
    product_category_name_english VARCHAR(100)
);
SHOW TABLES;

SET GLOBAL local_infile = 1;

LOAD DATA LOCAL INFILE "C:/Users/USER/Documents/PORTFOLIO PROJECT DATASETS/Brazilian E-Commerce Public Dataset by Olist/olist_customers_dataset.csv"
INTO TABLE olist_customers_dataset
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

LOAD DATA LOCAL INFILE "C:/Users/USER/Documents/PORTFOLIO PROJECT DATASETS/Brazilian E-Commerce Public Dataset by Olist/olist_orders_dataset.csv"
INTO TABLE olist_orders_dataset
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(order_id, customer_id, order_status, order_purchase_timestamp,
 order_approved_at, order_delivered_carrier_date,
 order_delivered_customer_date, order_estimated_delivery_date);
 
 SELECT order_status, COUNT(*) 
FROM olist_orders_dataset 
GROUP BY order_status;

LOAD DATA LOCAL INFILE 'C:/Users/USER/Documents/PORTFOLIO PROJECT DATASETS/Brazilian E-Commerce Public Dataset by Olist/olist_order_items_dataset.csv'
INTO TABLE olist_order_items_dataset
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

LOAD DATA LOCAL INFILE 'C:/Users/USER/Documents/PORTFOLIO PROJECT DATASETS/Brazilian E-Commerce Public Dataset by Olist/olist_order_payments_dataset.csv'
INTO TABLE olist_order_payments_dataset
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

LOAD DATA LOCAL INFILE 'C:/Users/USER/Documents/PORTFOLIO PROJECT DATASETS/Brazilian E-Commerce Public Dataset by Olist/olist_products_dataset.csv'
INTO TABLE olist_products_dataset
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

LOAD DATA LOCAL INFILE 'C:/Users/USER/Documents/PORTFOLIO PROJECT DATASETS/Brazilian E-Commerce Public Dataset by Olist/product_category_name_translation.csv'
INTO TABLE product_category_name_translation
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

SELECT COUNT(*) FROM olist_products_dataset;
SELECT COUNT(*) FROM product_category_name_translation;

SELECT 'customers' AS table_name, COUNT(*) FROM olist_customers_dataset
UNION ALL SELECT 'orders', COUNT(*) FROM olist_orders_dataset
UNION ALL SELECT 'order_items', COUNT(*) FROM olist_order_items_dataset
UNION ALL SELECT 'payments', COUNT(*) FROM olist_order_payments_dataset
UNION ALL SELECT 'products', COUNT(*) FROM olist_products_dataset
UNION ALL SELECT 'categories', COUNT(*) FROM product_category_name_translation;


WITH monthly_orders AS (
    SELECT
        DATE_FORMAT(order_purchase_timestamp, '%Y-%m-01') AS order_month,
        COUNT(DISTINCT order_id) AS total_orders
    FROM olist_orders_dataset
    -- Exclude canceled/unavailable orders so growth reflects real demand, not noise
    WHERE order_status NOT IN ('canceled', 'unavailable')
    GROUP BY 1
)
SELECT
    order_month,
    total_orders,
    LAG(total_orders) OVER (ORDER BY order_month) AS prev_month_orders,
    ROUND(
        (total_orders - LAG(total_orders) OVER (ORDER BY order_month))
        / LAG(total_orders) OVER (ORDER BY order_month) * 100
    , 2) AS mom_growth_pct
FROM monthly_orders
ORDER BY order_month;


WITH category_revenue AS (
    SELECT
        COALESCE(t.product_category_name_english, p.product_category_name) AS category,
        -- Revenue includes freight, not just price, to reflect true transaction value
        SUM(oi.price + oi.freight_value) AS total_revenue,
        COUNT(DISTINCT oi.order_id) AS total_orders
    FROM olist_order_items_dataset oi
    JOIN olist_products_dataset p
        ON oi.product_id = p.product_id
    LEFT JOIN product_category_name_translation t
        ON p.product_category_name = t.product_category_name
    JOIN olist_orders_dataset o
        ON oi.order_id = o.order_id
    -- Only count delivered orders — completed, realized revenue only
    WHERE o.order_status = 'delivered'
    GROUP BY 1
)
SELECT
    category,
    total_revenue,
    total_orders,
    RANK() OVER (ORDER BY total_revenue DESC) AS revenue_rank
FROM category_revenue
ORDER BY total_revenue DESC
LIMIT 5;


WITH customer_spending AS (
    SELECT
        -- customer_unique_id, not customer_id — Olist assigns a new customer_id
        -- per order, so this is needed to identify the actual repeat shopper
        c.customer_unique_id,
        SUM(op.payment_value) AS total_spent,
        COUNT(DISTINCT o.order_id) AS total_orders
    FROM olist_orders_dataset o
    JOIN olist_customers_dataset c
        ON o.customer_id = c.customer_id
    JOIN olist_order_payments_dataset op
        ON o.order_id = op.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY 1
)
SELECT
    customer_unique_id,
    total_spent,
    total_orders,
    ROUND(total_spent / total_orders, 2) AS avg_order_value,
    DENSE_RANK() OVER (ORDER BY total_spent DESC) AS spending_rank
FROM customer_spending
ORDER BY total_spent DESC
LIMIT 10;


WITH first_purchase AS (
    -- Each customer's cohort = the month of their first delivered order
    SELECT
        c.customer_unique_id,
        DATE_FORMAT(MIN(o.order_purchase_timestamp), '%Y-%m-01') AS cohort_month
    FROM olist_orders_dataset o
    JOIN olist_customers_dataset c
        ON o.customer_id = c.customer_id
    WHERE o.order_status = 'delivered'
    GROUP BY 1
),
customer_orders AS (
    SELECT
        c.customer_unique_id,
        DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m-01') AS order_month
    FROM olist_orders_dataset o
    JOIN olist_customers_dataset c
        ON o.customer_id = c.customer_id
    WHERE o.order_status = 'delivered'
),
cohort_activity AS (
    -- month_number = how many months after acquisition this order happened
    SELECT
        fp.cohort_month,
        co.customer_unique_id,
        TIMESTAMPDIFF(MONTH, fp.cohort_month, co.order_month) AS month_number
    FROM customer_orders co
    JOIN first_purchase fp
        ON co.customer_unique_id = fp.customer_unique_id
),
cohort_size AS (
    SELECT
        cohort_month,
        COUNT(DISTINCT customer_unique_id) AS num_customers
    FROM first_purchase
    GROUP BY 1
),
retention_table AS (
    SELECT
        cohort_month,
        month_number,
        COUNT(DISTINCT customer_unique_id) AS active_customers
    FROM cohort_activity
    GROUP BY 1, 2
)
SELECT
    r.cohort_month,
    r.month_number,
    cs.num_customers,
    r.active_customers,
    -- month_number = 0 is always 100% by definition (the acquisition month itself)
    ROUND(r.active_customers / cs.num_customers * 100, 2) AS retention_pct
FROM retention_table r
JOIN cohort_size cs
    ON r.cohort_month = cs.cohort_month
ORDER BY r.cohort_month, r.month_number;

SELECT
    COUNT(DISTINCT c.customer_unique_id) AS total_customers,
    ROUND(AVG(op.payment_value), 2) AS avg_order_value
FROM olist_orders_dataset o
JOIN olist_customers_dataset c ON o.customer_id = c.customer_id
JOIN olist_order_payments_dataset op ON o.order_id = op.order_id
WHERE o.order_status = 'delivered';

SELECT
    order_count,
    COUNT(*) AS num_customers
FROM (
    SELECT c.customer_unique_id, COUNT(DISTINCT o.order_id) AS order_count
    FROM olist_orders_dataset o
    JOIN olist_customers_dataset c ON o.customer_id = c.customer_id
    WHERE o.order_status = 'delivered'
    GROUP BY 1
) t
GROUP BY order_count
ORDER BY order_count;
