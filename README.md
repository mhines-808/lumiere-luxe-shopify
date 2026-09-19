# Lumiere Luxe — Shopify Store, Analytics Pipeline & BigQuery Dashboard

A fictional beauty ecommerce store built to test a full pipeline end to end — a Shopify storefront, GTM/GA4 tracking, a real webhook-to-database integration, and a BigQuery + Looker Studio analytics layer on top.

**Full write-up (with screenshots and key decisions):** https://formsandfunnels.com/projects/lumiere-luxe-project.html

---

## Overview

Most of my earlier projects stopped at the front end — a form, a landing page, a lead captured in a CRM. This one goes further downstream: a real storefront with real tracking, a genuine backend integration, and an actual SQL and BI layer on top, all tied to the same fictional business.

```
Shopify store (Dawn theme)
  → GTM / GA4 (storefront + checkout)
  → orders/create webhook
      → Flask app (Render) → Postgres (Neon)
  → synthetic orders + GA4-style events (Python/pandas)
      → BigQuery (ll_orders, ll_ga4_events)
      → SQL (joins, funnel, revenue analysis)
      → Looker Studio dashboard
```

## Stack

- **Shopify** — storefront, Dawn theme, 12-product catalog across 3 collections
- **Google Tag Manager / GA4** — storefront + checkout tracking
- **Flask** — webhook receiver, HMAC signature verification
- **Postgres (Neon)** — real order data from the live webhook
- **Render** — production hosting for the Flask app (gunicorn)
- **Python / pandas** — synthetic data generation
- **BigQuery** — synthetic orders + GA4-style events, SQL analysis
- **Looker Studio** — final dashboard

## Why a synthetic dataset

A dev store only produces a handful of real test orders and GA4 events — not enough to show a meaningful trend, funnel, or revenue pattern. A larger synthetic dataset was generated in Python/pandas: a set of orders and a matching set of GA4-style events, with `purchase` events carrying a `transaction_id` that ties back to a specific order. This is separate from the real webhook pipeline, which uses genuine data end to end.

## The webhook (real data)

Shopify's `orders/create` webhook fires to a small Flask app, which:

1. Verifies the request's HMAC signature against the webhook secret
2. Parses the order payload
3. Inserts it into Postgres, with line items stored as JSONB (an order can hold a variable number of products)

The app is deployed to Render with gunicorn, backed by Neon Postgres. The first pass ran locally behind ngrok, then Cloudflare Tunnel, to expose it to Shopify — both hit reliability issues on their free tiers, so the app was deployed to a real host instead, which is also closer to how this would actually run in production.

## BigQuery tables

| Table | Contents |
|---|---|
| `ll_orders` | Synthetic order data — `order_number`, `transaction_id`, `customer_email`, `total_price`, `financial_status`, `line_items` (JSON), `created_at` |
| `ll_ga4_events` | Synthetic GA4-style event data — `event_name`, `ga_session_id`, `device_category`, `traffic_source`, `traffic_medium`, `transaction_id` (on purchase events only) |
| `rev_by_source_view` | A saved view joining the two tables on `transaction_id`, for revenue by traffic source |

## Business questions & SQL

All 8 queries — covering revenue trends, order status, repeat customers, session/device breakdowns, the funnel, and the join for revenue by traffic source — are in [`queries.sql`](./queries.sql).

| # | Question |
|---|---|
| 1 | Total revenue and order count by month |
| 2 | Average order value for paid orders |
| 3 | Order count by status (paid / refunded / cancelled) |
| 4 | New vs. repeat customers |
| 5 | Sessions by device category |
| 6 | Sessions by traffic source and medium |
| 7 | Funnel counts — sessions reaching each stage |
| 8 | Revenue by traffic source (join, saved as `rev_by_source_view`) |

## Dashboard

Built in Looker Studio, connected to `ll_orders`, `ll_ga4_events`, and `rev_by_source_view`:

- KPI scorecards — total revenue, order count, average order value, total sessions
- Revenue by month (trend line)
- Order status breakdown
- Sessions by traffic source
- Funnel — sessions reaching each stage from session start through purchase
- Revenue by traffic source (from the join)

Full export: [`dashboard.pdf`](./dashboard.pdf)

## Key decisions

- **Deployed the webhook receiver instead of relying on a local tunnel.** Local tunneling tools (ngrok, Cloudflare Tunnel) hit reliability issues on their free tiers. Deploying to Render sidesteps that and is closer to how a webhook receiver would actually run in production.
- **Generated a synthetic dataset instead of relying only on real dev-store data.** A dev store realistically only produces a handful of real orders and events — not enough for meaningful trend or funnel analysis.
- **Built the dashboard in BigQuery + Looker Studio rather than Postgres + Tableau.** Both stacks are on my list to practice, deliberately split across two separate projects instead of mixing all four tools into one.
- **Stored line items as JSONB/JSON rather than flattening them into columns.** An order can contain any number of products, so a fixed set of item columns doesn't hold up.

---

Full case study with screenshots: https://formsandfunnels.com/projects/lumiere-luxe-project.html
