CREATE DATABASE RetailAnalysis; 
GO 
USE RetailAnalysis; 
GO 
-- Create sales_data1 table 
CREATE TABLE sales_data ( 
    invoice_no VARCHAR(50) NOT NULL, 
    customer_id VARCHAR(50) NOT NULL, 
    category VARCHAR(100) NOT NULL, 
    quantity INT NOT NULL, 
    price DECIMAL(10, 2) NOT NULL, 
    invoice_date VARCHAR(20) NOT NULL, 
    shopping_mall VARCHAR(100) NOT NULL 
); -- Create customer_data1 table 
CREATE TABLE customer_data( 
    customer_id VARCHAR(50) NOT NULL, 
    gender VARCHAR(20) NOT NULL, 
    age DECIMAL(5, 2) NULL, 
    payment_method VARCHAR(50) NOT NULL 
); -- Verify tables created 
SELECT TABLE_NAME  
FROM INFORMATION_SCHEMA.TABLES  
WHERE TABLE_TYPE = 'BASE TABLE';


-- Check row counts 
SELECT 'sales_data1' AS TableName, COUNT(*) FROM sales_data1 
UNION ALL 
SELECT 'customer_data1', COUNT(*) FROM customer_data1;
-- Preview data 
SELECT TOP 10 * FROM sales_data1; 
SELECT TOP 10 * FROM customer_data1;

-- 1.1: Check for NULL values across all columns
SELECT 
    'sales_data1' AS table_name,
    SUM(CASE WHEN invoice_no IS NULL THEN 1 ELSE 0 END) AS null_invoice_no,
    SUM(CASE WHEN customer_id IS NULL THEN 1 ELSE 0 END) AS null_customer_id,
    SUM(CASE WHEN category IS NULL THEN 1 ELSE 0 END) AS null_category,
    SUM(CASE WHEN quantity IS NULL THEN 1 ELSE 0 END) AS null_quantity,
    SUM(CASE WHEN price IS NULL THEN 1 ELSE 0 END) AS null_price,
    SUM(CASE WHEN invoice_date IS NULL THEN 1 ELSE 0 END) AS null_invoice_date,
    SUM(CASE WHEN shopping_mall IS NULL THEN 1 ELSE 0 END) AS null_shopping_mall,
    COUNT(*) AS total_records
FROM sales_data1;

-- 1.2: Check for NULL values in customer data
SELECT 
    'customer_data1' AS table_name,
    SUM(CASE WHEN customer_id IS NULL THEN 1 ELSE 0 END) AS null_customer_id,
    SUM(CASE WHEN gender IS NULL THEN 1 ELSE 0 END) AS null_gender,
    SUM(CASE WHEN age IS NULL THEN 1 ELSE 0 END) AS null_age,
    SUM(CASE WHEN payment_method IS NULL THEN 1 ELSE 0 END) AS null_payment_method,
    COUNT(*) AS total_records
FROM customer_data1;

-- 1.3: Identify and count duplicate records in sales data
SELECT 
    invoice_no,
    customer_id,
    invoice_date,
    category,
    COUNT(*) AS duplicate_count
FROM sales_data1
GROUP BY invoice_no, customer_id, invoice_date, category
HAVING COUNT(*) > 1;

-- 1.4: Check for invalid data ranges
SELECT 
    'Price Range Check' AS check_type,
    MIN(price) AS min_price,
    MAX(price) AS max_price,
    AVG(price) AS avg_price
FROM sales_data1;

SELECT 
    'Quantity Range Check' AS check_type,
    MIN(quantity) AS min_quantity,
    MAX(quantity) AS max_quantity,
    AVG(quantity) AS avg_quantity
FROM sales_data1;

SELECT 
    'Age Range Check' AS check_type,
    MIN(age) AS min_age,
    MAX(age) AS max_age,
    AVG(age) AS avg_age
FROM customer_data1
WHERE age IS NOT NULL;

-- 1.5: Handle missing age values (Option 1: Replace with average)
SELECT 
    c.customer_id,
    c.gender,
    c.age,
    CASE 
        WHEN c.age IS NULL THEN (SELECT AVG(age) FROM customer_data1 WHERE age IS NOT NULL)
        ELSE c.age 
    END AS age_cleaned
