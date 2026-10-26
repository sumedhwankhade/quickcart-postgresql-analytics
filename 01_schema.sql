-- ============================================================
-- QuickCart India | 01_schema.sql
-- Database: PostgreSQL (pgAdmin 4)
-- ============================================================
DROP VIEW  IF EXISTS v_order_value;
DROP TABLE IF EXISTS deliveries;
DROP TABLE IF EXISTS order_items;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS customers;

CREATE TABLE customers (
    customer_id          INTEGER PRIMARY KEY,
    customer_name        VARCHAR(50) NOT NULL,
    gender               CHAR(1),
    age                  INTEGER,
    city                 VARCHAR(50),
    state                VARCHAR(50),
    signup_date          DATE,
    acquisition_channel  VARCHAR(50),
    is_prime_member      SMALLINT CHECK (is_prime_member IN (0,1))
);

CREATE TABLE products (
    product_id    INTEGER PRIMARY KEY,
    product_name  VARCHAR(100) NOT NULL,
    category      VARCHAR(50),
    unit_price    NUMERIC(10,2),
    cost_price    NUMERIC(10,2)
);

CREATE TABLE orders (
    order_id        INTEGER PRIMARY KEY,
    customer_id     INTEGER NOT NULL REFERENCES customers(customer_id),
    order_date      DATE NOT NULL,
    order_hour      SMALLINT,
    order_status    VARCHAR(20),     -- Delivered / Cancelled / Returned
    payment_method  VARCHAR(20),
    coupon_code     VARCHAR(20),
    discount_amount NUMERIC(10,2),
    delivery_fee    NUMERIC(10,2)
);

CREATE TABLE order_items (
    order_item_id INTEGER PRIMARY KEY,
    order_id      INTEGER NOT NULL REFERENCES orders(order_id),
    product_id    INTEGER NOT NULL REFERENCES products(product_id),
    quantity      INTEGER,
    unit_price    NUMERIC(10,2)
);

CREATE TABLE deliveries (
    order_id         INTEGER PRIMARY KEY REFERENCES orders(order_id),
    delivery_minutes INTEGER,
    rating           SMALLINT
);

CREATE INDEX idx_orders_customer ON orders(customer_id);
CREATE INDEX idx_orders_date     ON orders(order_date);
CREATE INDEX idx_items_order     ON order_items(order_id);
CREATE INDEX idx_items_product   ON order_items(product_id);
