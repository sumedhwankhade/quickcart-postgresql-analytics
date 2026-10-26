
-- ============================================================
-- QuickCart India | 03_business_analysis.sql (PostgreSQL)
-- ============================================================

-- Q1. Overall KPIs (Delivered orders only)
-- Business question: How is the company's overall performance?
SELECT
    COUNT(*)                                                AS total_orders,
    COUNT(DISTINCT customer_id)                             AS active_customers,
    ROUND(SUM(net_revenue), 0)                              AS total_revenue,
    ROUND(AVG(net_revenue), 2)                              AS avg_order_value,
    ROUND(SUM(gross_profit), 0)                             AS total_gross_profit,
    ROUND(100.0 * SUM(gross_profit) / SUM(gross_value), 2)  AS profit_margin_pct
FROM v_order_value
WHERE order_status = 'Delivered';


-- Q2. Order status breakdown (cancellation and return rates)
-- The window function calculates the total number of orders
-- and uses it to calculate the percentage for each status.
SELECT order_status,
       COUNT(*) AS orders,
       ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS pct
FROM orders
GROUP BY order_status
ORDER BY orders DESC;


-- Q3. Monthly revenue trend with Month-over-Month growth (CTE + LAG)
WITH monthly AS (
    SELECT TO_CHAR(order_date, 'YYYY-MM') AS month,
           COUNT(*)                       AS orders,
           ROUND(SUM(net_revenue), 0)     AS revenue
    FROM v_order_value
    WHERE order_status = 'Delivered'
    GROUP BY TO_CHAR(order_date, 'YYYY-MM')
)
SELECT month, orders, revenue,
       LAG(revenue) OVER (ORDER BY month) AS prev_month_revenue,
       ROUND(100.0 * (revenue - LAG(revenue) OVER (ORDER BY month))
             / LAG(revenue) OVER (ORDER BY month), 2) AS mom_growth_pct
FROM monthly
ORDER BY month;


-- Q4. Category performance: revenue, profit, and profit margin
SELECT p.category,
       SUM(i.quantity)                                           AS units_sold,
       ROUND(SUM(i.quantity * i.unit_price), 0)                  AS revenue,
       ROUND(SUM(i.quantity * (i.unit_price - p.cost_price)), 0) AS profit,
       ROUND(100.0 * SUM(i.quantity * (i.unit_price - p.cost_price))
             / SUM(i.quantity * i.unit_price), 2)                AS margin_pct
FROM order_items i
JOIN products p ON p.product_id = i.product_id
JOIN orders o   ON o.order_id   = i.order_id
WHERE o.order_status = 'Delivered'
GROUP BY p.category
ORDER BY revenue DESC;


-- Q5. Top 3 products in EACH category (DENSE_RANK + PARTITION BY)
WITH product_rev AS (
    SELECT p.category, p.product_name,
           ROUND(SUM(i.quantity * i.unit_price), 0) AS revenue
    FROM order_items i
    JOIN products p ON p.product_id = i.product_id
    JOIN orders o   ON o.order_id   = i.order_id
    WHERE o.order_status = 'Delivered'
    GROUP BY p.category, p.product_name
),
ranked AS (
    SELECT *,
           DENSE_RANK() OVER (
               PARTITION BY category
               ORDER BY revenue DESC
           ) AS rnk
    FROM product_rev
)
SELECT category, rnk, product_name, revenue
FROM ranked
WHERE rnk <= 3
ORDER BY category, rnk;


-- Q6. City-wise business performance
SELECT c.city,
       COUNT(DISTINCT c.customer_id) AS customers,
       COUNT(v.order_id)             AS orders,
       ROUND(SUM(v.net_revenue), 0)  AS revenue,
       ROUND(SUM(v.net_revenue) / COUNT(DISTINCT c.customer_id), 0) AS revenue_per_customer
FROM customers c
JOIN v_order_value v ON v.customer_id = c.customer_id
WHERE v.order_status = 'Delivered'
GROUP BY c.city
ORDER BY revenue DESC;


-- Q7. Peak ordering hours (time-of-day groups using CASE)
SELECT CASE
           WHEN order_hour BETWEEN 6  AND 11 THEN '1. Morning (6-11)'
           WHEN order_hour BETWEEN 12 AND 16 THEN '2. Afternoon (12-16)'
           WHEN order_hour BETWEEN 17 AND 21 THEN '3. Evening (17-21)'
           ELSE '4. Night (22-5)'
       END AS time_slot,
       COUNT(*) AS orders,
       ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS pct_orders
FROM orders
GROUP BY 1
ORDER BY 1;


-- Q8a. Payment method vs. order value
SELECT payment_method,
       COUNT(*)                   AS orders,
       ROUND(AVG(net_revenue), 2) AS avg_order_value
FROM v_order_value
WHERE order_status = 'Delivered'
GROUP BY payment_method
ORDER BY orders DESC;


-- Q8b. Coupon impact: Do coupons increase the average basket value?
SELECT coupon_code,
       COUNT(*)                      AS orders,
       ROUND(AVG(gross_value), 2)    AS avg_basket,
       ROUND(SUM(discount_amount),0) AS discount_given,
       ROUND(SUM(net_revenue), 0)    AS revenue
FROM v_order_value
WHERE order_status = 'Delivered'
GROUP BY coupon_code
ORDER BY orders DESC;
