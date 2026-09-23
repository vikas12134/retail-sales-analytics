-- ============================================================================
-- Script Name:   04_customer_segmentation.sql
-- Task Number:   Task 8.4 - Customer Segmentation Analysis
-- Project Name:  Retail Sales & Customer Analytics (Aura Retail Group)
-- Database Name: RetailSalesAnalytics
-- Analysis Scope: Comprehensive customer segmentation including Recency, Frequency,
--                 and Monetary (RFM) modeling, quintile scoring, behavioral segment
--                 profiling, repeat vs. one-time buyer analysis, demographic
--                 segmentation (gender, age bracket), geographic distribution,
--                 loyalty tier validation, and recency/churn risk stratification.
-- Target Tables: dbo.FactSales, dbo.DimCustomer, dbo.DimDate
-- Execution Note: All queries are strictly READ-ONLY analytical SELECT queries.
-- ============================================================================

USE [RetailSalesAnalytics];
GO

-- ============================================================================
-- 1. RFM Base Metrics Calculation
-- Business Question: What are the foundational Recency, Frequency, and Monetary
--                    (RFM) metrics for each purchasing customer?
-- Methodology:
--   - Reference Date: Maximum transaction OrderDate in FactSales ('2024-12-31').
--   - Recency: Days between customer's latest order and the dataset reference date.
--   - Frequency: Total distinct sales transactions (SalesID).
--   - Monetary: Total net sales revenue (SalesAmount).
-- Target Tables: dbo.DimCustomer, dbo.FactSales
-- ============================================================================
WITH ReferenceBoundary AS (
    SELECT MAX(OrderDate) AS MaxOrderDate
    FROM dbo.FactSales
),
CustomerRFMData AS (
    SELECT 
        c.CustomerID,
        CONCAT(c.FirstName, ' ', c.LastName) AS CustomerName,
        c.CustomerSegment AS AssignedLoyaltyTier,
        c.Region,
        c.[State],
        c.JoinDate,
        MIN(f.OrderDate) AS FirstPurchaseDate,
        MAX(f.OrderDate) AS LastPurchaseDate,
        DATEDIFF(DAY, MAX(f.OrderDate), rb.MaxOrderDate) AS RecencyDays,
        COUNT(DISTINCT f.SalesID) AS OrderFrequency,
        SUM(f.Quantity) AS TotalUnitsPurchased,
        ROUND(SUM(f.SalesAmount), 2) AS MonetaryValue,
        ROUND(SUM(f.Profit), 2) AS TotalProfitContributed,
        ROUND(SUM(f.SalesAmount) / NULLIF(COUNT(DISTINCT f.SalesID), 0), 2) AS AverageOrderValue
    FROM dbo.DimCustomer c
    INNER JOIN dbo.FactSales f 
        ON c.CustomerID = f.CustomerID
    CROSS JOIN ReferenceBoundary rb
    GROUP BY 
        c.CustomerID,
        c.FirstName,
        c.LastName,
        c.CustomerSegment,
        c.Region,
        c.[State],
        c.JoinDate,
        rb.MaxOrderDate
)
SELECT 
    CustomerID,
    CustomerName,
    AssignedLoyaltyTier,
    Region,
    [State],
    JoinDate,
    FirstPurchaseDate,
    LastPurchaseDate,
    RecencyDays,
    OrderFrequency,
    TotalUnitsPurchased,
    MonetaryValue,
    TotalProfitContributed,
    AverageOrderValue
FROM CustomerRFMData
ORDER BY 
    MonetaryValue DESC;
GO

-- ============================================================================
-- 2. RFM Quintile Scoring (1 to 5)
-- Business Question: How do purchasing customers score on individual R, F, and M
--                    scales from 1 (lowest) to 5 (highest)?
-- Methodology:
--   - NTILE(5) assigns quintiles (1 = lowest tier, 5 = highest tier).
--   - Recency: LOWER RecencyDays = BETTER. Therefore ORDER BY RecencyDays DESC
--     ensures lowest days receive NTILE = 5.
--   - Frequency: HIGHER OrderFrequency = BETTER. ORDER BY OrderFrequency ASC
--     ensures highest frequency receives NTILE = 5.
--   - Monetary: HIGHER MonetaryValue = BETTER. ORDER BY MonetaryValue ASC
--     ensures highest spend receives NTILE = 5.
--   - Composite RFM: Formatted as 3-digit score string e.g. '555', '111'.
-- ============================================================================
WITH ReferenceBoundary AS (
    SELECT MAX(OrderDate) AS MaxOrderDate
    FROM dbo.FactSales
),
CustomerRFMRaw AS (
    SELECT 
        c.CustomerID,
        CONCAT(c.FirstName, ' ', c.LastName) AS CustomerName,
        c.CustomerSegment,
        DATEDIFF(DAY, MAX(f.OrderDate), rb.MaxOrderDate) AS RecencyDays,
        COUNT(DISTINCT f.SalesID) AS OrderFrequency,
        ROUND(SUM(f.SalesAmount), 2) AS MonetaryValue
    FROM dbo.DimCustomer c
    INNER JOIN dbo.FactSales f 
        ON c.CustomerID = f.CustomerID
    CROSS JOIN ReferenceBoundary rb
    GROUP BY 
        c.CustomerID,
        c.FirstName,
        c.LastName,
        c.CustomerSegment,
        rb.MaxOrderDate
),
CustomerRFMScores AS (
    SELECT 
        CustomerID,
        CustomerName,
        CustomerSegment,
        RecencyDays,
        OrderFrequency,
        MonetaryValue,
        NTILE(5) OVER (ORDER BY RecencyDays DESC) AS R_Score,
        NTILE(5) OVER (ORDER BY OrderFrequency ASC) AS F_Score,
        NTILE(5) OVER (ORDER BY MonetaryValue ASC) AS M_Score
    FROM CustomerRFMRaw
)
SELECT 
    CustomerID,
    CustomerName,
    CustomerSegment,
    RecencyDays,
    OrderFrequency,
    MonetaryValue,
    R_Score,
    F_Score,
    M_Score,
    CONCAT(R_Score, F_Score, M_Score) AS RFM_Cell,
    ROUND((R_Score + F_Score + M_Score) / 3.0, 2) AS AverageRFMScore
