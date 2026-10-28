# 🛒 QuickCart India — Quick-Commerce Sales & Customer Analytics (PostgreSQL)

> Pure SQL project: **22 business questions** on a 10-minute grocery-delivery business (Blinkit / Zepto style), solved in **PostgreSQL (pgAdmin 4)** using JOINs, CTEs, views, window functions, cohort retention and RFM segmentation.

![PostgreSQL](https://img.shields.io/badge/PostgreSQL-16-blue) ![SQL](https://img.shields.io/badge/100%25-SQL-green) ![Queries](https://img.shields.io/badge/Queries-22-orange)

---

## 1. Business Problem
QuickCart operates in 10 Indian cities. Management wants to know:
1. How are revenue and profit trending?
2. Which categories, products and cities drive growth?
3. Who are the best customers, and who are we about to lose?
4. Does faster delivery improve ratings?
5. Which acquisition channel brings the best customers?
6. Do coupons and festive season actually pay off?

## 2. Dataset
Synthetic data (Jan 2025 – Sep 2026). No real company data is used; patterns such as festive uplift and the evening peak are built in so that the analysis has something to find.

| Table | Rows | Purpose |
|---|---|---|
| `customers` | 2,000 | city, signup date, acquisition channel, Prime flag |
| `products` | 56 | 7 categories, selling price, cost price |
| `orders` | 9,284 | date, hour, status, payment, coupon, discount, delivery fee |
| `order_items` | 27,109 | product-level lines of every order |
| `deliveries` | 8,820 | delivery minutes + customer rating |

```
customers (1) ───< orders (1) ───< order_items >─── (1) products
                      └─── (1) deliveries
```

## 3. Folder Structure
```
quickcart-postgresql-analytics/
├── data/   customers.csv  products.csv  orders.csv  order_items.csv  deliveries.csv
├── sql/
│   ├── 01_schema.sql                 create tables, keys, indexes
│   ├── 02_data_checks_and_view.sql   data quality checks + view v_order_value
│   ├── 03_business_analysis.sql      KPIs, MoM growth, category, city, coupons
│   ├── 04_customer_analytics.sql     CLV, RFM, cohort retention
│   └── 05_delivery_and_ops.sql       delivery vs rating, cancellations, market basket
├── README.md
```

## 4. How to Run in pgAdmin 4

1. **Create database:** right-click *Databases → Create → Database…* → name it `quickcart`.
2. **Create tables:** right-click `quickcart` → **Query Tool** → open `sql/01_schema.sql` → press **F5**.
3. **Import CSVs (in this order, because of foreign keys):**
   `customers → products → orders → order_items → deliveries`
   For each table: *Schemas → public → Tables →* right-click the table → **Import/Export Data…**
   - Import ON, Format **csv**, Filename = the CSV file
   - **Header = ON**, Delimiter = `,`
   - Click OK.
4. **Check + create view:** run `02_data_checks_and_view.sql`. Expected row counts: 2000 / 56 / 9284 / 27109 / 8820.
5. **Run analysis:** run `03`, `04`, `05`. In the Query Tool, select a single query and press **F5** to run just that one.

> Tip: if import says "permission denied", use pgAdmin's Import/Export wizard (it uploads from your PC) instead of `COPY` from the server path.

## 5. SQL Concepts Used

| Concept | Where |
|---|---|
| INNER / LEFT JOIN, self-join | everywhere, Q22 |
| GROUP BY, HAVING, aggregates | Q1–Q8 |
| CASE WHEN bucketing | Q7, Q12, Q13, Q17, Q21 |
| CTEs (`WITH`) | Q3, Q5, Q12–Q16 |
| View | `v_order_value` |
| Window functions: `LAG`, `DENSE_RANK`, `NTILE`, `SUM() OVER` | Q2, Q3, Q5, Q13, Q15, Q16 |
| Date functions: `TO_CHAR`, `DATE_TRUNC`, `EXTRACT`, date subtraction | Q3, Q13, Q14, Q15 |
| Data quality checks | `02_data_checks_and_view.sql` |

**Revenue definition:** `net_revenue = Σ(quantity × unit_price) − discount + delivery_fee`, counted for `Delivered` orders only.

## 6. Key Findings
Headline (Delivered orders): **8,553 orders · 1,962 customers · ₹1.11 Cr revenue · AOV ₹1,297 · 18.6% gross margin**

1. **Electronics = profit engine:** ~48% of item revenue at 25% margin vs 12–13% for grocery.
2. **Festive effect:** Oct–Nov baskets have 3.86 items vs 2.81 in other months.
3. **Evening rush:** 17:00–21:59 = 42% of all orders.
4. **Speed matters:** 25+ minute deliveries average a 2.66 rating vs ~4.0 for the rest. Bengaluru is the slowest city (17.0 min).
5. **Prime customers** order 6.27 times vs 3.72 for non-Prime, with slightly smaller baskets.
6. **Referral** is the best channel (₹5,872 per customer); Instagram Ads the weakest (₹5,399).
7. **26% of customers order just once**; month-3 retention is roughly 10–33%.
8. **440 "At Risk" customers** previously spent ~₹8,765 each — a ready win-back list.
9. **FEST20 coupon** gave ~₹3.5 lakh discount but did not increase basket size.

> Data is synthetic: the findings show the *method*, not real market facts.

## 7. Recommendations
- Cross-sell electronics (e.g. Earphones + Power Bank) in grocery baskets.
- Win-back campaign for the At-Risk segment.
- Add rider capacity in Bengaluru evenings; track "% delivered within 15 min".
- Replace flat FEST20 with a minimum-basket coupon.
- Invest more in referral.

## 8. Author
Sumedh Wankhade (Aspiring Data Analyst)
**Skills:** Excel | SQL | Python | Power BI 
