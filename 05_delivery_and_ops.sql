
-- ============================================================
-- QuickCart India | 05_delivery_and_ops.sql (PostgreSQL)
-- Operations: Delivery speed vs. ratings, cancellations,
-- festive season analysis, and market basket analysis
-- ============================================================

-- Q17. Delivery time vs. rating
-- Business question: Does faster delivery lead to higher ratings?
SELECT CASE WHEN delivery_minutes <= 10 THEN '1. <= 10 min'
            WHEN delivery_minutes <= 15 THEN '2. 11-15 min'
            WHEN delivery_minutes <= 20 THEN '3. 16-20 min'
            WHEN delivery_minutes <= 25 THEN '4. 21-25 min'
            ELSE '5. 25+ min' END AS delivery_band,
       COUNT(*)                   AS orders,
       ROUND(AVG(rating), 2)      AS avg_rating
FROM deliveries
GROUP BY 1
ORDER BY 1;


-- Q18. City-wise average delivery time and percentage
-- of orders delivered within 15 minutes
SELECT c.city,
       ROUND(AVG(d.delivery_minutes), 1) AS avg_delivery_min,
       ROUND(100.0 * SUM(CASE WHEN d.delivery_minutes <= 15 THEN 1 ELSE 0 END) / COUNT(*), 1) AS pct_within_15min,
       ROUND(AVG(d.rating), 2)           AS avg_rating
FROM deliveries d
JOIN orders o    ON o.order_id    = d.order_id
JOIN customers c ON c.customer_id = o.customer_id
GROUP BY c.city
ORDER BY avg_delivery_min;


-- Q19. Hour-wise order volume and average delivery time
SELECT o.order_hour,
       COUNT(*)                          AS orders,
       ROUND(AVG(d.delivery_minutes), 1) AS avg_delivery_min
FROM deliveries d
JOIN orders o ON o.order_id = d.order_id
GROUP BY o.order_hour
ORDER BY o.order_hour;


-- Q20. Cancellation and return rates by payment method
SELECT payment_method,
       COUNT(*) AS orders,
       ROUND(100.0 * SUM(CASE WHEN order_status = 'Cancelled' THEN 1 ELSE 0 END) / COUNT(*), 2) AS cancel_rate_pct,
       ROUND(100.0 * SUM(CASE WHEN order_status = 'Returned'  THEN 1 ELSE 0 END) / COUNT(*), 2) AS return_rate_pct
FROM orders
GROUP BY payment_method
ORDER BY cancel_rate_pct DESC;


-- Q21. Festive season (October-November) vs. regular season:
-- Average number of items per order
SELECT CASE WHEN EXTRACT(MONTH FROM o.order_date) IN (10, 11)
            THEN 'Festive (Oct-Nov)' ELSE 'Regular' END AS season,
       COUNT(DISTINCT o.order_id) AS orders,
       ROUND(1.0 * COUNT(i.order_item_id) / COUNT(DISTINCT o.order_id), 2) AS avg_items_per_order
FROM orders o
JOIN order_items i ON i.order_id = o.order_id
GROUP BY 1;


-- Q22. Market basket analysis:
-- Which products are most frequently purchased together?
-- Uses a self-join to identify product pairs within the same order.
SELECT p1.product_name AS product_a,
       p2.product_name AS product_b,
       COUNT(*)        AS times_together
FROM order_items a
JOIN order_items b
    ON a.order_id = b.order_id
   AND a.product_id < b.product_id
JOIN products p1
    ON p1.product_id = a.product_id
JOIN products p2
    ON p2.product_id = b.product_id
GROUP BY p1.product_name, p2.product_name
ORDER BY times_together DESC
LIMIT 10;