FROM CustomerRFMScores
ORDER BY 
    R_Score DESC,
    F_Score DESC,
    M_Score DESC;
GO

-- ============================================================================
-- 3. RFM Named Customer Segmentation
-- Business Question: What behavioral customer segment does each customer belong to
--                    based on their combined RFM quintile profile?
-- Segments Defined:
--   - Champions: High recency, high frequency, high monetary (R>=4, F>=4, M>=4)
--   - Loyal Customers: Consistent repeat buyers with strong recency (R>=3, F>=3)
--   - Potential Loyalists: Recent buyers with good spend (R>=4, F BETWEEN 2 AND 3)
--   - New Customers: Bought recently with single order (R>=4, F=1)
--   - Promising: Average recency with single order (R=3, F=1)
--   - Needing Attention: Average recency, moderate frequency/monetary (R=3, F BETWEEN 2 AND 3)
--   - About to Sleep: Below average recency, low engagement (R=2, F BETWEEN 1 AND 2)
--   - At Risk: Previously high frequency/spend who haven't bought recently (R<=2, F>=3)
--   - Can't Lose Them: High spenders who haven't bought in a long time (R<=2, F>=4, M>=4)
--   - Hibernating: Low recency, low frequency, low monetary (R<=2, F BETWEEN 1 AND 2)
--   - Lost: Lowest recency and lowest frequency/spend (R=1, F=1)
-- ============================================================================
WITH ReferenceBoundary AS (
    SELECT MAX(OrderDate) AS MaxOrderDate
    FROM dbo.FactSales
),
CustomerRFMRaw AS (
    SELECT 
        c.CustomerID,
        CONCAT(c.FirstName, ' ', c.LastName) AS CustomerName,
        c.CustomerSegment,
        c.Region,
        DATEDIFF(DAY, MAX(f.OrderDate), rb.MaxOrderDate) AS RecencyDays,
        COUNT(DISTINCT f.SalesID) AS OrderFrequency,
        ROUND(SUM(f.SalesAmount), 2) AS MonetaryValue,
        ROUND(SUM(f.Profit), 2) AS TotalProfit
    FROM dbo.DimCustomer c
    INNER JOIN dbo.FactSales f 
        ON c.CustomerID = f.CustomerID
    CROSS JOIN ReferenceBoundary rb
    GROUP BY 
        c.CustomerID,
        c.FirstName,
        c.LastName,
        c.CustomerSegment,
        c.Region,
        rb.MaxOrderDate
),
CustomerRFMScores AS (
    SELECT 
        CustomerID,
        CustomerName,
        CustomerSegment,
        Region,
        RecencyDays,
        OrderFrequency,
        MonetaryValue,
        TotalProfit,
        NTILE(5) OVER (ORDER BY RecencyDays DESC) AS R_Score,
        NTILE(5) OVER (ORDER BY OrderFrequency ASC) AS F_Score,
        NTILE(5) OVER (ORDER BY MonetaryValue ASC) AS M_Score
    FROM CustomerRFMRaw
),
CustomerSegmentMapping AS (
    SELECT 
        CustomerID,
        CustomerName,
        CustomerSegment AS AssignedLoyaltyTier,
        Region,
        RecencyDays,
        OrderFrequency,
        MonetaryValue,
        TotalProfit,
        R_Score,
        F_Score,
        M_Score,
        CONCAT(R_Score, F_Score, M_Score) AS RFM_Cell,
        CASE 
            WHEN R_Score >= 4 AND F_Score >= 4 AND M_Score >= 4 
                THEN 'Champions'
            WHEN R_Score <= 2 AND F_Score >= 4 AND M_Score >= 4 
                THEN 'Can''t Lose Them'
            WHEN R_Score >= 3 AND F_Score >= 3 
                THEN 'Loyal Customers'
            WHEN R_Score >= 4 AND F_Score BETWEEN 2 AND 3 
                THEN 'Potential Loyalists'
            WHEN R_Score >= 4 AND F_Score = 1 
                THEN 'New Customers'
            WHEN R_Score = 3 AND F_Score = 1 
                THEN 'Promising'
            WHEN R_Score = 3 AND F_Score BETWEEN 2 AND 3 
                THEN 'Customers Needing Attention'
            WHEN R_Score <= 2 AND F_Score >= 3 
                THEN 'At Risk'
            WHEN R_Score = 2 AND F_Score BETWEEN 1 AND 2 
                THEN 'About to Sleep'
            WHEN R_Score = 1 AND F_Score BETWEEN 1 AND 2 AND M_Score >= 3 
                THEN 'Hibernating'
            ELSE 'Lost / Inactive'
        END AS RFM_Segment
    FROM CustomerRFMScores
)
SELECT 
    CustomerID,
    CustomerName,
    AssignedLoyaltyTier,
    Region,
    RecencyDays,
    OrderFrequency,
    MonetaryValue,
    TotalProfit,
    R_Score,
    F_Score,
    M_Score,
    RFM_Cell,
    RFM_Segment