FROM customer_data1 c;


-- ================================================================================
-- SECTION 2: EXPLORATORY DATA ANALYSIS (EDA)
-- ================================================================================

-- 2.1: Overall Business Summary
SELECT 
    COUNT(DISTINCT s.invoice_no) AS total_transactions,
    COUNT(DISTINCT s.customer_id) AS unique_customers,
    SUM(s.price) AS total_revenue,
    AVG(s.price) AS avg_transaction_value,
    SUM(s.quantity) AS total_items_sold,
    AVG(s.quantity) AS avg_items_per_transaction,
    COUNT(DISTINCT s.category) AS total_categories,
    COUNT(DISTINCT s.shopping_mall) AS total_malls
FROM sales_data1 s;

-- 2.2: Category-wise Performance Analysis
SELECT 
    category,
    COUNT(*) AS total_transactions,
    SUM(quantity) AS total_quantity_sold,
    SUM(price) AS total_revenue,
    AVG(price) AS avg_transaction_value,
    MIN(price) AS min_price,
    MAX(price) AS max_price,
    CAST(SUM(price) * 100.0 / (SELECT SUM(price) FROM sales_data1) AS DECIMAL(10,2)) AS revenue_percentage
FROM sales_data1
GROUP BY category
ORDER BY total_revenue DESC;

-- 2.3: Shopping Mall Performance Analysis
SELECT 
    shopping_mall,
    COUNT(*) AS total_transactions,
    SUM(quantity) AS total_items_sold,
    SUM(price) AS total_revenue,
    AVG(price) AS avg_transaction_value,
    COUNT(DISTINCT customer_id) AS unique_customers,
    CAST(SUM(price) * 100.0 / (SELECT SUM(price) FROM sales_data1) AS DECIMAL(10,2)) AS revenue_percentage
FROM sales_data1
GROUP BY shopping_mall
ORDER BY total_revenue DESC;

-- 2.4: Time-based Analysis - Monthly Sales Trend
SELECT 
    YEAR(CONVERT(DATE, invoice_date, 105)) AS sales_year,
    MONTH(CONVERT(DATE, invoice_date, 105)) AS sales_month,
    DATENAME(MONTH, CONVERT(DATE, invoice_date, 105)) AS month_name,
    COUNT(*) AS total_transactions,
    SUM(quantity) AS total_items_sold,
    SUM(price) AS monthly_revenue,
    AVG(price) AS avg_transaction_value
FROM sales_data1
GROUP BY YEAR(CONVERT(DATE, invoice_date, 105)), 
         MONTH(CONVERT(DATE, invoice_date, 105)),
         DATENAME(MONTH, CONVERT(DATE, invoice_date, 105))
ORDER BY sales_year, sales_month;

-- 2.5: Year-over-Year Growth Analysis
WITH YearlySales AS (
    SELECT 
        YEAR(CONVERT(DATE, invoice_date, 105)) AS sales_year,
        SUM(price) AS yearly_revenue,
        COUNT(*) AS yearly_transactions
    FROM sales_data1
    GROUP BY YEAR(CONVERT(DATE, invoice_date, 105))
)
SELECT 
    sales_year,
    yearly_revenue,
    yearly_transactions,
    LAG(yearly_revenue) OVER (ORDER BY sales_year) AS previous_year_revenue,
    CAST((yearly_revenue - LAG(yearly_revenue) OVER (ORDER BY sales_year)) * 100.0 / 
         NULLIF(LAG(yearly_revenue) OVER (ORDER BY sales_year), 0) AS DECIMAL(10,2)) AS yoy_growth_percentage
FROM YearlySales
ORDER BY sales_year;


-- ================================================================================
-- SECTION 3: CUSTOMER ANALYSIS
-- ================================================================================

-- 3.1: Customer Demographics Overview
SELECT 
    c.gender,
    COUNT(DISTINCT c.customer_id) AS total_customers,
    AVG(c.age) AS avg_age,
    MIN(c.age) AS min_age,
    MAX(c.age) AS max_age,
    SUM(s.price) AS total_revenue,
    AVG(s.price) AS avg_transaction_value,
    COUNT(s.invoice_no) AS total_transactions
