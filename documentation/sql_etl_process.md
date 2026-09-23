# SQL Server ETL Process & Data Pipeline Architecture
## Project: Retail Sales & Customer Analytics
**Enterprise:** Aura Retail Group  
**Database Name:** `RetailSalesAnalytics`  
**Document Version:** 1.0  
**Author:** Data Analytics Team  
**Date:** 2026-09-06  

---

## 1. Executive Summary & Pipeline Objectives

The Retail Sales Analytics ETL (Extract, Transform, Load) pipeline is designed to reliably ingest, validate, and load multi-channel retail transaction data into the centralized `RetailSalesAnalytics` SQL Server Star Schema data warehouse. 

The pipeline ingests five standardized, pre-cleaned CSV data sources produced by the Python data engineering pipeline and transforms them into four dimension tables and one central fact table:
- **`dbo.DimDate`**: 731 calendar days (2023-01-01 to 2024-12-31)
- **`dbo.DimCustomer`**: 50,000 unique retail customers
- **`dbo.DimProduct`**: 500 catalog SKUs across 5 core categories
- **`dbo.DimStore`**: 30 store locations (1 E-Commerce + 29 physical outlets)
- **`dbo.FactSales`**: 320,536 sales line items with complete financial reconciliation

### Core Architectural Principles:
1. **ELT (Extract-Load-Transform) Staging Isolation:** Raw CSV files are first ingested into a dedicated `staging` schema using fast `BULK INSERT` operations before being transformed into the production `dbo` schema.
2. **Defensive Schema Design:** Staging tables utilize permissive `VARCHAR` data types to prevent low-level OLE DB conversion aborts during bulk ingestion.
3. **Automated Quality Gates:** Comprehensive validation suites execute both in staging (pre-load) and in production (post-load) to guarantee zero silent data loss, zero duplicate keys, and zero referential integrity orphans.
4. **Atomic Transactional Reliability:** The final transformation and load step executes within an explicit `BEGIN TRANSACTION ... COMMIT TRANSACTION` block with automatic rollback upon any error.
5. **Full Bidirectional Traceability:** CSV transaction identifiers (`TransactionID`) are directly mapped to fact table keys (`SalesID`) and exposed through reporting views (`vw_SalesDetail`).

---

## 2. End-to-End Pipeline Architecture