FROM CustomerSegmentMapping
ORDER BY 
    MonetaryValue DESC;
GO

-- ============================================================================
-- 4. RFM Segment Distribution & Strategic Summary
-- Business Question: What is the aggregate distribution of customers, total revenue,
--                    average order value, and profit across RFM segments?
-- Metrics: Customer Count, % Customer Base, Total Revenue, % Total Revenue,
--          Average Order Value, Average Recency, Average Profit per Customer.
-- ============================================================================
WITH ReferenceBoundary AS (
    SELECT MAX(OrderDate) AS MaxOrderDate
    FROM dbo.FactSales
),
CustomerRFMRaw AS (
    SELECT 
        c.CustomerID,
        DATEDIFF(DAY, MAX(f.OrderDate), rb.MaxOrderDate) AS RecencyDays,
        COUNT(DISTINCT f.SalesID) AS OrderFrequency,
        ROUND(SUM(f.SalesAmount), 2) AS MonetaryValue,
        ROUND(SUM(f.Profit), 2) AS TotalProfit
    FROM dbo.DimCustomer c
    INNER JOIN dbo.FactSales f 
        ON c.CustomerID = f.CustomerID
    CROSS JOIN ReferenceBoundary rb
    GROUP BY 
        c.CustomerID,
        rb.MaxOrderDate
),
CustomerRFMScores AS (
    SELECT 
        CustomerID,
        RecencyDays,
        OrderFrequency,
        MonetaryValue,
        TotalProfit,
        NTILE(5) OVER (ORDER BY RecencyDays DESC) AS R_Score,
        NTILE(5) OVER (ORDER BY OrderFrequency ASC) AS F_Score,
        NTILE(5) OVER (ORDER BY MonetaryValue ASC) AS M_Score
    FROM CustomerRFMRaw
),
CustomerSegmentMapping AS (
    SELECT 
        CustomerID,
        RecencyDays,
        OrderFrequency,
        MonetaryValue,
        TotalProfit,
        CASE 
            WHEN R_Score >= 4 AND F_Score >= 4 AND M_Score >= 4 
                THEN 'Champions'
            WHEN R_Score <= 2 AND F_Score >= 4 AND M_Score >= 4 
                THEN 'Can''t Lose Them'
            WHEN R_Score >= 3 AND F_Score >= 3 
                THEN 'Loyal Customers'
            WHEN R_Score >= 4 AND F_Score BETWEEN 2 AND 3 
                THEN 'Potential Loyalists'
            WHEN R_Score >= 4 AND F_Score = 1 
                THEN 'New Customers'
            WHEN R_Score = 3 AND F_Score = 1 
                THEN 'Promising'
            WHEN R_Score = 3 AND F_Score BETWEEN 2 AND 3 
                THEN 'Customers Needing Attention'
            WHEN R_Score <= 2 AND F_Score >= 3 
                THEN 'At Risk'
            WHEN R_Score = 2 AND F_Score BETWEEN 1 AND 2 
                THEN 'About to Sleep'
            WHEN R_Score = 1 AND F_Score BETWEEN 1 AND 2 AND M_Score >= 3 
                THEN 'Hibernating'
            ELSE 'Lost / Inactive'
        END AS RFM_Segment
    FROM CustomerRFMScores
),
SegmentAggregates AS (
    SELECT 
        RFM_Segment,
        COUNT(CustomerID) AS CustomerCount,
        SUM(MonetaryValue) AS TotalRevenue,
        SUM(TotalProfit) AS TotalProfit,
        SUM(OrderFrequency) AS TotalTransactions,
        AVG(RecencyDays) AS AvgRecencyDays,
        AVG(OrderFrequency) AS AvgOrderFrequency,
        AVG(MonetaryValue) AS AvgCustomerSpend
    FROM CustomerSegmentMapping
    GROUP BY 
        RFM_Segment
)
SELECT 
    RFM_Segment,
    CustomerCount,
    ROUND((CustomerCount * 100.0) / NULLIF(SUM(CustomerCount) OVER (), 0), 2) AS PctCustomerBase,
    TotalRevenue,
    ROUND((TotalRevenue * 100.0) / NULLIF(SUM(TotalRevenue) OVER (), 0), 2) AS PctTotalRevenue,
    TotalProfit,
    ROUND((TotalProfit * 100.0) / NULLIF(SUM(TotalProfit) OVER (), 0), 2) AS PctTotalProfit,
    ROUND(TotalRevenue / NULLIF(TotalTransactions, 0), 2) AS AverageOrderValue,
    ROUND(AvgRecencyDays, 1) AS AvgRecencyDays,
    ROUND(AvgOrderFrequency, 2) AS AvgFrequency,
    ROUND(AvgCustomerSpend, 2) AS AvgMonetarySpend