FROM customer_data1 c
INNER JOIN sales_data1 s ON c.customer_id = s.customer_id
WHERE c.age IS NOT NULL
GROUP BY c.gender
ORDER BY total_revenue DESC;

-- 3.2: Age Group Analysis
SELECT 
    CASE 
        WHEN c.age BETWEEN 18 AND 25 THEN '18-25'
        WHEN c.age BETWEEN 26 AND 35 THEN '26-35'
        WHEN c.age BETWEEN 36 AND 45 THEN '36-45'
        WHEN c.age BETWEEN 46 AND 55 THEN '46-55'
        WHEN c.age BETWEEN 56 AND 65 THEN '56-65'
        ELSE '65+'
    END AS age_group,
    COUNT(DISTINCT c.customer_id) AS customer_count,
    SUM(s.price) AS total_revenue,
    AVG(s.price) AS avg_transaction_value,
    COUNT(s.invoice_no) AS total_transactions,
    SUM(s.quantity) AS total_items_purchased
FROM customer_data1 c
INNER JOIN sales_data1 s ON c.customer_id = s.customer_id
WHERE c.age IS NOT NULL
GROUP BY CASE 
    WHEN c.age BETWEEN 18 AND 25 THEN '18-25'
    WHEN c.age BETWEEN 26 AND 35 THEN '26-35'
    WHEN c.age BETWEEN 36 AND 45 THEN '36-45'
    WHEN c.age BETWEEN 46 AND 55 THEN '46-55'
    WHEN c.age BETWEEN 56 AND 65 THEN '56-65'
    ELSE '65+'
END
ORDER BY total_revenue DESC;

-- 3.3: Payment Method Analysis
SELECT 
    c.payment_method,
    COUNT(*) AS total_transactions,
    COUNT(DISTINCT c.customer_id) AS unique_customers,
    SUM(s.price) AS total_revenue,
    AVG(s.price) AS avg_transaction_value,
    -- CORRECTED SUBQUERIES BELOW: Changed sales_data1 to sales_data1
    CAST(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM sales_data1) AS DECIMAL(10,2)) AS transaction_percentage,
    CAST(SUM(s.price) * 100.0 / (SELECT SUM(price) FROM sales_data1) AS DECIMAL(10,2)) AS revenue_percentage
FROM customer_data1 c
INNER JOIN sales_data1 s ON c.customer_id = s.customer_id
GROUP BY c.payment_method
ORDER BY total_revenue DESC;

-- 3.4: Gender and Category Preference
SELECT 
    c.gender,
    s.category,
    COUNT(*) AS purchase_count,
    SUM(s.price) AS total_spent,
    AVG(s.price) AS avg_transaction_value,
    SUM(s.quantity) AS total_items
FROM customer_data1 c
INNER JOIN sales_data1 s ON c.customer_id = s.customer_id
GROUP BY c.gender, s.category
ORDER BY c.gender, total_spent DESC;

-- 3.5: Payment Method by Gender
SELECT 
    c.gender,
    c.payment_method,
    COUNT(*) AS transaction_count,
    SUM(s.price) AS total_revenue,
    AVG(s.price) AS avg_transaction_value
FROM customer_data1 c
INNER JOIN sales_data1 s ON c.customer_id = s.customer_id
GROUP BY c.gender, c.payment_method
ORDER BY c.gender, total_revenue DESC;


-- ================================================================================
-- SECTION 4: PRODUCT & CATEGORY ANALYSIS
-- ================================================================================

-- 4.1: Top 10 Most Profitable Categories by Mall
WITH CategoryMallPerformance AS (
    SELECT 
        shopping_mall,
        category,
        SUM(price) AS total_revenue,
        COUNT(*) AS transaction_count,
        ROW_NUMBER() OVER (PARTITION BY shopping_mall ORDER BY SUM(price) DESC) AS rank_in_mall
    FROM sales_data1
    GROUP BY shopping_mall, category
)
SELECT 
    shopping_mall,
    category,
    total_revenue,
    transaction_count,
    rank_in_mall
