-- CTE: Calculate profit metrics per product
WITH ProductMetrics AS (
    SELECT 
        product_id,
        product_name,
        category,
        primary_material,
        selling_price_gbp,
        (selling_price_gbp - production_cost_gbp) AS profit_gbp,
        ROUND(((selling_price_gbp - production_cost_gbp) / selling_price_gbp) * 100, 2) AS profit_margin_pct
    FROM furniture
)
-- Main Query: Rank products by margin within category
SELECT 
    category,
    product_name,
    selling_price_gbp,
    profit_gbp,
    profit_margin_pct,
    DENSE_RANK() OVER (PARTITION BY category ORDER BY profit_margin_pct DESC) AS margin_rank_in_category
FROM ProductMetrics
ORDER BY category, margin_rank_in_category;

SELECT 
    category,
    COUNT(*) AS total_skus,
    SUM(stock_quantity) AS total_units_in_stock,
    ROUND(SUM(stock_quantity * production_cost_gbp), 2) AS capital_tied_up_gbp,
    ROUND(SUM(stock_quantity * selling_price_gbp), 2) AS potential_revenue_gbp,
    SUM(CASE WHEN stock_quantity <= 2 THEN 1 ELSE 0 END) AS low_stock_alerts
FROM furniture
GROUP BY category
ORDER BY capital_tied_up_gbp DESC;

WITH LeadTimeStats AS (
    SELECT 
        product_id,
        product_name,
        category,
        lead_time_days,
        ROUND(AVG(lead_time_days) OVER (PARTITION BY category), 1) AS category_avg_lead_time
    FROM furniture
)
SELECT 
    product_id,
    product_name,
    category,
    lead_time_days,
    category_avg_lead_time,
    ROUND(lead_time_days - category_avg_lead_time, 1) AS variance_days,
    CASE 
        WHEN lead_time_days > category_avg_lead_time THEN 'Slower than Avg'
        WHEN lead_time_days < category_avg_lead_time THEN 'Faster than Avg'
        ELSE 'On Par'
    END AS production_status
FROM LeadTimeStats
ORDER BY category, variance_days DESC;