FROM SegmentAggregates
ORDER BY 
    TotalRevenue DESC;
GO

-- ============================================================================
-- 5. One-Time vs. Repeat Customer Analysis
-- Business Question: What proportion of customers are one-time buyers versus repeat
--                    purchasers, and what is their revenue contribution?
-- Business Metric: Repeat Customer Rate = (Repeat Buyers / Total Buyers) * 100.
-- Methodology:
--   - Non-Purchasers: 0 transactions.
--   - One-Time Buyers: Exactly 1 transaction.
--   - Repeat Buyers: 2 or more transactions.
-- Target Tables: dbo.DimCustomer, dbo.FactSales
-- ============================================================================
WITH CustomerPurchaseVolume AS (
    SELECT 
        c.CustomerID,
        COUNT(DISTINCT f.SalesID) AS OrderCount,
        COALESCE(SUM(f.SalesAmount), 0.00) AS TotalRevenue,
        COALESCE(SUM(f.Profit), 0.00) AS TotalProfit
    FROM dbo.DimCustomer c
    LEFT JOIN dbo.FactSales f 
        ON c.CustomerID = f.CustomerID
    GROUP BY 
        c.CustomerID
),
CustomerPurchaseBehavior AS (
    SELECT 
        CustomerID,
        OrderCount,
        TotalRevenue,
        TotalProfit,
        CASE 
            WHEN OrderCount = 0 THEN 'Non-Purchaser'
            WHEN OrderCount = 1 THEN 'One-Time Buyer'
            ELSE 'Repeat Buyer (2+ Orders)'
        END AS PurchaseFrequencyCategory,
        CASE 
            WHEN OrderCount = 0 THEN 3
            WHEN OrderCount = 1 THEN 2
            ELSE 1
        END AS CategorySortOrder
    FROM CustomerPurchaseVolume
),
BehaviorAggregates AS (
    SELECT 
        PurchaseFrequencyCategory,
        CategorySortOrder,
        COUNT(CustomerID) AS CustomerCount,
        SUM(TotalRevenue) AS TotalRevenue,
        SUM(TotalProfit) AS TotalProfit,
        SUM(OrderCount) AS TotalOrders
    FROM CustomerPurchaseBehavior
    GROUP BY 
        PurchaseFrequencyCategory,
        CategorySortOrder
)
SELECT 
    PurchaseFrequencyCategory,
    CustomerCount,
    ROUND((CustomerCount * 100.0) / NULLIF(SUM(CustomerCount) OVER (), 0), 2) AS PctOfTotalRegistered,
    TotalRevenue,
    ROUND((TotalRevenue * 100.0) / NULLIF(SUM(TotalRevenue) OVER (), 0), 2) AS PctOfTotalRevenue,
    TotalProfit,
    ROUND(TotalRevenue / NULLIF(TotalOrders, 0), 2) AS AverageOrderValue,
    ROUND(TotalRevenue / NULLIF(CustomerCount, 0), 2) AS RevenuePerCustomer
FROM BehaviorAggregates
ORDER BY 
    CategorySortOrder ASC;
GO

-- ============================================================================
-- 6. Repeat Customer Rate KPI Summary
-- Business Question: What is the formal Repeat Customer Rate across all purchasing
--                    customers (excluding non-purchasers)?
-- ============================================================================
WITH PurchasingCustomerOrders AS (
    SELECT 
        CustomerID,
        COUNT(DISTINCT SalesID) AS OrderCount,
        SUM(SalesAmount) AS TotalRevenue
    FROM dbo.FactSales
    GROUP BY 
        CustomerID
),
RepeatKpis AS (
    SELECT 
        COUNT(CustomerID) AS TotalPurchasingCustomers,
        SUM(CASE WHEN OrderCount = 1 THEN 1 ELSE 0 END) AS OneTimeBuyersCount,
        SUM(CASE WHEN OrderCount >= 2 THEN 1 ELSE 0 END) AS RepeatBuyersCount,
        SUM(CASE WHEN OrderCount >= 2 THEN TotalRevenue ELSE 0.00 END) AS RepeatRevenue,
        SUM(TotalRevenue) AS TotalRevenue
    FROM PurchasingCustomerOrders
)
SELECT 
    TotalPurchasingCustomers,
    OneTimeBuyersCount,
    RepeatBuyersCount,
    ROUND((RepeatBuyersCount * 100.0) / NULLIF(TotalPurchasingCustomers, 0), 2) AS RepeatCustomerRatePct,
    ROUND((RepeatRevenue * 100.0) / NULLIF(TotalRevenue, 0), 2) AS RepeatRevenueContributionPct
FROM RepeatKpis;
GO