FROM CategoryMallPerformance
WHERE rank_in_mall <= 3
ORDER BY shopping_mall, rank_in_mall;

-- 4.2: Category Performance by Quarter
SELECT 
    YEAR(CONVERT(DATE, invoice_date, 105)) AS sales_year,
    DATEPART(QUARTER, CONVERT(DATE, invoice_date, 105)) AS sales_quarter,
    category,
    COUNT(*) AS total_transactions,
    SUM(price) AS quarterly_revenue,
    AVG(price) AS avg_transaction_value
FROM sales_data1
GROUP BY 
    YEAR(CONVERT(DATE, invoice_date, 105)),
    DATEPART(QUARTER, CONVERT(DATE, invoice_date, 105)),
    category
ORDER BY sales_year, sales_quarter, quarterly_revenue DESC;

-- 4.3: Quantity Analysis - High vs Low Volume Products
SELECT 
    category,
    quantity,
    COUNT(*) AS frequency,
    SUM(price) AS total_revenue,
    AVG(price) AS avg_price_per_transaction
FROM sales_data1
GROUP BY category, quantity
ORDER BY category, quantity;

-- 4.4: Price Range Distribution by Category
SELECT 
    category,
    CASE 
        WHEN price < 100 THEN 'Under $100'
        WHEN price BETWEEN 100 AND 500 THEN '$100-$500'
        WHEN price BETWEEN 501 AND 1000 THEN '$501-$1000'
        WHEN price BETWEEN 1001 AND 2000 THEN '$1001-$2000'
        ELSE 'Over $2000'
    END AS price_range,
    COUNT(*) AS transaction_count,
    SUM(price) AS total_revenue,
    AVG(quantity) AS avg_quantity
FROM sales_data1
GROUP BY 
    category,
    CASE 
        WHEN price < 100 THEN 'Under $100'
        WHEN price BETWEEN 100 AND 500 THEN '$100-$500'
        WHEN price BETWEEN 501 AND 1000 THEN '$501-$1000'
        WHEN price BETWEEN 1001 AND 2000 THEN '$1001-$2000'
        ELSE 'Over $2000'
    END
ORDER BY category, 
    MIN(CASE 
        WHEN price < 100 THEN 1
        WHEN price BETWEEN 100 AND 500 THEN 2
        WHEN price BETWEEN 501 AND 1000 THEN 3
        WHEN price BETWEEN 1001 AND 2000 THEN 4
        ELSE 5
    END);


-- ================================================================================
-- SECTION 5: ADVANCED BUSINESS INSIGHTS
-- ================================================================================

-- 5.1: RFM Analysis (Recency, Frequency, Monetary) - Customer Segmentation
-- Note: Since each customer_id is unique per transaction, this is adapted
WITH CustomerMetrics AS (
    SELECT 
        c.customer_id,
        c.gender,
        c.age,
        c.payment_method,
        COUNT(s.invoice_no) AS frequency,
        SUM(s.price) AS monetary_value,
        AVG(s.price) AS avg_order_value,
        MAX(CONVERT(DATE, s.invoice_date, 105)) AS last_purchase_date
    FROM customer_data1 c
    INNER JOIN sales_data1 s ON c.customer_id = s.customer_id
    GROUP BY c.customer_id, c.gender, c.age, c.payment_method
)
SELECT 
    customer_id,
    gender,
    age,
    payment_method,
    frequency,
    monetary_value,
    avg_order_value,
    last_purchase_date,
    DATEDIFF(DAY, last_purchase_date, '2023-03-08') AS days_since_last_purchase
FROM CustomerMetrics
ORDER BY monetary_value DESC;

-- 5.2: Shopping Mall Comparison Matrix
SELECT 
    shopping_mall,
    COUNT(*) AS total_transactions,
    COUNT(DISTINCT customer_id) AS unique_customers,
    SUM(price) AS total_revenue,
    AVG(price) AS avg_transaction_value,
    SUM(quantity) AS total_items_sold,
    AVG(quantity) AS avg_items_per_transaction,
    COUNT(DISTINCT category) AS categories_sold,
    MIN(CONVERT(DATE, invoice_date, 105)) AS first_transaction_date,
    MAX(CONVERT(DATE, invoice_date, 105)) AS last_transaction_date
