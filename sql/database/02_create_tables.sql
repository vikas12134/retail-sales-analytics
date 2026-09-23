-- ============================================================================
-- Script: 02_create_tables.sql
-- Description: Creates the 4 Dimension tables and 1 Central Fact table (Star Schema).
-- Project: Retail Sales & Customer Analytics (Aura Retail Group)
-- Author: Data Analytics Team
-- Date: 2026-09-05
-- ============================================================================

USE [RetailSalesAnalytics];
GO

-- ============================================================================
-- 1. DIMENSION TABLE: DimDate
-- Role: Conformed Calendar Dimension (2023-01-01 to 2024-12-31, 731 days)
-- Granularity: One row per calendar day
-- ============================================================================
IF OBJECT_ID(N'dbo.DimDate', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.DimDate (
        DateKey         INT          NOT NULL, -- YYYYMMDD integer surrogate key (e.g. 20230101)
        FullDate        DATE         NOT NULL, -- Calendar date (e.g. '2023-01-01')
        [Year]          SMALLINT     NOT NULL, -- Calendar year (e.g. 2023, 2024)
        [Quarter]       TINYINT      NOT NULL, -- Calendar quarter (1 to 4)
        QuarterName     VARCHAR(10)  NOT NULL, -- Formatted quarter label (e.g. '2023-Q1')
        [Month]         TINYINT      NOT NULL, -- Month number (1 to 12)
        MonthName       VARCHAR(15)  NOT NULL, -- Full month name (e.g. 'January')
        MonthYear       VARCHAR(10)  NOT NULL, -- Formatted month-year (e.g. 'Jan-2023')
        WeekOfYear      TINYINT      NOT NULL, -- ISO week number (1 to 53)
        DayOfWeek       TINYINT      NOT NULL, -- Day of week number (1 = Monday to 7 = Sunday)
        DayName         VARCHAR(10)  NOT NULL, -- Day name (e.g. 'Sunday', 'Monday')
        DayOfMonth      TINYINT      NOT NULL, -- Day of month (1 to 31)
        IsWeekend       BIT          NOT NULL, -- 1 = Weekend (Saturday/Sunday), 0 = Weekday
        IsHoliday       BIT          NOT NULL, -- 1 = Retail Holiday, 0 = Non-holiday
        FiscalYear      VARCHAR(10)  NOT NULL, -- Fiscal year identifier (e.g. 'FY2023')
        FiscalQuarter   VARCHAR(10)  NOT NULL, -- Fiscal quarter identifier (e.g. 'FQ1')
        CONSTRAINT PK_DimDate PRIMARY KEY CLUSTERED (DateKey)
    );
    PRINT 'Table [dbo].[DimDate] created successfully.';
END
ELSE
BEGIN
    PRINT 'Table [dbo].[DimDate] already exists. Skipping.';
END
GO


-- ============================================================================
-- 2. DIMENSION TABLE: DimCustomer
-- Role: Customer Demographics and Segmentation Dimension (50,000 customers)
-- Granularity: One row per registered retail customer
-- ============================================================================
IF OBJECT_ID(N'dbo.DimCustomer', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.DimCustomer (
        CustomerID      VARCHAR(20)  NOT NULL, -- Business Key (e.g. 'CUST-00001')
        FirstName       VARCHAR(50)  NOT NULL, -- Cleaned first name
        LastName        VARCHAR(50)  NOT NULL, -- Cleaned last name
        Email           VARCHAR(100) NOT NULL, -- Email address or 'Not Provided'
        Phone           VARCHAR(30)  NOT NULL, -- Contact phone or 'Not Provided'
        Gender          VARCHAR(20)  NOT NULL, -- 'Female', 'Male', 'Other'
        DateOfBirth     DATE         NULL,     -- Date of birth (nullable to preserve statistical age accuracy)
        City            VARCHAR(50)  NOT NULL, -- Customer city
        [State]         VARCHAR(10)  NOT NULL, -- 2-letter uppercase postal code (e.g. 'NY', 'TX')
        Region          VARCHAR(20)  NOT NULL, -- Geographic sales region ('North', 'South', 'East', 'West')
        PostalCode      VARCHAR(10)  NOT NULL, -- Standardized 5-digit ZIP code string (e.g. '07198')
        CustomerSegment VARCHAR(30)  NOT NULL, -- Loyalty tier ('Regular', 'Silver', 'Gold', 'VIP Platinum')
        JoinDate        DATE         NOT NULL, -- Account creation date
        CONSTRAINT PK_DimCustomer PRIMARY KEY CLUSTERED (CustomerID)
    );
    PRINT 'Table [dbo].[DimCustomer] created successfully.';
END
ELSE
BEGIN
    PRINT 'Table [dbo].[DimCustomer] already exists. Skipping.';
END
GO


-- ============================================================================
-- 3. DIMENSION TABLE: DimProduct
-- Role: Merchandise Catalog Dimension (500 products across 5 core categories)
-- Granularity: One row per unique product SKU
-- ============================================================================
IF OBJECT_ID(N'dbo.DimProduct', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.DimProduct (
        ProductID       VARCHAR(20)    NOT NULL, -- Product SKU Key (e.g. 'PROD-0001')
        ProductName     VARCHAR(150)   NOT NULL, -- Standardized merchandise label
        Category        VARCHAR(50)    NOT NULL, -- Core merchandise category (5 canonical domains)
        Subcategory     VARCHAR(50)    NOT NULL, -- Subcategory classification (25 classifications)
        Brand           VARCHAR(50)    NOT NULL, -- Brand manufacturer (34 brands)
        UnitCost        DECIMAL(10, 2) NOT NULL, -- Standard acquisition cost (COGS base)
        UnitPrice       DECIMAL(10, 2) NOT NULL, -- Standard retail catalog selling price
        [Status]        VARCHAR(20)    NOT NULL, -- Catalog lifecycle status ('Active')
        CONSTRAINT PK_DimProduct PRIMARY KEY CLUSTERED (ProductID)
    );
    PRINT 'Table [dbo].[DimProduct] created successfully.';
END
ELSE
BEGIN
    PRINT 'Table [dbo].[DimProduct] already exists. Skipping.';
END
GO


-- ============================================================================
-- 4. DIMENSION TABLE: DimStore
-- Role: Store Network Dimension (30 retail locations: 1 E-Commerce + 29 Physical)
-- Granularity: One row per physical retail store or digital channel
-- ============================================================================
IF OBJECT_ID(N'dbo.DimStore', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.DimStore (
        StoreID         VARCHAR(20)  NOT NULL, -- Store identifier (e.g. 'STR-01')
        StoreName       VARCHAR(100) NOT NULL, -- Standardized store name
        StoreType       VARCHAR(50)  NOT NULL, -- 'Online', 'Flagship Store', 'Mall Outlet', 'Standalone Store', 'Express Store'
        City            VARCHAR(50)  NOT NULL, -- Store physical city
        [State]         VARCHAR(20)  NOT NULL, -- Store state code or 'NATIONAL'
        Region          VARCHAR(20)  NOT NULL, -- Store operating region ('National', 'North', 'South', 'East', 'West')
        SquareFootage   INT          NOT NULL, -- Retail floor area (sq ft; 0 for Online)
        OpenDate        DATE         NOT NULL, -- Store opening date
        ManagerName     VARCHAR(100) NOT NULL, -- General manager name
        CONSTRAINT PK_DimStore PRIMARY KEY CLUSTERED (StoreID)
    );
    PRINT 'Table [dbo].[DimStore] created successfully.';
END
ELSE
BEGIN
    PRINT 'Table [dbo].[DimStore] already exists. Skipping.';
END
GO


-- ============================================================================
-- 5. FACT TABLE: FactSales
-- Role: Central Transaction Fact Table (320,536 sales transaction line items)
-- Granularity: One row per individual retail transaction item
-- Note: Contains only foreign keys, degenerate dimension attributes (channel, payment),
-- and additive numerical business facts. No redundant dimensional text attributes.
-- ============================================================================
IF OBJECT_ID(N'dbo.FactSales', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.FactSales (
        SalesID         VARCHAR(20)    NOT NULL, -- Primary Key (corresponds to cleaned TransactionID e.g. 'TXN-0000001')
        DateKey         INT            NOT NULL, -- FK to DimDate
        OrderDate       DATE           NOT NULL, -- Transaction date (for temporal partitioning/filtering)
        CustomerID      VARCHAR(20)    NOT NULL, -- FK to DimCustomer
        ProductID       VARCHAR(20)    NOT NULL, -- FK to DimProduct
        StoreID         VARCHAR(20)    NOT NULL, -- FK to DimStore
        SalesChannel    VARCHAR(20)    NOT NULL, -- Degenerate dimension: 'Online' or 'In-Store'
        Quantity        INT            NOT NULL, -- Additive fact: Units sold (>= 1)
        UnitPrice       DECIMAL(10, 2) NOT NULL, -- Unit price at sale timestamp
        Discount        DECIMAL(4, 2)  NOT NULL, -- Applied promotional discount rate (0.00 to 1.00)
        DiscountAmount  DECIMAL(10, 2) NOT NULL, -- Additive fact: Monetary discount (round(Gross * Discount, 2))
        SalesAmount     DECIMAL(10, 2) NOT NULL, -- Additive fact: Net revenue after discount
        UnitCost        DECIMAL(10, 2) NOT NULL, -- Unit cost at sale timestamp
        CostAmount      DECIMAL(10, 2) NOT NULL, -- Additive fact: Total COGS (round(Quantity * UnitCost, 2))
        Profit          DECIMAL(10, 2) NOT NULL, -- Additive fact: Net gross profit (round(Sales - Cost, 2))
        PaymentMethod   VARCHAR(30)    NOT NULL, -- Degenerate dimension: e.g. 'Credit Card', 'Cash', 'Debit Card'
        CONSTRAINT PK_FactSales PRIMARY KEY CLUSTERED (SalesID)
    );
    PRINT 'Table [dbo].[FactSales] created successfully.';
END
ELSE
BEGIN
    PRINT 'Table [dbo].[FactSales] already exists. Skipping.';
END
GO

PRINT 'All Star Schema tables (4 Dimensions + 1 Central Fact) created successfully.';
GO