-- ============================================================================
-- 7. Demographic Segmentation: Age Bracket Analysis
-- Business Question: How does revenue, order frequency, and average order value
--                    distribute across customer age brackets?
-- Methodology:
--   - Age calculated accurately relative to dataset benchmark ('2024-12-31').
--   - Brackets: Under 25, 25-34, 35-44, 45-54, 55-64, 65+, and Unknown.
-- Target Tables: dbo.DimCustomer, dbo.FactSales
-- ============================================================================
WITH CustomerAgeCalculation AS (
    SELECT 
        c.CustomerID,
        c.DateOfBirth,
        CASE 
            WHEN c.DateOfBirth IS NULL THEN 'Unknown'
            WHEN FLOOR(DATEDIFF(DAY, c.DateOfBirth, '2024-12-31') / 365.25) < 25 THEN 'Under 25'
            WHEN FLOOR(DATEDIFF(DAY, c.DateOfBirth, '2024-12-31') / 365.25) BETWEEN 25 AND 34 THEN '25-34'
            WHEN FLOOR(DATEDIFF(DAY, c.DateOfBirth, '2024-12-31') / 365.25) BETWEEN 35 AND 44 THEN '35-44'
            WHEN FLOOR(DATEDIFF(DAY, c.DateOfBirth, '2024-12-31') / 365.25) BETWEEN 45 AND 54 THEN '45-54'
            WHEN FLOOR(DATEDIFF(DAY, c.DateOfBirth, '2024-12-31') / 365.25) BETWEEN 55 AND 64 THEN '55-64'
            ELSE '65+'
        END AS AgeBracket,
        CASE 
            WHEN c.DateOfBirth IS NULL THEN 7
            WHEN FLOOR(DATEDIFF(DAY, c.DateOfBirth, '2024-12-31') / 365.25) < 25 THEN 1
            WHEN FLOOR(DATEDIFF(DAY, c.DateOfBirth, '2024-12-31') / 365.25) BETWEEN 25 AND 34 THEN 2
            WHEN FLOOR(DATEDIFF(DAY, c.DateOfBirth, '2024-12-31') / 365.25) BETWEEN 35 AND 44 THEN 3
            WHEN FLOOR(DATEDIFF(DAY, c.DateOfBirth, '2024-12-31') / 365.25) BETWEEN 45 AND 54 THEN 4
            WHEN FLOOR(DATEDIFF(DAY, c.DateOfBirth, '2024-12-31') / 365.25) BETWEEN 55 AND 64 THEN 5
            ELSE 6
        END AS AgeSortOrder,
        COUNT(DISTINCT f.SalesID) AS OrderCount,
        COALESCE(SUM(f.SalesAmount), 0.00) AS TotalRevenue,
        COALESCE(SUM(f.Profit), 0.00) AS TotalProfit
    FROM dbo.DimCustomer c
    LEFT JOIN dbo.FactSales f 
        ON c.CustomerID = f.CustomerID
    GROUP BY 
        c.CustomerID,
        c.DateOfBirth
),
AgeAggregates AS (
    SELECT 
        AgeBracket,
        AgeSortOrder,
        COUNT(CustomerID) AS TotalCustomers,
        SUM(CASE WHEN OrderCount > 0 THEN 1 ELSE 0 END) AS ActiveCustomers,
        SUM(OrderCount) AS TotalOrders,
        SUM(TotalRevenue) AS TotalRevenue,
        SUM(TotalProfit) AS TotalProfit
    FROM CustomerAgeCalculation
    GROUP BY 
        AgeBracket,
        AgeSortOrder
)
SELECT 
    AgeBracket,
    TotalCustomers,
    ActiveCustomers,
    ROUND((ActiveCustomers * 100.0) / NULLIF(TotalCustomers, 0), 2) AS ActivationRatePct,
    TotalRevenue,
    ROUND((TotalRevenue * 100.0) / NULLIF(SUM(TotalRevenue) OVER (), 0), 2) AS PctTotalRevenue,
    TotalProfit,
    ROUND(TotalProfit / NULLIF(TotalRevenue, 0) * 100.0, 2) AS ProfitMarginPct,
    ROUND(TotalRevenue / NULLIF(TotalOrders, 0), 2) AS AverageOrderValue,
    ROUND(TotalRevenue / NULLIF(ActiveCustomers, 0), 2) AS RevenuePerActiveCustomer
FROM AgeAggregates
ORDER BY 
    AgeSortOrder ASC;
GO

