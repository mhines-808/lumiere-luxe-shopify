
--1. Total revenue and order count by month
SELECT
COUNT(*) as order_count,
SUM(total_price) as total_revenue,
FORMAT_TIMESTAMP('%Y-%m', created_at) as by_month
FROM ll_synthetic_data.ll_orders
WHERE financial_status = 'paid'
GROUP BY by_month
ORDER BY by_month;

--2. Average order value for paid orders
SELECT
AVG(total_price) as avg_order_value
FROM ll_synthetic_data.ll_orders
WHERE financial_status = 'paid'
;

-- 3. Order count by status (paid/refunded/cancelled)
SELECT
COUNT(*) as order_count,
financial_status
FROM ll_synthetic_data.ll_orders
GROUP BY financial_status
;

-- 4. New vs. repeat customers 
--    customers with exactly 1 order vs. more than 1
WITH customer_orders AS (
  SELECT
    customer_email,
    COUNT(*) AS order_count
  FROM ll_synthetic_data.ll_orders
  WHERE financial_status = 'paid'
  GROUP BY customer_email
)

SELECT
  CASE
    WHEN order_count = 1 THEN 'new'
    ELSE 'repeat'
  END AS customer_type,
  COUNT(*) AS number_of_customers
FROM customer_orders
GROUP BY customer_type;


-- 5. Sessions by device category (mobile/desktop/tablet)
SELECT
  COUNT(DISTINCT ga_session_id) as sessions_count,
  device_category
FROM ll_synthetic_data.ll_ga4_events
GROUP BY device_category
ORDER BY sessions_count DESC;

 
 -- 6. Sessions by traffic source/medium
SELECT
  traffic_source,
  traffic_medium,
  COUNT(DISTINCT ga_session_id) as sessions_count
FROM ll_synthetic_data.ll_ga4_events
GROUP BY traffic_source, traffic_medium
ORDER BY sessions_count DESC;

-- 7. Funnel counts — sessions reaching each stage (session_start → view_item → add_to_cart → begin_checkout → purchase)

SELECT
  COUNT(DISTINCT CASE WHEN event_name = 'session_start' THEN ga_session_id END) AS sessions_started,

  COUNT(DISTINCT CASE WHEN event_name = 'view_item' THEN ga_session_id END) AS sessions_viewed_item,

  COUNT(DISTINCT CASE WHEN event_name = 'add_to_cart' THEN ga_session_id END) AS sessions_added_to_cart,

  COUNT(DISTINCT CASE WHEN event_name = 'begin_checkout' THEN ga_session_id END) AS sessions_started_checkout,

  COUNT(DISTINCT CASE WHEN event_name = 'purchase' THEN ga_session_id END) AS sessions_purchased

FROM ll_synthetic_data.ll_ga4_events;


--8. Join ll_orders to ll_ga4_events on transaction_id — revenue by traffic source
SELECT 
    SUM(o.total_price) as total_revenue,
    g.traffic_source
FROM ll_synthetic_data.ll_orders o
INNER JOIN ll_synthetic_data.ll_ga4_events g
ON o.transaction_id = g.transaction_id
GROUP BY g.traffic_source
ORDER BY total_revenue DESC;


-- Create view for this one join
CREATE VIEW ll_synthetic_data.rev_by_source_view AS
SELECT 
    SUM(o.total_price) as total_revenue,
    g.traffic_source
FROM ll_synthetic_data.ll_orders o
INNER JOIN ll_synthetic_data.ll_ga4_events g
ON o.transaction_id = g.transaction_id
GROUP BY g.traffic_source
ORDER BY total_revenue DESC;