FROM sales_data1
GROUP BY shopping_mall
ORDER BY total_revenue DESC;

-- 5.3: Peak Sales Hours/Days Analysis (Day of Week)
SELECT 
    DATENAME(WEEKDAY, CONVERT(DATE, invoice_date, 105)) AS day_of_week,
    DATEPART(WEEKDAY, CONVERT(DATE, invoice_date, 105)) AS day_number,
    COUNT(*) AS total_transactions,
    SUM(price) AS total_revenue,
    AVG(price) AS avg_transaction_value
FROM sales_data1
GROUP BY 
    DATENAME(WEEKDAY, CONVERT(DATE, invoice_date, 105)),
    DATEPART(WEEKDAY, CONVERT(DATE, invoice_date, 105))
ORDER BY day_number;

-- 5.4: Cross-Category Purchase Analysis
SELECT 
    c1.category AS category_1,
    c2.category AS category_2,
    COUNT(*) AS co_occurrence_count
FROM sales_data1 c1
INNER JOIN sales_data1 c2 
    ON c1.customer_id = c2.customer_id 
    AND c1.category < c2.category
    AND CONVERT(DATE, c1.invoice_date, 105) = CONVERT(DATE, c2.invoice_date, 105)
GROUP BY c1.category, c2.category
HAVING COUNT(*) > 10
ORDER BY co_occurrence_count DESC;

-- 5.5: Monthly Revenue Comparison with Moving Average
WITH MonthlyRevenue AS (
    SELECT 
        YEAR(CONVERT(DATE, invoice_date, 105)) AS sales_year,
        MONTH(CONVERT(DATE, invoice_date, 105)) AS sales_month,
        SUM(price) AS monthly_revenue
    FROM sales_data1
    GROUP BY 
        YEAR(CONVERT(DATE, invoice_date, 105)),
        MONTH(CONVERT(DATE, invoice_date, 105))
)
SELECT 
    sales_year,
    sales_month,
    monthly_revenue,
    AVG(monthly_revenue) OVER (
        ORDER BY sales_year, sales_month 
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ) AS moving_avg_3months,
    monthly_revenue - LAG(monthly_revenue) OVER (ORDER BY sales_year, sales_month) AS month_over_month_change
FROM MonthlyRevenue
ORDER BY sales_year, sales_month;


-- ================================================================================
-- SECTION 6: KPI CALCULATIONS
-- ================================================================================

-- 6.1: Key Performance Indicators Dashboard
WITH TotalMetrics AS (
    SELECT 
        SUM(price) AS total_revenue,
        COUNT(DISTINCT customer_id) AS total_customers,
        COUNT(*) AS total_transactions
    FROM sales_data1
)
SELECT 
    'Total Revenue' AS kpi_name,
    CAST(total_revenue AS DECIMAL(15,2)) AS kpi_value,
    'USD' AS unit
FROM TotalMetrics
UNION ALL
SELECT 
    'Average Transaction Value',
    CAST((SELECT AVG(price) FROM sales_data1) AS DECIMAL(15,2)),
    'USD'
UNION ALL
SELECT 
    'Total Transactions',
    CAST((SELECT COUNT(*) FROM sales_data1) AS DECIMAL(15,2)),
    'Count'
UNION ALL
SELECT 
    'Unique Customers',
    CAST((SELECT COUNT(DISTINCT customer_id) FROM sales_data1) AS DECIMAL(15,2)),
    'Count'
UNION ALL
SELECT 
    'Average Items Per Transaction',
    CAST((SELECT AVG(quantity) FROM sales_data1) AS DECIMAL(15,2)),
    'Items'
UNION ALL
SELECT 
    'Customer Retention Rate',
    CAST(0.00 AS DECIMAL(15,2)),
    'Percentage (Not Applicable - Unique Customers)';