-- ============================================================================
-- 8. Demographic Segmentation: Gender Analysis
-- Business Question: What are the differences in customer count, total revenue,
--                    order volume, and profit margins between genders?
-- Target Tables: dbo.DimCustomer, dbo.FactSales
-- ============================================================================
WITH CustomerGenderSummary AS (
    SELECT 
        c.CustomerID,
        c.Gender,
        COUNT(DISTINCT f.SalesID) AS OrderCount,
        COALESCE(SUM(f.Quantity), 0) AS TotalQuantity,
        COALESCE(SUM(f.SalesAmount), 0.00) AS TotalRevenue,
        COALESCE(SUM(f.Profit), 0.00) AS TotalProfit
    FROM dbo.DimCustomer c
    LEFT JOIN dbo.FactSales f 
        ON c.CustomerID = f.CustomerID
    GROUP BY 
        c.CustomerID,
        c.Gender
),
GenderAggregates AS (
    SELECT 
        Gender,
        COUNT(CustomerID) AS TotalCustomers,
        SUM(CASE WHEN OrderCount > 0 THEN 1 ELSE 0 END) AS ActiveCustomers,
        SUM(OrderCount) AS TotalTransactions,
        SUM(TotalQuantity) AS TotalUnitsSold,
        SUM(TotalRevenue) AS TotalRevenue,
        SUM(TotalProfit) AS TotalProfit
    FROM CustomerGenderSummary
    GROUP BY 
        Gender
)
SELECT 
    Gender,
    TotalCustomers,
    ActiveCustomers,
    ROUND((TotalCustomers * 100.0) / NULLIF(SUM(TotalCustomers) OVER (), 0), 2) AS PctCustomerBase,
    TotalTransactions,
    TotalUnitsSold,
    TotalRevenue,
    ROUND((TotalRevenue * 100.0) / NULLIF(SUM(TotalRevenue) OVER (), 0), 2) AS PctTotalRevenue,
    TotalProfit,
    ROUND(TotalProfit / NULLIF(TotalRevenue, 0) * 100.0, 2) AS ProfitMarginPct,
    ROUND(TotalRevenue / NULLIF(TotalTransactions, 0), 2) AS AverageOrderValue,
    ROUND(TotalRevenue / NULLIF(ActiveCustomers, 0), 2) AS RevenuePerActiveCustomer
FROM GenderAggregates
ORDER BY 
    TotalRevenue DESC;
GO

-- ============================================================================
-- 9. Geographic Segmentation: Regional Performance
-- Business Question: How does customer distribution and purchasing behavior differ
--                    across geographic regions?
-- Target Tables: dbo.DimCustomer, dbo.FactSales
-- ============================================================================
WITH RegionalCustomerMetrics AS (
    SELECT 
        c.CustomerID,
        c.Region,
        COUNT(DISTINCT f.SalesID) AS OrderCount,
        COALESCE(SUM(f.SalesAmount), 0.00) AS TotalRevenue,
        COALESCE(SUM(f.Profit), 0.00) AS TotalProfit
    FROM dbo.DimCustomer c
    LEFT JOIN dbo.FactSales f 
        ON c.CustomerID = f.CustomerID
    GROUP BY 
        c.CustomerID,
        c.Region
),
RegionalAggregates AS (
    SELECT 
        Region,
        COUNT(CustomerID) AS TotalRegisteredCustomers,
        SUM(CASE WHEN OrderCount > 0 THEN 1 ELSE 0 END) AS ActivePurchasers,
        SUM(OrderCount) AS TotalOrders,
        SUM(TotalRevenue) AS TotalRevenue,
        SUM(TotalProfit) AS TotalProfit
    FROM RegionalCustomerMetrics
    GROUP BY 
        Region
)
SELECT 
    Region,
    TotalRegisteredCustomers,
    ActivePurchasers,
    ROUND((ActivePurchasers * 100.0) / NULLIF(TotalRegisteredCustomers, 0), 2) AS ActivePurchaserRatePct,
    TotalOrders,
    TotalRevenue,
    ROUND((TotalRevenue * 100.0) / NULLIF(SUM(TotalRevenue) OVER (), 0), 2) AS PctTotalRevenue,
    TotalProfit,
    ROUND(TotalProfit / NULLIF(TotalRevenue, 0) * 100.0, 2) AS ProfitMarginPct,
    ROUND(TotalRevenue / NULLIF(TotalOrders, 0), 2) AS AverageOrderValue,
    ROUND(TotalRevenue / NULLIF(ActivePurchasers, 0), 2) AS RevenuePerActiveCustomer
FROM RegionalAggregates
ORDER BY 
    TotalRevenue DESC;
GO

-- ============================================================================
-- 10. Loyalty Tier Alignment Analysis (CustomerSegment vs. Actual Spend)
-- Business Question: Does actual customer spending align with their assigned
--                    loyalty tier in DimCustomer (Regular, Silver, Gold, VIP Platinum)?
-- Methodology: Compare assigned tier against customer counts, total revenue,
--              average revenue, and average transaction counts.
-- Target Tables: dbo.DimCustomer, dbo.FactSales
-- ============================================================================
WITH CustomerTierPerformance AS (
    SELECT 
        c.CustomerID,
        c.CustomerSegment AS AssignedLoyaltyTier,
        COUNT(DISTINCT f.SalesID) AS OrderCount,
        COALESCE(SUM(f.SalesAmount), 0.00) AS TotalRevenue,
        COALESCE(SUM(f.Profit), 0.00) AS TotalProfit
    FROM dbo.DimCustomer c
    LEFT JOIN dbo.FactSales f 
        ON c.CustomerID = f.CustomerID
    GROUP BY 
        c.CustomerID,
        c.CustomerSegment
),
TierAggregates AS (
    SELECT 
        AssignedLoyaltyTier,
        COUNT(CustomerID) AS TotalCustomersInTier,
        SUM(CASE WHEN OrderCount > 0 THEN 1 ELSE 0 END) AS ActiveCustomersInTier,
        SUM(OrderCount) AS TotalTransactions,
        SUM(TotalRevenue) AS TotalRevenueFromTier,
        SUM(TotalProfit) AS TotalProfitFromTier
    FROM CustomerTierPerformance
    GROUP BY 
        AssignedLoyaltyTier
)
SELECT 
    AssignedLoyaltyTier,
    TotalCustomersInTier,
    ROUND((TotalCustomersInTier * 100.0) / NULLIF(SUM(TotalCustomersInTier) OVER (), 0), 2) AS PctOfTotalCustomers,
    ActiveCustomersInTier,
    TotalTransactions,
    TotalRevenueFromTier,
    ROUND((TotalRevenueFromTier * 100.0) / NULLIF(SUM(TotalRevenueFromTier) OVER (), 0), 2) AS PctOfTotalRevenue,
    TotalProfitFromTier,
    ROUND(TotalProfitFromTier / NULLIF(TotalRevenueFromTier, 0) * 100.0, 2) AS ProfitMarginPct,
    ROUND(TotalRevenueFromTier / NULLIF(TotalTransactions, 0), 2) AS AverageOrderValue,
    ROUND(TotalRevenueFromTier / NULLIF(ActiveCustomersInTier, 0), 2) AS RevenuePerActiveCustomer,
    ROUND(CAST(TotalTransactions AS FLOAT) / NULLIF(TotalCustomersInTier, 0), 2) AS AvgOrdersPerCustomer
