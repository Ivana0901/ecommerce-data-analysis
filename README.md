# Brazilian E-Commerce Analysis | Olist Dataset

## Project Overview
This project is a portfolio-style end-to-end Data Analyst case study built on the **Brazilian E-Commerce Public Dataset by Olist** from Kaggle.

The goal is to simulate a real-world business analysis for an e-commerce company and generate insights into:

- sales performance
- customer behavior
- product performance
- geographic trends

## Tools Used
- **PostgreSQL** – database design, validation, SQL analysis
- **Python** – data analysis and visualization
- **Power BI** – dashboarding and business storytelling
- **Git/GitHub** – version control and project documentation

## Dataset
Source: Brazilian E-Commerce Public Dataset by Olist (Kaggle)

Main tables used:
- orders
- customers
- order_items
- products
- sellers
- order_payments
- order_reviews
- geolocation
- product_category_name_translation

## Project Workflow

### 1. Database Setup
- Imported all Olist tables into PostgreSQL
- Validated core relationships between tables

### 2. Data Quality Checks
Completed the following checks and fixes:

- Verified key joins across major tables
- Resolved missing product category translations
- Handled missing product categories through a clean view
- Resolved review table grain inconsistency by aggregating to order level
- Investigated geolocation grain and documented it as a dataset characteristic

### 3. Clean Views Created
- `vw_products_clean`
- `vw_order_reviews_clean`

### 4. Final Analytical View
- `vw_order_details`

This view combines:
- orders
- customers
- order_items
- products
- sellers
- review metrics

## Key Data Quality Notes

### Product category translation issue
Two product categories were missing from the translation table and were manually added.

### Missing product categories
610 products had missing categories. Since these products were actually sold and represented approximately **1.32% of sales**, they were retained and mapped to `unknown_category` in `vw_products_clean`.

### Review table grain issue
The `order_reviews` table did not always contain one row per order.  
A clean aggregated view was created to ensure one row per order with:
- review_count
- avg_review_score
- min_review_score
- max_review_score

### Geolocation note
`geolocation_zip_code_prefix` is not unique, so geolocation cannot be treated as a standard dimension table with a one-to-one key relationship.

## Repository Structure

```text
ecommerce-data-analysis/
│
├── data/
├── sql/
├── notebooks/
├── powerbi/
├── images/
└── README.md
