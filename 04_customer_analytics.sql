
-- ============================================================
-- QuickCart India | 04_customer_analytics.sql (PostgreSQL)
-- Level: Advanced (CLV, RFM, Cohort Retention, Window Functions)
-- ============================================================

-- Q9. Customer Lifetime Value (CLV): Top 10 customers
SELECT c.customer_id, c.city, c.is_prime_member,
       COUNT(v.order_id)            AS orders,
       ROUND(SUM(v.net_revenue), 0) AS lifetime_value
FROM customers c
JOIN v_order_value v ON v.customer_id = c.customer_id
WHERE v.order_status = 'Delivered'
GROUP BY c.customer_id, c.city, c.is_prime_member
ORDER BY lifetime_value DESC
LIMIT 10;


-- Q10. Compare Prime and Non-Prime customer behavior
SELECT CASE WHEN c.is_prime_member = 1 THEN 'Prime' ELSE 'Non-Prime' END AS segment,
       COUNT(DISTINCT c.customer_id)                                     AS customers,
       COUNT(v.order_id)                                                 AS orders,
       ROUND(1.0 * COUNT(v.order_id) / COUNT(DISTINCT c.customer_id), 2) AS orders_per_customer,
       ROUND(AVG(v.net_revenue), 2)                                      AS avg_order_value
FROM customers c
JOIN v_order_value v ON v.customer_id = c.customer_id
WHERE v.order_status = 'Delivered'
GROUP BY 1;


-- Q11. Acquisition channel quality: Which channel brings in the most valuable customers?
SELECT c.acquisition_channel,
       COUNT(DISTINCT c.customer_id) AS customers,
       ROUND(SUM(v.net_revenue) / COUNT(DISTINCT c.customer_id), 0) AS revenue_per_customer
FROM customers c
LEFT JOIN v_order_value v
       ON v.customer_id = c.customer_id AND v.order_status = 'Delivered'
GROUP BY c.acquisition_channel
ORDER BY revenue_per_customer DESC;


-- Q12. Compare repeat customers with one-time customers
WITH cust_orders AS (
    SELECT customer_id, COUNT(*) AS n_orders
    FROM orders
    WHERE order_status = 'Delivered'
    GROUP BY customer_id
)
SELECT CASE WHEN n_orders = 1              THEN 'One-time'
            WHEN n_orders BETWEEN 2  AND 5  THEN '2-5 orders'
            WHEN n_orders BETWEEN 6  AND 15 THEN '6-15 orders'
            ELSE '16+ orders' END AS bucket,
       COUNT(*) AS customers,
       ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS pct
FROM cust_orders
GROUP BY 1
ORDER BY MIN(n_orders);


-- Q13. RFM segmentation (Recency, Frequency, Monetary) using NTILE
-- Snapshot date: 2026-09-30 (the last day of the dataset)
WITH rfm_base AS (
    SELECT customer_id,
           (DATE '2026-09-30' - MAX(order_date)) AS recency_days,
           COUNT(*)                              AS frequency,
           ROUND(SUM(net_revenue), 0)            AS monetary
    FROM v_order_value
    WHERE order_status = 'Delivered'
    GROUP BY customer_id
),
rfm_score AS (
    SELECT *,
           NTILE(4) OVER (ORDER BY recency_days DESC) AS r,   -- 4 = most recent
           NTILE(4) OVER (ORDER BY frequency)         AS f,   -- 4 = most frequent
           NTILE(4) OVER (ORDER BY monetary)          AS m    -- 4 = highest spending
    FROM rfm_base
)
SELECT CASE
           WHEN r = 4 AND f >= 3 AND m >= 3 THEN 'Champions'
           WHEN r >= 3 AND f >= 2           THEN 'Loyal'
           WHEN r = 4 AND f = 1             THEN 'New Customers'
           WHEN r <= 2 AND f >= 3           THEN 'At Risk (was valuable)'
           WHEN r = 1 AND f <= 2            THEN 'Lost'
           ELSE 'Needs Attention'
       END AS segment,
       COUNT(*)                    AS customers,
       ROUND(AVG(monetary), 0)     AS avg_spend,
       ROUND(AVG(recency_days), 0) AS avg_days_since_last_order
FROM rfm_score
GROUP BY 1
ORDER BY customers DESC;


-- Q14. Monthly cohort retention
-- Cohort = the month of a customer's first delivered order.
-- month_no = the number of months since the customer's cohort month.
WITH first_order AS (
    SELECT customer_id, DATE_TRUNC('month', MIN(order_date))::date AS cohort_month
    FROM orders
    WHERE order_status = 'Delivered'
    GROUP BY customer_id
),
activity AS (
    SELECT DISTINCT o.customer_id, f.cohort_month,
           (EXTRACT(YEAR  FROM o.order_date) - EXTRACT(YEAR  FROM f.cohort_month)) * 12
         + (EXTRACT(MONTH FROM o.order_date) - EXTRACT(MONTH FROM f.cohort_month)) AS month_no
    FROM orders o
    JOIN first_order f ON f.customer_id = o.customer_id
    WHERE o.order_status = 'Delivered'
),
cohort_size AS (
    SELECT cohort_month, COUNT(*) AS size
    FROM first_order
    GROUP BY cohort_month
)
SELECT TO_CHAR(a.cohort_month, 'YYYY-MM') AS cohort_month,
       s.size AS cohort_size,
       ROUND(100.0 * SUM(CASE WHEN month_no = 1 THEN 1 ELSE 0 END) / s.size, 1) AS m1_retention_pct,
       ROUND(100.0 * SUM(CASE WHEN month_no = 2 THEN 1 ELSE 0 END) / s.size, 1) AS m2_retention_pct,
       ROUND(100.0 * SUM(CASE WHEN month_no = 3 THEN 1 ELSE 0 END) / s.size, 1) AS m3_retention_pct
FROM activity a
JOIN cohort_size s ON s.cohort_month = a.cohort_month
GROUP BY a.cohort_month, s.size
ORDER BY a.cohort_month;


-- Q15. Average gap between two consecutive orders (LAG per customer)
WITH gaps AS (
    SELECT customer_id, order_date,
           order_date - LAG(order_date) OVER (PARTITION BY customer_id ORDER BY order_date) AS gap_days
    FROM orders
    WHERE order_status = 'Delivered'
)
SELECT ROUND(AVG(gap_days), 1) AS avg_days_between_orders,
       MIN(gap_days)           AS min_gap,
       MAX(gap_days)           AS max_gap
FROM gaps
WHERE gap_days IS NOT NULL;


-- Q16. Running (cumulative) revenue by month
WITH monthly AS (
    SELECT TO_CHAR(order_date, 'YYYY-MM') AS month,
           SUM(net_revenue) AS revenue
    FROM v_order_value
    WHERE order_status = 'Delivered'
    GROUP BY 1
)
SELECT month,
       ROUND(revenue, 0)                            AS revenue,
       ROUND(SUM(revenue) OVER (ORDER BY month), 0) AS cumulative_revenue
FROM monthly
ORDER BY month;