FROM TierAggregates
ORDER BY 
    TotalRevenueFromTier DESC;
GO

-- ============================================================================
-- 11. Monetary Spend Bands (Spend Stratification)
-- Business Question: How are customers distributed across discrete spending tiers?
-- Tiers Defined:
--   - Tier 1: $10,000+       (Elite High-Spenders)
--   - Tier 2: $5,000 - $9,999 (Key Spenders)
--   - Tier 3: $2,500 - $4,999 (Mid-Tier Spenders)
--   - Tier 4: $1,000 - $2,499 (Developing Spenders)
--   - Tier 5: $1 - $999       (Entry-Level Spenders)
--   - Tier 6: $0              (Zero Spend / Inactive)
-- ============================================================================
WITH CustomerSpending AS (
    SELECT 
        c.CustomerID,
        COALESCE(SUM(f.SalesAmount), 0.00) AS TotalSpend
    FROM dbo.DimCustomer c
    LEFT JOIN dbo.FactSales f 
        ON c.CustomerID = f.CustomerID
    GROUP BY 
        c.CustomerID
),
SpendTiers AS (
    SELECT 
        CustomerID,
        TotalSpend,
        CASE 
            WHEN TotalSpend >= 10000.00 THEN 'Tier 1: $10,000+'
            WHEN TotalSpend >= 5000.00 THEN 'Tier 2: $5,000 - $9,999'
            WHEN TotalSpend >= 2500.00 THEN 'Tier 3: $2,500 - $4,999'
            WHEN TotalSpend >= 1000.00 THEN 'Tier 4: $1,000 - $2,499'
            WHEN TotalSpend > 0.00 THEN 'Tier 5: $1 - $999'
            ELSE 'Tier 6: $0 (No Purchases)'
        END AS SpendTier,
        CASE 
            WHEN TotalSpend >= 10000.00 THEN 1
            WHEN TotalSpend >= 5000.00 THEN 2
            WHEN TotalSpend >= 2500.00 THEN 3
            WHEN TotalSpend >= 1000.00 THEN 4
            WHEN TotalSpend > 0.00 THEN 5
            ELSE 6
        END AS SpendTierOrder
    FROM CustomerSpending
),
SpendTierAggregates AS (
    SELECT 
        SpendTier,
        SpendTierOrder,
        COUNT(CustomerID) AS CustomerCount,
        SUM(TotalSpend) AS TotalRevenue
    FROM SpendTiers
    GROUP BY 
        SpendTier,
        SpendTierOrder
)
SELECT 
    SpendTier,
    CustomerCount,
    ROUND((CustomerCount * 100.0) / NULLIF(SUM(CustomerCount) OVER (), 0), 2) AS PctCustomers,
    TotalRevenue,
    ROUND((TotalRevenue * 100.0) / NULLIF(SUM(TotalRevenue) OVER (), 0), 2) AS PctRevenue,
    ROUND(TotalRevenue / NULLIF(CustomerCount, 0), 2) AS AvgRevenuePerCustomer
FROM SpendTierAggregates
ORDER BY 
    SpendTierOrder ASC;
GO

