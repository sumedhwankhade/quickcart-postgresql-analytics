-- ============================================================
-- QuickCart India | 02_data_checks_and_view.sql
-- Database: PostgreSQL
-- ============================================================

-- 1. Row counts of every table
-- Expected: 2000 / 56 / 9284 / 27109 / 8820
SELECT 'customers' AS tbl, COUNT(*) AS rows_cnt FROM customers
UNION ALL SELECT 'products',    COUNT(*) FROM products
UNION ALL SELECT 'orders',      COUNT(*) FROM orders
UNION ALL SELECT 'order_items', COUNT(*) FROM order_items
UNION ALL SELECT 'deliveries',  COUNT(*) FROM deliveries;

-- 2. Duplicate order ids (expected: 0 rows)
SELECT order_id, COUNT(*) FROM orders GROUP BY order_id HAVING COUNT(*) > 1;

-- 3. NULL checks on critical columns (expected: all 0)
SELECT
    SUM(CASE WHEN customer_id  IS NULL THEN 1 ELSE 0 END) AS null_customer,
    SUM(CASE WHEN order_date   IS NULL THEN 1 ELSE 0 END) AS null_date,
    SUM(CASE WHEN order_status IS NULL THEN 1 ELSE 0 END) AS null_status
FROM orders;

-- 4. Orphan check: orders whose customer does not exist (expected: 0)
SELECT COUNT(*) AS orphan_orders
FROM orders o LEFT JOIN customers c ON c.customer_id = o.customer_id
WHERE c.customer_id IS NULL;

-- 5. Orders without items (expected: 0)
SELECT COUNT(*) AS orders_without_items
FROM orders o LEFT JOIN order_items i ON i.order_id = o.order_id
WHERE i.order_id IS NULL;

-- 6. Orders placed before customer signup (expected: 0)
SELECT COUNT(*) AS orders_before_signup
FROM orders o JOIN customers c ON c.customer_id = o.customer_id
WHERE o.order_date < c.signup_date;

-- 7. Date range of data
SELECT MIN(order_date) AS first_order, MAX(order_date) AS last_order FROM orders;

-- ------------------------------------------------------------
-- Reusable VIEW: Calculates the final revenue for each order.
-- All subsequent queries can use this view.
--
-- Net revenue = Total item value - Discount + Delivery fee
-- ------------------------------------------------------------
CREATE OR REPLACE VIEW v_order_value AS
SELECT
    o.order_id,
    o.customer_id,
    o.order_date,
    o.order_hour,
    o.order_status,
    o.payment_method,
    o.coupon_code,
    SUM(i.quantity * i.unit_price)                                      AS gross_value,
    o.discount_amount,
    o.delivery_fee,
    SUM(i.quantity * i.unit_price) - o.discount_amount + o.delivery_fee AS net_revenue,
    SUM(i.quantity * (i.unit_price - p.cost_price))                     AS gross_profit
FROM orders o
JOIN order_items i ON i.order_id = o.order_id
JOIN products p    ON p.product_id = i.product_id
GROUP BY o.order_id, o.customer_id, o.order_date, o.order_hour, o.order_status,
         o.payment_method, o.coupon_code, o.discount_amount, o.delivery_fee;
		 -- PostgreSQL allows this because order_id is the PRIMARY KEY

-- Quick test of the view
SELECT * FROM v_order_value LIMIT 5;