-- 6.2: Sales Conversion Metrics by Category
SELECT 
    category,
    COUNT(*) AS total_visits,
    SUM(CASE WHEN price > 0 THEN 1 ELSE 0 END) AS successful_transactions,
    CAST(SUM(CASE WHEN price > 0 THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS DECIMAL(10,2)) AS conversion_rate,
    AVG(price) AS avg_transaction_value,
    SUM(price) AS total_revenue
FROM sales_data1
GROUP BY category
ORDER BY conversion_rate DESC;

-- 6.3: Customer Lifetime Value (CLV) by Segment
SELECT 
    c.gender,
    CASE 
        WHEN c.age BETWEEN 18 AND 35 THEN 'Young Adults (18-35)'
        WHEN c.age BETWEEN 36 AND 50 THEN 'Middle Age (36-50)'
        ELSE 'Senior (50+)'
    END AS age_segment,
    COUNT(DISTINCT c.customer_id) AS customer_count,
    SUM(s.price) AS total_revenue,
    AVG(s.price) AS avg_transaction_value,
    SUM(s.price) / COUNT(DISTINCT c.customer_id) AS avg_customer_lifetime_value
FROM customer_data1 c
INNER JOIN sales_data1 s ON c.customer_id = s.customer_id
WHERE c.age IS NOT NULL
GROUP BY 
    c.gender,
    CASE 
        WHEN c.age BETWEEN 18 AND 35 THEN 'Young Adults (18-35)'
        WHEN c.age BETWEEN 36 AND 50 THEN 'Middle Age (36-50)'
        ELSE 'Senior (50+)'
    END
ORDER BY avg_customer_lifetime_value DESC;


-- ================================================================================
-- SECTION 7: ACTIONABLE BUSINESS RECOMMENDATIONS QUERIES
-- ================================================================================

-- 7.1: Underperforming Categories by Mall (Bottom 20% Revenue)
WITH MallCategoryRevenue AS (
    SELECT 
        shopping_mall,
        category,
        SUM(price) AS category_revenue,
        PERCENT_RANK() OVER (PARTITION BY shopping_mall ORDER BY SUM(price)) AS revenue_percentile
    FROM sales_data1
    GROUP BY shopping_mall, category
)
SELECT 
    shopping_mall,
    category,
    CAST(category_revenue AS DECIMAL(15,2)) AS revenue,
    CAST(revenue_percentile * 100 AS DECIMAL(5,2)) AS percentile_rank
FROM MallCategoryRevenue
WHERE revenue_percentile <= 0.20
ORDER BY shopping_mall, revenue;

-- 7.2: High-Value Customer Identification
WITH CustomerValue AS (
    SELECT 
        s.customer_id,
        c.gender,
        c.age,
        c.payment_method,
        SUM(s.price) AS total_spent,
        COUNT(*) AS transaction_count,
        AVG(s.price) AS avg_transaction_value
    FROM sales_data1 s
    INNER JOIN customer_data1 c ON s.customer_id = c.customer_id
    GROUP BY s.customer_id, c.gender, c.age, c.payment_method
)
SELECT TOP 100
    customer_id,
    gender,
    age,
    payment_method,
    CAST(total_spent AS DECIMAL(15,2)) AS total_spent,
    transaction_count,
    CAST(avg_transaction_value AS DECIMAL(15,2)) AS avg_transaction_value,
    CASE 
        WHEN total_spent >= (SELECT DISTINCT PERCENTILE_CONT(0.90) WITHIN GROUP (ORDER BY total_spent) OVER () FROM CustomerValue) 
        THEN 'VIP'
        WHEN total_spent >= (SELECT DISTINCT PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY total_spent) OVER () FROM CustomerValue)
        THEN 'High Value'
        ELSE 'Standard'
    END AS customer_segment
FROM CustomerValue
ORDER BY total_spent DESC;

-- 7.3: Seasonal Trend Analysis for Inventory Planning
SELECT 
    YEAR(CONVERT(DATE, invoice_date, 105)) AS sales_year,
    MONTH(CONVERT(DATE, invoice_date, 105)) AS sales_month,
    DATENAME(MONTH, CONVERT(DATE, invoice_date, 105)) AS month_name,
    category,
    SUM(quantity) AS total_quantity_sold,
    SUM(price) AS monthly_revenue,
    AVG(price) AS avg_transaction_value
