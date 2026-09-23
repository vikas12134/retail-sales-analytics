-- ============================================================================
-- Script: 02_load_staging_data.sql
-- Description: Truncates staging tables and loads cleaned CSV data using BULK INSERT.
-- Project: Retail Sales & Customer Analytics (Aura Retail Group)
-- Author: Data Analytics Team
-- Date: 2026-09-06
-- ============================================================================
-- IMPORTANT CONFIGURATION INSTRUCTIONS:
-- 1. Do NOT execute this script without updating the placeholder file paths below.
-- 2. BULK INSERT executes on the SQL Server host engine, so the file paths must be
--    ABSOLUTE Windows filesystem paths accessible to the SQL Server service account.
-- 3. Replace the placeholder token 'D:\Data_Analytics\retail-sales-analytics' with the absolute
--    path to your project repository on your machine.
--    Example:
--      Replace: 'D:\Data_Analytics\retail-sales-analytics\data\cleaned\date.csv'
--      With:    'D:\Data_Analytics\retail-sales-analytics\data\cleaned\date.csv'
-- ============================================================================

USE [RetailSalesAnalytics];
GO

SET NOCOUNT ON;

PRINT '============================================================================';
PRINT '            RETAIL SALES ANALYTICS - STAGING DATA LOAD PROCESS              ';
PRINT '============================================================================';
PRINT 'Execution Timestamp: ' + CONVERT(VARCHAR(30), GETDATE(), 120);
PRINT '';

-- ============================================================================
-- STEP 1: TRUNCATE STAGING TABLES (ENSURE IDEMPOTENCY)
-- ============================================================================
PRINT 'Truncating existing data from staging tables...';

TRUNCATE TABLE staging.stg_Date;
TRUNCATE TABLE staging.stg_Customer;
TRUNCATE TABLE staging.stg_Product;
TRUNCATE TABLE staging.stg_Store;
TRUNCATE TABLE staging.stg_Sales;

PRINT 'All staging tables truncated successfully.';
PRINT '';

-- ============================================================================
-- STEP 2: BULK INSERT DATA INTO STAGING TABLES
-- Option A: Static BULK INSERT statements using clearly marked placeholders.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 2.1. Load Dimension Date Staging (Expected: 731 rows)
-- ----------------------------------------------------------------------------
PRINT '----------------------------------------------------------------------------';
PRINT 'Loading [staging].[stg_Date]...';
BULK INSERT staging.stg_Date
FROM 'D:\Data_Analytics\retail-sales-analytics\data\cleaned\date.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n',
    CODEPAGE = '65001',
    TABLOCK
);
PRINT 'Completed [staging].[stg_Date] load.';
GO

-- ----------------------------------------------------------------------------
-- 2.2. Load Customer Staging (Expected: 50,000 rows)
-- ----------------------------------------------------------------------------
PRINT '----------------------------------------------------------------------------';
PRINT 'Loading [staging].[stg_Customer]...';
BULK INSERT staging.stg_Customer
FROM 'D:\Data_Analytics\retail-sales-analytics\data\cleaned\customers.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n',
    CODEPAGE = '65001',
    TABLOCK
);
PRINT 'Completed [staging].[stg_Customer] load.';
GO

-- ----------------------------------------------------------------------------
-- 2.3. Load Product Staging (Expected: 500 rows)
-- ----------------------------------------------------------------------------
PRINT '----------------------------------------------------------------------------';
PRINT 'Loading [staging].[stg_Product]...';
BULK INSERT staging.stg_Product
FROM 'D:\Data_Analytics\retail-sales-analytics\data\cleaned\products.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n',
    CODEPAGE = '65001',
    TABLOCK
);
PRINT 'Completed [staging].[stg_Product] load.';
GO

-- ----------------------------------------------------------------------------
-- 2.4. Load Store Staging (Expected: 30 rows)
-- ----------------------------------------------------------------------------
PRINT '----------------------------------------------------------------------------';
PRINT 'Loading [staging].[stg_Store]...';
BULK INSERT staging.stg_Store
FROM 'D:\Data_Analytics\retail-sales-analytics\data\cleaned\stores.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n',
    CODEPAGE = '65001',
    TABLOCK
);
PRINT 'Completed [staging].[stg_Store] load.';
GO

-- ----------------------------------------------------------------------------
-- 2.5. Load Sales Transaction Staging (Expected: 320,536 rows)
-- ----------------------------------------------------------------------------
PRINT '----------------------------------------------------------------------------';
PRINT 'Loading [staging].[stg_Sales]...';
BULK INSERT staging.stg_Sales
FROM 'D:\Data_Analytics\retail-sales-analytics\data\cleaned\sales.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n',
    CODEPAGE = '65001',
    TABLOCK
);
PRINT 'Completed [staging].[stg_Sales] load.';
GO

-- ============================================================================
-- STEP 3: LOG INGESTED STAGING ROW COUNTS
-- ============================================================================
PRINT '';
PRINT '============================================================================';
PRINT '                     STAGING LOAD ROW COUNT SUMMARY                         ';
PRINT '============================================================================';

SELECT 
    t.name AS [StagingTable],
    SUM(p.rows) AS [LoadedRowCount],
    CASE t.name
        WHEN 'stg_Date'     THEN 731
        WHEN 'stg_Customer' THEN 50000
        WHEN 'stg_Product'  THEN 500
        WHEN 'stg_Store'    THEN 30
        WHEN 'stg_Sales'    THEN 320536
        ELSE 0
    END AS [ExpectedRowCount],
    CASE 
        WHEN t.name = 'stg_Date'     AND SUM(p.rows) = 731    THEN 'MATCH'
        WHEN t.name = 'stg_Customer' AND SUM(p.rows) = 50000  THEN 'MATCH'
        WHEN t.name = 'stg_Product'  AND SUM(p.rows) = 500    THEN 'MATCH'
        WHEN t.name = 'stg_Store'    AND SUM(p.rows) = 30     THEN 'MATCH'
        WHEN t.name = 'stg_Sales'    AND SUM(p.rows) = 320536 THEN 'MATCH'
        ELSE 'MISMATCH / CHECK LOGS'
    END AS [VerificationStatus]
FROM sys.tables t
INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
INNER JOIN sys.partitions p ON t.object_id = p.object_id
WHERE s.name = 'staging'
  AND p.index_id IN (0, 1)
GROUP BY t.name
ORDER BY t.name;

PRINT '============================================================================';
PRINT 'Staging load completed. Proceed to 03_validate_staging_data.sql.';
PRINT '============================================================================';
GO



