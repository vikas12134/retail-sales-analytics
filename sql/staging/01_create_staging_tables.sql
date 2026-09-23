-- ============================================================================
-- Script: 01_create_staging_tables.sql
-- Description: Creates the staging schema and staging tables for CSV data ingestion.
-- Project: Retail Sales & Customer Analytics (Aura Retail Group)
-- Author: Data Analytics Team
-- Date: 2026-09-06
-- ============================================================================

USE [RetailSalesAnalytics];
GO

-- ============================================================================
-- 1. CREATE STAGING SCHEMA
-- Purpose: Isolates raw ingestion tables from core production Star Schema tables (dbo).
-- ============================================================================
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = N'staging')
BEGIN
    EXEC('CREATE SCHEMA staging');
    PRINT 'Schema [staging] created successfully.';
END
ELSE
BEGIN
    PRINT 'Schema [staging] already exists. Skipping creation.';
END
GO

-- ============================================================================
-- 2. STAGING TABLE: staging.stg_Date
-- Source File: data/cleaned/date.csv (731 rows)
-- Note: Uses VARCHAR columns to guarantee error-free bulk loading from CSV.
-- Data types are validated and converted during the 04_transform_and_load phase.
-- ============================================================================
IF OBJECT_ID(N'staging.stg_Date', N'U') IS NOT NULL
BEGIN
    DROP TABLE staging.stg_Date;
    PRINT 'Existing [staging].[stg_Date] table dropped.';
END
GO

CREATE TABLE staging.stg_Date (
    DateKey         VARCHAR(50)  NULL,
    FullDate        VARCHAR(50)  NULL,
    [Year]          VARCHAR(50)  NULL,
    [Quarter]       VARCHAR(50)  NULL,
    QuarterName     VARCHAR(50)  NULL,
    [Month]         VARCHAR(50)  NULL,
    MonthName       VARCHAR(50)  NULL,
    MonthYear       VARCHAR(50)  NULL,
    WeekOfYear      VARCHAR(50)  NULL,
    DayOfWeek       VARCHAR(50)  NULL,
    DayName         VARCHAR(50)  NULL,
    DayOfMonth      VARCHAR(50)  NULL,
    IsWeekend       VARCHAR(50)  NULL,
    IsHoliday       VARCHAR(50)  NULL,
    FiscalYear      VARCHAR(50)  NULL,
    FiscalQuarter   VARCHAR(50)  NULL
);
PRINT 'Table [staging].[stg_Date] created successfully.';
GO


-- ============================================================================
-- 3. STAGING TABLE: staging.stg_Customer
-- Source File: data/cleaned/customers.csv (50,000 rows)
-- ============================================================================
IF OBJECT_ID(N'staging.stg_Customer', N'U') IS NOT NULL
BEGIN
    DROP TABLE staging.stg_Customer;
    PRINT 'Existing [staging].[stg_Customer] table dropped.';
END
GO

CREATE TABLE staging.stg_Customer (
    CustomerID      VARCHAR(50)  NULL,
    FirstName       VARCHAR(100) NULL,
    LastName        VARCHAR(100) NULL,
    Email           VARCHAR(150) NULL,
    Phone           VARCHAR(50)  NULL,
    Gender          VARCHAR(50)  NULL,
    DateOfBirth     VARCHAR(50)  NULL,
    City            VARCHAR(100) NULL,
    [State]         VARCHAR(50)  NULL,
    Region          VARCHAR(50)  NULL,
    PostalCode      VARCHAR(50)  NULL,
    CustomerSegment VARCHAR(50)  NULL,
    JoinDate        VARCHAR(50)  NULL
);
PRINT 'Table [staging].[stg_Customer] created successfully.';
GO


-- ============================================================================
-- 4. STAGING TABLE: staging.stg_Product
-- Source File: data/cleaned/products.csv (500 rows)
-- ============================================================================
IF OBJECT_ID(N'staging.stg_Product', N'U') IS NOT NULL
BEGIN
    DROP TABLE staging.stg_Product;
    PRINT 'Existing [staging].[stg_Product] table dropped.';
END
GO

CREATE TABLE staging.stg_Product (
    ProductID       VARCHAR(50)  NULL,
    ProductName     VARCHAR(255) NULL,
    Category        VARCHAR(100) NULL,
    Subcategory     VARCHAR(100) NULL,
    Brand           VARCHAR(100) NULL,
    UnitCost        VARCHAR(50)  NULL,
    UnitPrice       VARCHAR(50)  NULL,
    [Status]        VARCHAR(50)  NULL
);
PRINT 'Table [staging].[stg_Product] created successfully.';
GO


-- ============================================================================
-- 5. STAGING TABLE: staging.stg_Store
-- Source File: data/cleaned/stores.csv (30 rows)
-- ============================================================================
IF OBJECT_ID(N'staging.stg_Store', N'U') IS NOT NULL
BEGIN
    DROP TABLE staging.stg_Store;
    PRINT 'Existing [staging].[stg_Store] table dropped.';
END
GO

CREATE TABLE staging.stg_Store (
    StoreID         VARCHAR(50)  NULL,
    StoreName       VARCHAR(150) NULL,
    StoreType       VARCHAR(100) NULL,
    City            VARCHAR(100) NULL,
    [State]         VARCHAR(50)  NULL,
    Region          VARCHAR(50)  NULL,
    SquareFootage   VARCHAR(50)  NULL,
    OpenDate        VARCHAR(50)  NULL,
    ManagerName     VARCHAR(150) NULL
);
PRINT 'Table [staging].[stg_Store] created successfully.';
GO


-- ============================================================================
-- 6. STAGING TABLE: staging.stg_Sales
-- Source File: data/cleaned/sales.csv (320,536 rows)
-- Note: The CSV header uses 'TransactionID'; maps to 'SalesID' in dbo.FactSales.
-- ============================================================================
IF OBJECT_ID(N'staging.stg_Sales', N'U') IS NOT NULL
BEGIN
    DROP TABLE staging.stg_Sales;
    PRINT 'Existing [staging].[stg_Sales] table dropped.';
END
GO

CREATE TABLE staging.stg_Sales (
    TransactionID   VARCHAR(50)  NULL,
    DateKey         VARCHAR(50)  NULL,
    OrderDate       VARCHAR(50)  NULL,
    CustomerID      VARCHAR(50)  NULL,
    ProductID       VARCHAR(50)  NULL,
    StoreID         VARCHAR(50)  NULL,
    SalesChannel    VARCHAR(50)  NULL,
    Quantity        VARCHAR(50)  NULL,
    UnitPrice       VARCHAR(50)  NULL,
    Discount        VARCHAR(50)  NULL,
    DiscountAmount  VARCHAR(50)  NULL,
    SalesAmount     VARCHAR(50)  NULL,
    UnitCost        VARCHAR(50)  NULL,
    CostAmount      VARCHAR(50)  NULL,
    Profit          VARCHAR(50)  NULL,
    PaymentMethod   VARCHAR(50)  NULL
);
PRINT 'Table [staging].[stg_Sales] created successfully.';
GO

-- ============================================================================
-- 7. VERIFICATION SUMMARY
-- ============================================================================
PRINT '============================================================================';
PRINT 'Staging schema and all 5 staging tables created successfully:';
PRINT '  1. staging.stg_Date';
PRINT '  2. staging.stg_Customer';
PRINT '  3. staging.stg_Product';
PRINT '  4. staging.stg_Store';
PRINT '  5. staging.stg_Sales';
PRINT '============================================================================';
GO