FROM sales_data1
GROUP BY 
    YEAR(CONVERT(DATE, invoice_date, 105)),
    MONTH(CONVERT(DATE, invoice_date, 105)),
    DATENAME(MONTH, CONVERT(DATE, invoice_date, 105)),
    category
ORDER BY category, sales_year, sales_month;

-- 7.4: Payment Method Adoption Trend
SELECT 
    YEAR(CONVERT(DATE, s.invoice_date, 105)) AS sales_year,
    MONTH(CONVERT(DATE, s.invoice_date, 105)) AS sales_month,
    c.payment_method,
    COUNT(*) AS transaction_count,
    SUM(s.price) AS revenue,
    CAST(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (
        PARTITION BY YEAR(CONVERT(DATE, s.invoice_date, 105)), 
                     MONTH(CONVERT(DATE, s.invoice_date, 105))
    ) AS DECIMAL(10,2)) AS percentage_of_monthly_transactions
FROM sales_data1 s
INNER JOIN customer_data1 c ON s.customer_id = c.customer_id
GROUP BY 
    YEAR(CONVERT(DATE, s.invoice_date, 105)),
    MONTH(CONVERT(DATE, s.invoice_date, 105)),
    c.payment_method
ORDER BY sales_year, sales_month, transaction_count DESC;


-- ================================================================================
-- SECTION 8: DATA EXPORT QUERIES FOR VISUALIZATION
-- ================================================================================

-- 8.1: Export Monthly Sales Data for Dashboard
SELECT 
    YEAR(CONVERT(DATE, invoice_date, 105)) AS Year,
    MONTH(CONVERT(DATE, invoice_date, 105)) AS Month,
    DATENAME(MONTH, CONVERT(DATE, invoice_date, 105)) AS MonthName,
    category AS Category,
    shopping_mall AS ShoppingMall,
    COUNT(*) AS TotalTransactions,
    SUM(quantity) AS TotalQuantity,
    CAST(SUM(price) AS DECIMAL(15,2)) AS TotalRevenue,
    CAST(AVG(price) AS DECIMAL(10,2)) AS AvgTransactionValue
FROM sales_data1
GROUP BY 
    YEAR(CONVERT(DATE, invoice_date, 105)),
    MONTH(CONVERT(DATE, invoice_date, 105)),
    DATENAME(MONTH, CONVERT(DATE, invoice_date, 105)),
    category,
    shopping_mall
ORDER BY Year, Month, Category;

-- 8.2: Export Customer Demographics for Segmentation
SELECT 
    c.customer_id AS CustomerID,
    c.gender AS Gender,
    c.age AS Age,
    CASE 
        WHEN c.age BETWEEN 18 AND 25 THEN '18-25'
        WHEN c.age BETWEEN 26 AND 35 THEN '26-35'
        WHEN c.age BETWEEN 36 AND 45 THEN '36-45'
        WHEN c.age BETWEEN 46 AND 55 THEN '46-55'
        WHEN c.age BETWEEN 56 AND 65 THEN '56-65'
        ELSE '65+'
    END AS AgeGroup,
    c.payment_method AS PaymentMethod,
    COUNT(s.invoice_no) AS TotalTransactions,
    CAST(SUM(s.price) AS DECIMAL(15,2)) AS TotalSpent,
    CAST(AVG(s.price) AS DECIMAL(10,2)) AS AvgTransactionValue,
    SUM(s.quantity) AS TotalItemsPurchased
FROM customer_data1 c
INNER JOIN sales_data1 s ON c.customer_id = s.customer_id
WHERE c.age IS NOT NULL
GROUP BY 
    c.customer_id,
    c.gender,
    c.age,
    CASE 
        WHEN c.age BETWEEN 18 AND 25 THEN '18-25'
        WHEN c.age BETWEEN 26 AND 35 THEN '26-35'
        WHEN c.age BETWEEN 36 AND 45 THEN '36-45'
        WHEN c.age BETWEEN 46 AND 55 THEN '46-55'
        WHEN c.age BETWEEN 56 AND 65 THEN '56-65'
        ELSE '65+'
    END,
    c.payment_method;


-- ================================================================================
-- END OF SQL QUERIES
-- For questions or improvements, refer to project documentation
-- ================================================================================