-- ============================================================================
-- 12. Recency & Churn Risk Segmentation
-- Business Question: How many customers are at immediate risk of churning based
--                    on inactivity duration?
-- Methodology:
--   - Days since last purchase relative to '2024-12-31'.
--   - Active: <= 60 days
--   - Cooling Down: 61 - 120 days
--   - At Risk: 121 - 240 days
--   - Churned / Dormant: > 240 days
--   - Unconverted: Never purchased
-- Target Tables: dbo.DimCustomer, dbo.FactSales
-- ============================================================================
WITH ReferenceBoundary AS (
    SELECT MAX(OrderDate) AS MaxOrderDate
    FROM dbo.FactSales
),
CustomerRecencyInfo AS (
    SELECT 
        c.CustomerID,
        MAX(f.OrderDate) AS LastOrderDate,
        DATEDIFF(DAY, MAX(f.OrderDate), rb.MaxOrderDate) AS RecencyDays,
        COALESCE(SUM(f.SalesAmount), 0.00) AS LifetimeSpend,
        COUNT(DISTINCT f.SalesID) AS LifetimeOrders
    FROM dbo.DimCustomer c
    LEFT JOIN dbo.FactSales f 
        ON c.CustomerID = f.CustomerID
    CROSS JOIN ReferenceBoundary rb
    GROUP BY 
        c.CustomerID,
        rb.MaxOrderDate
),
ChurnRiskTiers AS (
    SELECT 
        CustomerID,
        RecencyDays,
        LifetimeSpend,
        LifetimeOrders,
        CASE 
            WHEN LastOrderDate IS NULL THEN 'Unconverted (Never Purchased)'
            WHEN RecencyDays <= 60 THEN 'Active (0-60 Days)'
            WHEN RecencyDays BETWEEN 61 AND 120 THEN 'Cooling Down (61-120 Days)'
            WHEN RecencyDays BETWEEN 121 AND 240 THEN 'At Risk (121-240 Days)'
            ELSE 'Churned / Dormant (> 240 Days)'
        END AS ChurnRiskSegment,
        CASE 
            WHEN LastOrderDate IS NULL THEN 5
            WHEN RecencyDays <= 60 THEN 1
            WHEN RecencyDays BETWEEN 61 AND 120 THEN 2
            WHEN RecencyDays BETWEEN 121 AND 240 THEN 3
            ELSE 4
        END AS ChurnRiskSortOrder
    FROM CustomerRecencyInfo
),
ChurnRiskAggregates AS (
    SELECT 
        ChurnRiskSegment,
        ChurnRiskSortOrder,
        COUNT(CustomerID) AS CustomerCount,
        SUM(LifetimeSpend) AS TotalHistoricalRevenue,
        AVG(CAST(RecencyDays AS FLOAT)) AS AvgRecencyDays
    FROM ChurnRiskTiers
    GROUP BY 
        ChurnRiskSegment,
        ChurnRiskSortOrder
)
SELECT 
    ChurnRiskSegment,
    CustomerCount,
    ROUND((CustomerCount * 100.0) / NULLIF(SUM(CustomerCount) OVER (), 0), 2) AS PctOfTotalCustomers,
    TotalHistoricalRevenue,
    ROUND((TotalHistoricalRevenue * 100.0) / NULLIF(SUM(TotalHistoricalRevenue) OVER (), 0), 2) AS PctOfHistoricalRevenue,
    ROUND(AvgRecencyDays, 1) AS AvgRecencyDays,
    ROUND(TotalHistoricalRevenue / NULLIF(CustomerCount, 0), 2) AS RevenuePerCustomerInTier
FROM ChurnRiskAggregates
ORDER BY 
    ChurnRiskSortOrder ASC;
GO

-- ============================================================================
-- 13. Customer Acquisition Cohort Analysis by Join Year
-- Business Question: How have customer acquisition cohorts evolved over time in
--                    terms of retention, purchasing volume, and lifetime value?
-- Target Tables: dbo.DimCustomer, dbo.FactSales
-- ============================================================================
WITH CustomerCohortBase AS (
    SELECT 
        c.CustomerID,
        YEAR(c.JoinDate) AS JoinYear,
        COUNT(DISTINCT f.SalesID) AS TotalOrders,
        COALESCE(SUM(f.SalesAmount), 0.00) AS TotalRevenue,
        COALESCE(SUM(f.Profit), 0.00) AS TotalProfit
    FROM dbo.DimCustomer c
    LEFT JOIN dbo.FactSales f 
        ON c.CustomerID = f.CustomerID
    GROUP BY 
        c.CustomerID,
        YEAR(c.JoinDate)
),
CohortAggregates AS (
    SELECT 
        JoinYear,
        COUNT(CustomerID) AS CohortSize,
        SUM(CASE WHEN TotalOrders > 0 THEN 1 ELSE 0 END) AS ActiveCustomers,
        SUM(TotalOrders) AS TotalOrdersPlaced,
        SUM(TotalRevenue) AS CohortTotalRevenue,
        SUM(TotalProfit) AS CohortTotalProfit
    FROM CustomerCohortBase
    GROUP BY 
        JoinYear
)
SELECT 
    JoinYear,
    CohortSize,
    ActiveCustomers,
    ROUND((ActiveCustomers * 100.0) / NULLIF(CohortSize, 0), 2) AS CohortActivationRatePct,
    TotalOrdersPlaced,
    CohortTotalRevenue,
    ROUND((CohortTotalRevenue * 100.0) / NULLIF(SUM(CohortTotalRevenue) OVER (), 0), 2) AS PctEnterpriseRevenue,
    CohortTotalProfit,
    ROUND(CohortTotalProfit / NULLIF(CohortTotalRevenue, 0) * 100.0, 2) AS ProfitMarginPct,
    ROUND(CohortTotalRevenue / NULLIF(TotalOrdersPlaced, 0), 2) AS AverageOrderValue,
    ROUND(CohortTotalRevenue / NULLIF(ActiveCustomers, 0), 2) AS RevenuePerActiveCustomer
FROM CohortAggregates
ORDER BY 
    JoinYear ASC;
GO