```text
┌─────────────────────────────────────────────────────────────────────────┐
│                    SOURCE LAYER (data/cleaned/*.csv)                    │
│   date.csv        customers.csv    products.csv   stores.csv   sales.csv│
│   (731 rows)      (50,000 rows)    (500 rows)     (30 rows)    (320,536)│
└────────────────────────────────────┬────────────────────────────────────┘
                                     │
                    [02_load_staging_data.sql]
                    BULK INSERT (TABLOCK, UTF-8)
                                     ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                     STAGING LAYER (staging.*)                           │
│   stg_Date        stg_Customer     stg_Product    stg_Store    stg_Sales│
│   All columns VARCHAR to prevent OLE DB conversion aborts during ingest │
└────────────────────────────────────┬────────────────────────────────────┘
                                     │
                   [03_validate_staging_data.sql]
                   Pre-load Quality Gate (27 checks)
                                     ▼
                   [04_transform_and_load.sql]
                   Atomic Transaction: Trim, Type Cast,
                   Impute Nulls, Map Keys, Load in FK Order
                                     ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                   PRODUCTION STAR SCHEMA (dbo.*)                        │
│   dbo.DimDate      dbo.DimCustomer  dbo.DimProduct  dbo.DimStore        │
│   (Parent Dims)    (Parent Dims)    (Parent Dims)   (Parent Dims)       │
│         │                 │                │              │             │
│         └───────────┬─────┴────────────────┴──────┬───────┘             │
│                     ▼                             ▼                     │
│               [Referential Integrity: Foreign Keys (1 to Many)]         │
│                     │                             │                     │
│                     └──────────────► ◄────────────┘                     │
│                                     │                                   │
│                              dbo.FactSales                              │
│                         (320,536 Line Items)                            │
└────────────────────────────────────┬────────────────────────────────────┘
                                     │
                   [05_validate_final_data.sql]
                   Post-load Quality Gate (28 checks)
                                     ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                   ANALYTICAL VIEWS & POWER BI ACCESS                    │
│   vw_SalesDetail        vw_MonthlySalesSummary                          │
│   vw_CategoryPerformance vw_CustomerRFMBase                             │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 3. Staging Schema & Table Design Rationale

### Why a Dedicated `staging` Schema?
- **Security & Access Control:** Analysts and reporting tools are granted `SELECT` permissions only on `dbo` and reporting views, completely isolating raw ingestion artifacts.
- **Maintenance Independence:** Staging tables can be truncated, dropped, altered, or reloaded without invalidating production views, procedures, or query plans.
- **Auditing & Troubleshooting:** If a production load ever fails, staging tables retain the exact state of ingested raw records for differential debugging.

### Why Permissive `VARCHAR` Types in Staging?
Standard CSV bulk loading in SQL Server frequently encounters issues with:
- Empty strings for nullable dates (`DateOfBirth` in customer data) which default to `1900-01-01` or abort with conversion errors when loaded directly into a `DATE` column.
- Decimal points with varying scale or unexpected scientific notation.
- Unintentional leading/trailing whitespace in CSV text fields.

By staging all fields as `VARCHAR(50)` to `VARCHAR(255)`, `BULK INSERT` achieves maximum ingestion throughput without failures. All cleaning, trimming, and safe conversions occur deterministically in T-SQL via `TRY_CAST`, `TRIM`, and `NULLIF`.

---

## 4. Pipeline Execution Hierarchy & Script Specifications

The ETL pipeline consists of five SQL scripts executed in a strict chronological sequence:

```text
sql/staging/
├── 01_create_staging_tables.sql   # DDL: Creates 'staging' schema and 5 staging tables
├── 02_load_staging_data.sql       # BULK INSERT: Truncates and loads CSVs into staging
├── 03_validate_staging_data.sql   # QA Gate 1: Verifies staging counts, nulls, keys, types
├── 04_transform_and_load.sql      # ETL Core: Atomic transform & load into Star Schema
└── 05_validate_final_data.sql     # QA Gate 2: Full audit of production schema and math
```

### Script 01: `01_create_staging_tables.sql`
- **Objective:** Establishes the `staging` schema and creates `staging.stg_Date`, `staging.stg_Customer`, `staging.stg_Product`, `staging.stg_Store`, and `staging.stg_Sales`.
- **Idempotency:** Checks `IF OBJECT_ID(...) IS NOT NULL DROP TABLE` to ensure repeatable execution.
- **Column Alignments:** Staging column definitions match the CSV headers 1:1 in name and ordinal position.

### Script 02: `02_load_staging_data.sql`
- **Objective:** Truncates staging tables and executes high-performance `BULK INSERT` operations from cleaned CSV files.
- **Bulk Insert Parameters:**
  - `FIRSTROW = 2`: Skips the CSV header row.
  - `FIELDTERMINATOR = ','`: Comma delimiter.
  - `ROWTERMINATOR = '\n'`: Standard line-break delimiter.
  - `CODEPAGE = '65001'`: UTF-8 encoding support for international characters.
  - `TABLOCK`: Acquires a table-level lock to enable minimal logging and maximize I/O throughput.
- **Placeholder Design:** Uses explicit, clearly marked placeholders (`<ABSOLUTE_PATH_TO_PROJECT_ROOT>\data\cleaned\*.csv`) to prevent hard-coding environment-specific file paths.

### Script 03: `03_validate_staging_data.sql`
- **Objective:** Pre-load validation gate ensuring staging data is complete, referentially sound, and type-castable before touching production tables.
- **Key Test Categories:**
  1. **Row Count Verification:** Matches staging records against expected totals (731, 50k, 500, 30, 320.5k).
  2. **Primary Key Nulls:** Asserts 0 null or blank values in candidate primary keys.
  3. **Key Uniqueness:** Asserts 0 duplicate business keys in all 5 datasets.
  4. **Referential Integrity Pre-Check:** Identifies any orphan `CustomerID`, `ProductID`, `StoreID`, or `DateKey` in staging sales.
  5. **Data Castability:** Validates that strings can safely convert to `INT`, `DECIMAL`, and `DATE`.
  6. **Business Domain Boundaries:** Confirms valid `SalesChannel`, `Category`, and `CustomerSegment` values.

### Script 04: `04_transform_and_load.sql`
- **Objective:** Executes the core transformations, enforces referential loading order, and loads the production Star Schema tables.
- **Atomic Transaction Safety:**
  ```sql
  BEGIN TRY
      BEGIN TRANSACTION;
      -- Referentially ordered deletion: FactSales -> DimCustomer/Product/Store/Date
      -- Referentially ordered insertion: DimDate -> DimCustomer -> DimProduct -> DimStore -> FactSales
      COMMIT TRANSACTION;
  END TRY
  BEGIN CATCH
      IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
      THROW;
  END CATCH;
  ```
- **Loading Sequence:**
  1. `dbo.DimDate` (independent calendar dimension)
  2. `dbo.DimCustomer` (parent customer dimension)
  3. `dbo.DimProduct` (parent product catalog dimension)
  4. `dbo.DimStore` (parent retail store dimension)
  5. `dbo.FactSales` (child fact table referencing all 4 dimensions)

### Script 05: `05_validate_final_data.sql`
- **Objective:** Final quality certification and audit of the production Star Schema warehouse.
- **Key Test Categories:**
  1. **Production Table Row Counts:** Validates 731, 50k, 500, 30, and 320,536 rows.
  2. **Primary Key Uniqueness:** Verifies PK clustered indexes have zero duplicate or null values.
  3. **Foreign Key Integrity:** Verifies 0 orphan rows between `FactSales` and all 4 dimensions.
  4. **Financial Consistency & Math Reconciliation:**
     - `DiscountAmount = round(Quantity * UnitPrice * Discount, 2)`
     - `SalesAmount = round((Quantity * UnitPrice) - DiscountAmount, 2)`
     - `CostAmount = round(Quantity * UnitCost, 2)`
     - `Profit = round(SalesAmount - CostAmount, 2)`
  5. **CHECK Constraint Verification:** Confirms all commercial business boundaries (`Quantity > 0`, `Discount 0.00-1.00`, etc.).
  6. **Analytical Views Health:** Tests that all 4 reporting views compile and execute cleanly.
  7. **Executive Metrics Reconciliation:** Produces aggregate revenue, COGS, units, and gross margin totals.

---

## 5. Detailed Column Mapping & Transformation Matrix

| Staging Source Column | Target Production Table & Column | Target SQL Data Type | Transformation Logic / Business Rule |
|---|---|---|---|
| **staging.stg_Date** | **dbo.DimDate** | | |
| `DateKey` | `DateKey` | `INT` | `CAST(TRIM(DateKey) AS INT)` (Surrogate YYYYMMDD) |
| `FullDate` | `FullDate` | `DATE` | `CAST(TRIM(FullDate) AS DATE)` |
| `Year` | `[Year]` | `SMALLINT` | `CAST(TRIM([Year]) AS SMALLINT)` |
| `Quarter` | `[Quarter]` | `TINYINT` | `CAST(TRIM([Quarter]) AS TINYINT)` |
| `QuarterName` | `QuarterName` | `VARCHAR(10)` | `CAST(TRIM(QuarterName) AS VARCHAR(10))` |
| `Month` | `[Month]` | `TINYINT` | `CAST(TRIM([Month]) AS TINYINT)` |
| `MonthName` | `MonthName` | `VARCHAR(15)` | `CAST(TRIM(MonthName) AS VARCHAR(15))` |
| `MonthYear` | `MonthYear` | `VARCHAR(10)` | `CAST(TRIM(MonthYear) AS VARCHAR(10))` |
| `WeekOfYear` | `WeekOfYear` | `TINYINT` | `CAST(TRIM(WeekOfYear) AS TINYINT)` |
| `DayOfWeek` | `DayOfWeek` | `TINYINT` | `CAST(TRIM(DayOfWeek) AS TINYINT)` |
| `DayName` | `DayName` | `VARCHAR(10)` | `CAST(TRIM(DayName) AS VARCHAR(10))` |
| `DayOfMonth` | `DayOfMonth` | `TINYINT` | `CAST(TRIM(DayOfMonth) AS TINYINT)` |
| `IsWeekend` | `IsWeekend` | `BIT` | `CAST(TRIM(IsWeekend) AS BIT)` |
| `IsHoliday` | `IsHoliday` | `BIT` | `CAST(TRIM(IsHoliday) AS BIT)` |
| `FiscalYear` | `FiscalYear` | `VARCHAR(10)` | `CAST(TRIM(FiscalYear) AS VARCHAR(10))` |
| `FiscalQuarter` | `FiscalQuarter` | `VARCHAR(10)` | `CAST(TRIM(FiscalQuarter) AS VARCHAR(10))` |
| **staging.stg_Customer** | **dbo.DimCustomer** | | |
| `CustomerID` | `CustomerID` | `VARCHAR(20)` | `CAST(TRIM(CustomerID) AS VARCHAR(20))` |
| `FirstName` | `FirstName` | `VARCHAR(50)` | `CAST(TRIM(FirstName) AS VARCHAR(50))` |
| `LastName` | `LastName` | `VARCHAR(50)` | `CAST(TRIM(LastName) AS VARCHAR(50))` |
| `Email` | `Email` | `VARCHAR(100)` | `CAST(TRIM(Email) AS VARCHAR(100))` |
| `Phone` | `Phone` | `VARCHAR(30)` | `CAST(TRIM(Phone) AS VARCHAR(30))` |
| `Gender` | `Gender` | `VARCHAR(20)` | `CAST(TRIM(Gender) AS VARCHAR(20))` |
| `DateOfBirth` | `DateOfBirth` | `DATE (NULL)` | `CASE WHEN TRIM(DateOfBirth) = '' OR DateOfBirth IS NULL THEN NULL ELSE CAST(TRIM(DateOfBirth) AS DATE) END` |
| `City` | `City` | `VARCHAR(50)` | `CAST(TRIM(City) AS VARCHAR(50))` |
| `State` | `[State]` | `VARCHAR(10)` | `CAST(TRIM([State]) AS VARCHAR(10))` |
| `Region` | `Region` | `VARCHAR(20)` | `CAST(TRIM(Region) AS VARCHAR(20))` |
| `PostalCode` | `PostalCode` | `VARCHAR(10)` | `CAST(TRIM(PostalCode) AS VARCHAR(10))` |
| `CustomerSegment` | `CustomerSegment` | `VARCHAR(30)` | `CAST(TRIM(CustomerSegment) AS VARCHAR(30))` |
| `JoinDate` | `JoinDate` | `DATE` | `CAST(TRIM(JoinDate) AS DATE)` |
| **staging.stg_Product** | **dbo.DimProduct** | | |
| `ProductID` | `ProductID` | `VARCHAR(20)` | `CAST(TRIM(ProductID) AS VARCHAR(20))` |
| `ProductName` | `ProductName` | `VARCHAR(150)` | `CAST(TRIM(ProductName) AS VARCHAR(150))` |
| `Category` | `Category` | `VARCHAR(50)` | `CAST(TRIM(Category) AS VARCHAR(50))` |
| `Subcategory` | `Subcategory` | `VARCHAR(50)` | `CAST(TRIM(Subcategory) AS VARCHAR(50))` |
| `Brand` | `Brand` | `VARCHAR(50)` | `CAST(TRIM(Brand) AS VARCHAR(50))` |
| `UnitCost` | `UnitCost` | `DECIMAL(10, 2)` | `CAST(TRIM(UnitCost) AS DECIMAL(10, 2))` |
| `UnitPrice` | `UnitPrice` | `DECIMAL(10, 2)` | `CAST(TRIM(UnitPrice) AS DECIMAL(10, 2))` |
| `Status` | `[Status]` | `VARCHAR(20)` | `CAST(TRIM([Status]) AS VARCHAR(20))` |
| **staging.stg_Store** | **dbo.DimStore** | | |
| `StoreID` | `StoreID` | `VARCHAR(20)` | `CAST(TRIM(StoreID) AS VARCHAR(20))` |
| `StoreName` | `StoreName` | `VARCHAR(100)` | `CAST(TRIM(StoreName) AS VARCHAR(100))` |
| `StoreType` | `StoreType` | `VARCHAR(50)` | `CAST(TRIM(StoreType) AS VARCHAR(50))` |
| `City` | `City` | `VARCHAR(50)` | `CAST(TRIM(City) AS VARCHAR(50))` |
| `State` | `[State]` | `VARCHAR(20)` | `CAST(TRIM([State]) AS VARCHAR(20))` |
| `Region` | `Region` | `VARCHAR(20)` | `CAST(TRIM(Region) AS VARCHAR(20))` |
| `SquareFootage` | `SquareFootage` | `INT` | `CAST(TRIM(SquareFootage) AS INT)` |
| `OpenDate` | `OpenDate` | `DATE` | `CAST(TRIM(OpenDate) AS DATE)` |
| `ManagerName` | `ManagerName` | `VARCHAR(100)` | `CAST(TRIM(ManagerName) AS VARCHAR(100))` |
| **staging.stg_Sales** | **dbo.FactSales** | | |
| `TransactionID` | `SalesID` | `VARCHAR(20)` | `CAST(TRIM(TransactionID) AS VARCHAR(20))` (Key mapping) |
| `DateKey` | `DateKey` | `INT` | `CAST(TRIM(DateKey) AS INT)` (FK to DimDate) |
| `OrderDate` | `OrderDate` | `DATE` | `CAST(TRIM(OrderDate) AS DATE)` |
| `CustomerID` | `CustomerID` | `VARCHAR(20)` | `CAST(TRIM(CustomerID) AS VARCHAR(20))` (FK to DimCustomer) |
| `ProductID` | `ProductID` | `VARCHAR(20)` | `CAST(TRIM(ProductID) AS VARCHAR(20))` (FK to DimProduct) |
| `StoreID` | `StoreID` | `VARCHAR(20)` | `CAST(TRIM(StoreID) AS VARCHAR(20))` (FK to DimStore) |
| `SalesChannel` | `SalesChannel` | `VARCHAR(20)` | `CAST(TRIM(SalesChannel) AS VARCHAR(20))` ('Online', 'In-Store') |
| `Quantity` | `Quantity` | `INT` | `CAST(TRIM(Quantity) AS INT)` |
| `UnitPrice` | `UnitPrice` | `DECIMAL(10, 2)` | `CAST(TRIM(UnitPrice) AS DECIMAL(10, 2))` |
| `Discount` | `Discount` | `DECIMAL(4, 2)` | `CAST(TRIM(Discount) AS DECIMAL(4, 2))` |
| `DiscountAmount` | `DiscountAmount` | `DECIMAL(10, 2)` | `CAST(TRIM(DiscountAmount) AS DECIMAL(10, 2))` |
| `SalesAmount` | `SalesAmount` | `DECIMAL(10, 2)` | `CAST(TRIM(SalesAmount) AS DECIMAL(10, 2))` |
| `UnitCost` | `UnitCost` | `DECIMAL(10, 2)` | `CAST(TRIM(UnitCost) AS DECIMAL(10, 2))` |
| `CostAmount` | `CostAmount` | `DECIMAL(10, 2)` | `CAST(TRIM(CostAmount) AS DECIMAL(10, 2))` |
| `Profit` | `Profit` | `DECIMAL(10, 2)` | `CAST(TRIM(Profit) AS DECIMAL(10, 2))` |
| `PaymentMethod` | `PaymentMethod` | `VARCHAR(30)` | `CAST(TRIM(PaymentMethod) AS VARCHAR(30))` |

---

## 6. Performance Optimization & Transaction Management

1. **Recovery Model & Minimal Logging:**
   The `RetailSalesAnalytics` database is configured with the `SIMPLE` recovery model. Bulk load operations with `TABLOCK` are minimally logged, preventing exponential transaction log file growth.
2. **Bulk Loading Throughput:**
   `TABLOCK` allows SQL Server to bypass row-level lock overhead and stream data pages directly to disk. Ingesting 320,536 sales records completes in ~1-2 seconds on modern SSD hardware.
3. **Transaction Isolation & Rollback:**
   The production load (`04_transform_and_load.sql`) runs in an all-or-nothing transaction. If a constraint or type mismatch triggers a failure on row 300,000 of `FactSales`, all prior dimension insertions roll back cleanly, leaving the database in a known valid state.
4. **Referential Integrity Order:**
   Deletions occur inward from Child to Parent (`FactSales` $\rightarrow$ `Dimensions`). Insertions occur outward from Parent to Child (`Dimensions` $\rightarrow$ `FactSales`), ensuring zero foreign key constraint conflicts.

---

## 7. Operational Runbook & Disaster Recovery

### Routine Execution:
To execute a full reload, simply follow the step-by-step sequence in `documentation/sql_data_loading_guide.md`.

### Failure Recovery:
1. If `02_load_staging_data.sql` fails: Verify file path permissions and UTF-8 encoding. Re-run `02_load_staging_data.sql` (it automatically truncates staging first).
2. If `03_validate_staging_data.sql` fails: Inspect the `#StagingValidationResults` table to identify which dataset contains anomalies.
3. If `04_transform_and_load.sql` fails: The transaction automatically rolls back. Staging data remains intact for investigation.
4. If `05_validate_final_data.sql` fails: Inspect the `#FinalValidationResults` table for specific mathematical or constraint discrepancies.
