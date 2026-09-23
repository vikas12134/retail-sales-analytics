# Phase 8: SQL Analysis Final Report & Lineage Documentation

**Project Name:** Retail Sales & Customer Analytics  
**Enterprise Entity:** Aura Retail Group  
**Target Database:** `RetailSalesAnalytics` (Microsoft SQL Server)  
**Data Warehouse Architecture:** Kimball Star Schema (4 Conformed Dimensions + 1 Central Fact Table)  
**Analysis Author:** Data Analytics & Engineering Team  
**Phase Status:** **Phase 8 Completed & Certified**  

---

## 1. Executive Summary

The **SQL Analysis Phase (Phase 8)** represents the core analytical engine of the Retail Sales & Customer Analytics warehouse. Building upon the verified, cleansed, and referentially enforced star schema database (`RetailSalesAnalytics`), Phase 8 implements an enterprise suite of analytical T-SQL scripts to convert raw transactional data into actionable business intelligence for retail executives, category merchants, store operations managers, and marketing directors.

Across **9 modular, read-only SQL analysis scripts**, Phase 8 examines 9 distinct commercial domains:
1. **Overall Business Performance:** High-level KPIs including top-line gross revenue, net gross profit, COGS, unit volumes, and average order values.
2. **Product Performance:** SKU-level and category-level sales, unit velocity, product margin profiles, and catalog contribution shares.
3. **Sales Trends Over Time:** Multi-period longitudinal trends (monthly, quarterly, yearly), period-over-period growth rates (MoM and YoY), and historical seasonality indices.
4. **Customer Performance:** Customer lifetime spend, order frequency, loyalty tier distribution, and concentration rankings.
5. **Customer Segmentation & RFM Modeling:** Advanced behavioral quintile scoring across Recency, Frequency, and Monetary dimensions, repeat buyer dynamics, demographic cross-tabs, and cohort retention.
6. **Store Performance:** Physical vs. digital channel evaluation, revenue/profit density per square foot, and store rankings.
7. **Regional Performance:** Geographic distribution of sales, regional profit variances, intra-regional store rankings, and regional time-series trajectories.
8. **Profitability & Discount Impact:** The commercial relationship between promotional discount tiers, product margin degradation, loss-making transactions, and category elasticity.
9. **Advanced Analytical SQL:** Portfolio-grade windowing techniques, including running totals, moving averages, offset calculations (`LAG`), and customer lifecycle sequencing.

All queries are executed directly against the final validated tables (`dbo.FactSales`, `dbo.DimDate`, `dbo.DimCustomer`, `dbo.DimProduct`, `dbo.DimStore`) rather than staging tables or raw files, ensuring 100% referential integrity, standardized data types, and reconciled financial calculations.

---

## 2. Data Model Used

The analytical workload operates entirely on a central **Kimball Star Schema** deployed under the `dbo` schema in Microsoft SQL Server:

```
                  +------------------------------------+
                  |       dbo.DimDate (Calendar)       |
                  | PK: DateKey (INT, YYYYMMDD)        |
                  +-----------------+------------------+
                                    |
                                    | 1:N
                                    v
+-----------------------+         +-------------------------------+         +-----------------------+
|  dbo.DimCustomer      |  1:N    |       dbo.FactSales           |  N:1    |   dbo.DimProduct      |
|  PK: CustomerID       |-------->| PK: SalesID                   |<--------|   PK: ProductID       |
|  (Demographics, Tier) |         | FK: DateKey, CustomerID,      |         |   (Catalog, Pricing)  |
+-----------------------+         |     ProductID, StoreID        |         +-----------------------+
                                  | Degenerate: SalesChannel,     |
                                  |             PaymentMethod     |
                                  | Facts: Quantity, UnitPrice,   |
                                  |   Discount, DiscountAmount,   |
                                  |   SalesAmount, UnitCost,      |
                                  |   CostAmount, Profit          |
                                  +---------------+---------------+
                                                  ^
                                                  | N:1
                                                  |
                                  +---------------+---------------+
                                  |     dbo.DimStore (Retail)     |
                                  | PK: StoreID                   |
                                  | (Format, Region, Footprint)   |
                                  +-------------------------------+
```

### Table Specifications & Analytical Roles

| Table Name | Granularity | Key Columns Used | Analytical Purpose in Phase 8 |
|---|---|---|---|
| **`dbo.FactSales`** | One row per individual retail transaction item (320,536 rows) | `SalesID`, `DateKey`, `OrderDate`, `CustomerID`, `ProductID`, `StoreID`, `SalesChannel`, `Quantity`, `UnitPrice`, `Discount`, `DiscountAmount`, `SalesAmount`, `UnitCost`, `CostAmount`, `Profit`, `PaymentMethod` | Central transactional fact repository storing additive and semi-additive business metrics (revenue, COGS, profit, discount, quantity) and foreign keys connecting all dimensions. |
| **`dbo.DimDate`** | One row per calendar day from 2023-01-01 to 2024-12-31 (731 rows) | `DateKey`, `FullDate`, `[Year]`, `[Quarter]`, `QuarterName`, `[Month]`, `MonthName`, `MonthYear`, `WeekOfYear`, `DayOfWeek`, `DayName`, `DayOfMonth`, `IsWeekend`, `IsHoliday`, `FiscalYear`, `FiscalQuarter` | Conformed calendar dimension supporting time-series aggregation, MoM/YoY growth rate windowing, seasonal index calculations, and chronological reporting. |
| **`dbo.DimCustomer`** | One row per registered retail customer (50,000 rows) | `CustomerID`, `FirstName`, `LastName`, `Email`, `Phone`, `Gender`, `DateOfBirth`, `City`, `[State]`, `Region`, `PostalCode`, `CustomerSegment`, `JoinDate` | Customer demographics dimension enabling RFM behavioral modeling, loyalty tier validation, geographic customer segmentation, and customer lifetime value (CLV) analysis. |
| **`dbo.DimProduct`** | One row per unique merchandise SKU (500 rows) | `ProductID`, `ProductName`, `Category`, `Subcategory`, `Brand`, `UnitCost`, `UnitPrice`, `[Status]` | Merchandise catalog dimension driving category margin rollups, brand performance comparisons, catalog Pareto distribution, and price elasticity analysis. |
| **`dbo.DimStore`** | One row per physical retail store or digital channel (30 rows) | `StoreID`, `StoreName`, `StoreType`, `City`, `[State]`, `Region`, `SquareFootage`, `OpenDate`, `ManagerName` | Store network dimension enabling channel analysis (Online vs. Physical), sales territory regional rollups, and retail footprint productivity (Revenue and Profit per Sq Ft). |

---

## 3. SQL Analysis Inventory

Every analysis file residing in `sql/analysis/` is documented below with its exact file path, primary analytical focus, and business scope:

| Analysis Area | SQL Script File | Analytical Scope & Core Business Purpose |
|---|---|---|
| **Overall Business Performance** | [`01_overall_performance.sql`](file:///d:/Data_Analytics/retail-sales-analytics/sql/analysis/01_overall_performance.sql) | Baseline enterprise KPI scorecard computing total revenue, COGS, gross profit, overall profit margin percentage, total unit volume, distinct transaction volume, unique customer count, Average Order Value (AOV), and Average Selling Price (ASP). |
| **Product Performance** | [`02_product_performance.sql`](file:///d:/Data_Analytics/retail-sales-analytics/sql/analysis/02_product_performance.sql) | Comprehensive merchandise evaluation including SKU-level revenue, cost, profit, and margin; Top 10 product rankings by revenue, profit, and unit volume; category aggregations; and revenue contribution percentages using window functions. |
| **Sales Trends Analysis** | [`02_sales_trends.sql`](file:///d:/Data_Analytics/retail-sales-analytics/sql/analysis/02_sales_trends.sql) | Longitudinal temporal analysis across monthly, quarterly, and annual intervals; Month-over-Month (MoM) revenue and profit growth velocity using `LAG()`; cumulative revenue and profit running totals; calendar month seasonality indices; side-by-side Year-over-Year (YoY) comparisons; and automated peak/trough sales period identification. |
| **Customer Performance** | [`03_customer_performance.sql`](file:///d:/Data_Analytics/retail-sales-analytics/sql/analysis/03_customer_performance.sql) | Customer-level spending patterns, order frequency, Average Order Value per customer, top customer revenue rankings, customer revenue contribution curves, and 3-tier NTILE revenue segmentation. |
| **Customer Segmentation & RFM** | [`04_customer_segmentation.sql`](file:///d:/Data_Analytics/retail-sales-analytics/sql/analysis/04_customer_segmentation.sql) | Enterprise RFM modeling with quintile scoring (1–5) and 11 distinct behavioral segments (Champions, Loyalists, Potential Loyalists, At Risk, Hibernating, etc.); repeat vs. one-time buyer analysis; demographic and regional customer cross-tabs; loyalty tier audit; and annual acquisition cohort tracking. |
| **Store Performance** | [`05_store_performance.sql`](file:///d:/Data_Analytics/retail-sales-analytics/sql/analysis/05_store_performance.sql) | Comprehensive store network evaluation; store rankings across revenue, profit, volume, and profit margin; channel format comparison (Online, Flagship, Mall Outlet, Standalone, Express); regional store variance; physical footprint productivity (Revenue and Profit per Sq Ft); and an 8-check read-only data quality audit suite. |
| **Regional Analysis** | [`06_regional_analysis.sql`](file:///d:/Data_Analytics/retail-sales-analytics/sql/analysis/06_regional_analysis.sql) | Geographic sales performance across operating territories (`National`, `North`, `South`, `East`, `West`); regional profitability margins; global regional revenue and profit rankings; intra-regional store rankings; dynamic #1 store identification per region; regional monthly trends; and an executive consolidated summary matrix. |
| **Profitability & Discount Analysis** | [`07_profitability_discount_analysis.sql`](file:///d:/Data_Analytics/retail-sales-analytics/sql/analysis/07_profitability_discount_analysis.sql) | Commercial discount impact analysis across 4 standardized discount tiers (`No Discount`, `Low`, `Medium`, `High`); correlation between discount rates, unit prices, and margin compression; line-item inspection of high-discount ($\ge 20\%$) and loss-making (`Profit <= 0.00`) transactions; category margins; monthly profitability timelines; and top/bottom product profit rankings. |
| **Advanced SQL Analysis** | [`08_advanced_analysis.sql`](file:///d:/Data_Analytics/retail-sales-analytics/sql/analysis/08_advanced_analysis.sql) | Portfolio-grade advanced analytical SQL demonstrating single/multi-stage CTEs, chronological running totals with unbounded window frames, period-over-period `LAG()` offsets, rolling 3-month moving averages, scoped intra-category and intra-regional `ROW_NUMBER()` partitions, customer cumulative Pareto spend curves, category revenue contribution ratios, conditional aggregation across discount tiers, customer activity lifespan (`DATEDIFF`), and initial customer purchase identification. |

---

## 4. Business Questions Answered

The completed SQL scripts provide deterministic, data-driven answers to core commercial retail questions:

### A. Overall Enterprise Performance
- *What is the total sales revenue, total cost of goods sold, and net gross profit of Aura Retail Group?*
- *What is the enterprise-wide gross profit margin percentage?*
- *How many total items were sold, and how many distinct sales transactions were completed?*
- *What is the enterprise Average Order Value (AOV) and Average Selling Price (ASP)?*
- *How many unique registered retail customers actively made a purchase?*

### B. Sales Trends & Seasonality
- *How do sales revenue and profit fluctuate across calendar months, quarters, and years?*
- *What is the month-over-month (MoM) revenue and profit growth rate?*
- *What is the cumulative revenue and profit trajectory over the two-year reporting period?*
- *Which calendar months historically generate peak sales (holiday surges) vs. commercial troughs (post-holiday lulls)?*
- *How do identical calendar months perform year-over-year (2023 vs. 2024)?*
- *What are the specific dates of the single highest and lowest revenue and profit months?*

### C. Merchandise & Product Performance
- *Which product categories and subcategories drive the bulk of enterprise revenue and profit?*
- *Which specific product SKUs are the top 10 profit drivers versus the lowest-profit / loss-making margin drainers?*
- *What is the individual profit margin percentage for each product in the catalog?*
- *What percentage of total company revenue is generated by each product category?*
- *Which single product SKU is the #1 revenue leader within each distinct product category?*

### D. Customer Demographics & Lifetime Value
- *Which customers are the highest-spending VIP contributors across the company?*
- *What is the distribution of customer order frequency and Average Order Value?*
- *What percentage of total enterprise revenue is contributed by the top deciles of customers (Pareto curve)?*
- *How long is the active purchasing lifespan of each customer (days between first and most recent purchase)?*
- *What was the exact date, transaction ID, and basket size of each customer's inaugural purchase?*

### E. Customer Segmentation & RFM Modeling
- *How are customers segmented when scored into 1–5 quintiles across Recency, Frequency, and Monetary dimensions?*
- *What proportion of the active customer base falls into strategic segments (e.g., Champions, Loyal Customers, At Risk, Churned)?*
- *What is the ratio of repeat buyers versus one-time purchasers, and what share of total revenue do repeat buyers generate?*
- *How does purchasing behavior vary across demographic attributes (gender, age bracket) and geographic territories?*
- *Are assigned loyalty tiers (Regular, Silver, Gold, VIP Platinum) statistically aligned with actual customer monetary contribution?*
- *How have customer acquisition cohorts (2020 through 2024) retained spending volume over time?*

### F. Store Network & Footprint Productivity
- *What is the comparative sales and profit performance of each individual store location?*
- *How does direct-to-consumer E-Commerce perform relative to brick-and-mortar store formats (Flagship, Mall Outlet, Standalone, Express)?*
- *Which physical store locations achieve the highest retail floor productivity (Sales per Sq Ft and Profit per Sq Ft)?*
- *Are there any dormant retail locations with zero recorded sales transactions?*

### G. Geographic Regional Performance
- *Which geographic sales regions (`National`, `North`, `South`, `East`, `West`) generate the highest revenue and net profit?*
- *What are the respective profit margins across geographic operating regions?*
- *Which individual store is the #1 revenue generator within each sales region?*
- *How does regional revenue trend chronologically across monthly reporting periods?*

### H. Profitability, Pricing & Promotional Discounts
- *How do promotional discount tiers (0%, 1%–10%, 11%–20%, >20%) impact net gross profit margins?*
- *Does higher discounting stimulate enough volume to offset gross margin compression, or does it degrade profit?*
- *Which specific commercial transactions incurred deep discounts ($\ge 20\%$) or resulted in break-even/negative profit (`Profit <= 0`)?*
- *What proportion of regional sales revenue is sold under promotional discounts versus full catalog price?*

---

## 5. SQL Techniques Demonstrated

The analysis scripts apply modern, standard Transact-SQL (T-SQL) constructs selected for clarity, computational efficiency, and analytical precision:

| Technique | Where Applied | Technical Rationale & Business Purpose |
|---|---|---|
| **Relational Joins (`INNER JOIN`, `LEFT JOIN`)** | All scripts | Joins the central transaction fact table (`dbo.FactSales`) to conformed dimensions (`dbo.DimDate`, `dbo.DimCustomer`, `dbo.DimProduct`, `dbo.DimStore`) using integer and surrogate keys. `LEFT JOIN` is specifically utilized in store and customer performance scripts to preserve dormant stores or non-purchasing customers for audit completeness. |
| **Common Table Expressions (CTEs)** | `02_sales_trends.sql`, `04_customer_segmentation.sql`, `05_store_performance.sql`, `06_regional_analysis.sql`, `07_profitability_discount_analysis.sql`, `08_advanced_analysis.sql` | Modularizes multi-step calculations into distinct, readable logical layers (e.g., base aggregation $\rightarrow$ metric derivation $\rightarrow$ ranking $\rightarrow$ filtering), eliminating nested subqueries and redundant code. |
| **Multiple / Chained CTEs** | `02_sales_trends.sql`, `04_customer_segmentation.sql`, `08_advanced_analysis.sql` | Structures progressive data transformation pipelines (e.g., aggregating monthly figures in CTE 1, applying `LAG()` window offsets in CTE 2, and calculating percentage growth in the final query). |
| **Aggregate Functions (`SUM`, `AVG`, `MIN`, `MAX`, `COUNT DISTINCT`)** | All scripts | Computes fundamental financial and operational measures: total revenue, total COGS, net gross profit, average unit price, distinct transaction volume (`COUNT(DISTINCT SalesID)`), and temporal boundaries (`MIN(OrderDate)`, `MAX(OrderDate)`). |
| **Offset Window Functions (`LAG`)** | `02_sales_trends.sql`, `08_advanced_analysis.sql` | Retrieves values from the immediately preceding row in chronological sequence without expensive self-joins, enabling clean Month-over-Month (MoM) revenue and profit variance and percentage growth tracking. |
| **Ranking Window Functions (`ROW_NUMBER`)** | `02_sales_trends.sql`, `08_advanced_analysis.sql` | Assigns deterministic sequential integers to rows within a partition. Used with `ORDER BY ... DESC` and outer filters (`WHERE RowNum = 1`) to dynamically extract the top product per category, top store per region, customer initial purchase, and peak/trough months. |
| **Dense Ranking Window Functions (`DENSE_RANK`)** | `02_product_performance.sql`, `03_customer_performance.sql`, `05_store_performance.sql`, `06_regional_analysis.sql`, `07_profitability_discount_analysis.sql`, `08_advanced_analysis.sql` | Computes ordinal ranks for products, customers, stores, and regions without skipping rank numbers when ties occur in metric values. |
| **Partitioning (`PARTITION BY`)** | `05_store_performance.sql`, `06_regional_analysis.sql`, `08_advanced_analysis.sql` | Divides result sets into independent analytical subsets (e.g., by Category, Region, or CustomerID) where ranking and sequencing calculations reset at group boundaries. |
| **Window Frame Running Totals** | `02_sales_trends.sql`, `08_advanced_analysis.sql` | Uses `ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW` to compute cumulative revenue, cumulative profit, and customer spend Pareto concentration curves over ordered datasets. |
| **Rolling Moving Averages** | `08_advanced_analysis.sql` | Uses `AVG(...) OVER (ORDER BY ... ROWS BETWEEN 2 PRECEDING AND CURRENT ROW)` to calculate a trailing 3-month simple moving average that filters out short-term seasonality and noise. |
| **Unpartitioned Grand Total Windows** | `02_product_performance.sql`, `03_customer_performance.sql`, `05_store_performance.sql`, `06_regional_analysis.sql`, `08_advanced_analysis.sql` | Computes dataset-wide denominators on the fly using `SUM(...) OVER ()` without collapsing row granularity, enabling concise percentage contribution calculations. |
| **Quantile Distribution (`NTILE`)** | `03_customer_performance.sql`, `04_customer_segmentation.sql` | Divides ordered populations into equal statistical buckets (tertiles `NTILE(3)` in customer performance; quintiles `NTILE(5)` for RFM scoring) to segment customers objectively by spend, frequency, and recency. |
| **Conditional Aggregation (`SUM(CASE WHEN...)`)** | `02_sales_trends.sql`, `04_customer_segmentation.sql`, `08_advanced_analysis.sql` | Evaluates boolean criteria inside aggregation functions to pivot measures into distinct columns (e.g., YoY monthly comparison side-by-side; revenue across promotional discount bands per region) in a single high-performance table scan. |
| **Correlated Subqueries & Semi-Joins (`EXISTS`)** | `08_advanced_analysis.sql` | Validates customer activity using `WHERE EXISTS (SELECT 1 FROM dbo.FactSales WHERE CustomerID = c.CustomerID)`, optimizing query performance and enforcing analytical safety. |
| **Defensive Division (`NULLIF`)** | All scripts | Wraps all arithmetic division denominators (`NULLIF(divisor, 0)`) to guard against division-by-zero runtime exceptions, returning safe `NULL` values when transaction counts, revenue, or baseline periods are zero. |
| **Precision Decimal Formatting (`ROUND`)** | All scripts | Standardizes monetary outputs and percentage ratios to 2 or 4 decimal places, ensuring clean, consistent financial reporting. |

---

## 6. End-to-End Data Traceability & Lineage

The analytical SQL scripts in Phase 8 do not query raw CSV files or unverified staging tables directly. Instead, they represent the culmination of an **audited, five-stage data warehouse lifecycle**:

```
[ Stage 1: Raw Ingestion ]
  Raw CSV Data Sources: customers.csv (50,000), products.csv (500), stores.csv (30), date.csv (731), sales.csv (321,131)
       |
       v
[ Stage 2: Automated Cleaning & Audit ]
  python/data_cleaning.py: Whitespace trimming, name title-casing, postal code padding,
  email/phone imputation ('Not Provided'), duplicate removal (450 tech duplicates),
  referential integrity validation (145 unmapped sales filtered), financial formula verification.
       |
       v
[ Stage 3: Relational Staging Layer ]
  sql/staging/01_create_staging_tables.sql & 02_load_staging_data.sql:
  Cleaned data ingested via BULK INSERT into dedicated [staging] schema tables (stg_Customer, stg_Product, etc.).
  Validated using sql/staging/03_validate_staging_data.sql.
       |
       v
[ Stage 4: Production Star Schema ETL ]
  sql/staging/04_transform_and_load.sql:
  Atomic transaction (BEGIN TRANSACTION / COMMIT) transforms and loads data from [staging] to production [dbo] schema.
  Enforces Primary Keys, Foreign Keys, and commercial CHECK constraints (Quantity > 0, Discount 0.00–1.00).
  Verified using sql/staging/05_validate_final_data.sql and sql/database/06_validate_database.sql.
       |
       v
[ Stage 5: Analytical SQL Layer (Phase 8) ]
  sql/analysis/01_overall_performance.sql through 08_advanced_analysis.sql:
  Read-only analytical queries, CTEs, and window functions operating on certified dbo tables.
       |
       v
[ Business Intelligence & Executive Decision-Making ]
```

### Stage Responsibilities

1. **Stage 1 (Raw Data Generation & Acquisition):** Captures enterprise transactional history covering 321,131 raw sales rows across 50,000 customers, 500 products, 30 stores, and 731 calendar days.
2. **Stage 2 (Python Cleansing & Certification):** Removes 450 duplicate rows, handles 145 corrupt/orphan records, standardizes text casing and 5-digit ZIP codes, and certifies mathematical balance:
   $$\text{DiscountAmount} = \text{round}(\text{Quantity} \times \text{UnitPrice} \times \text{Discount}, 2)$$
   $$\text{SalesAmount} = \text{round}((\text{Quantity} \times \text{UnitPrice}) - \text{DiscountAmount}, 2)$$
   $$\text{CostAmount} = \text{round}(\text{Quantity} \times \text{UnitCost}, 2)$$
   $$\text{Profit} = \text{round}(\text{SalesAmount} - \text{CostAmount}, 2)$$
3. **Stage 3 (Staging Ingestion):** Loads pre-validated CSV files into non-indexed, permissive `staging.stg_*` tables for database-side reconciliation.
4. **Stage 4 (Production Star Schema Load):** Moves data into `dbo.DimDate`, `dbo.DimCustomer`, `dbo.DimProduct`, `dbo.DimStore`, and `dbo.FactSales` within an atomic transaction. Enforces 5 clustered Primary Keys, 4 Foreign Key constraints, and 6 Check constraints.
5. **Stage 5 (Analytical Consumption):** Executes analytical queries exclusively against the certified, indexed `dbo` tables.

---

## 7. Data Quality & Pre-Analysis Validation

Prior to running Phase 8 analysis, the underlying data underwent comprehensive automated audits at both the Python and SQL Server levels, as recorded in `reports/data_quality_report.md` and `sql/database/06_validate_database.sql`:

### Summary of Validated Metrics

| Validation Category | Audit Rule & Specification | Observed Metric / Status | Compliance Result |
|---|---|---|---|
| **Row Count Audit** | Customer records retained | 50,000 of 50,000 (100%) | **PASSED** |
| | Product catalog SKUs retained | 500 of 500 (100%) | **PASSED** |
| | Store outlets retained | 30 of 30 (100%) | **PASSED** |
| | Calendar days retained | 731 of 731 (100%) | **PASSED** |
| | Sales transactions retained | 320,536 of 321,131 (99.81%) | **PASSED** (595 bad rows purged) |
| **Duplicate Keys** | Uniqueness of Primary Keys | 0 duplicates across all 5 tables | **PASSED** |
| **Referential Integrity** | `FactSales.CustomerID -> DimCustomer` | 0 orphaned foreign keys | **PASSED** |
| | `FactSales.ProductID -> DimProduct` | 0 orphaned foreign keys | **PASSED** |
| | `FactSales.StoreID -> DimStore` | 0 orphaned foreign keys | **PASSED** |
| | `FactSales.DateKey -> DimDate` | 0 orphaned foreign keys | **PASSED** |
| **Mandatory NULL Checks** | NULLs in Fact additive facts (`Quantity`, `SalesAmount`, `Profit`) | 0 NULL values | **PASSED** |
| | NULLs in Dimension business keys | 0 NULL values | **PASSED** |
| **Business Boundary Checks** | `Quantity > 0` constraint | 0 non-positive quantities | **PASSED** |
| | `Discount BETWEEN 0.00 AND 1.00` constraint | 0 invalid discount rates | **PASSED** |
| | `UnitPrice >= 0.00`, `UnitCost >= 0.00` | 0 negative pricing records | **PASSED** |
| | `SalesAmount >= 0.00`, `CostAmount >= 0.00` | 0 negative revenue/cost records | **PASSED** |
| **Financial Reconciliation** | Sum of discounts, sales, and costs | $\Delta \le \$0.001$ variance tolerance | **PASSED (100% reconciled)** |

---

## 8. Reproducibility & Repository Guide

An external data analyst or engineering team member can fully reproduce the warehouse and analysis environment using the following repository artifacts:

```
d:/Data_Analytics/retail-sales-analytics/
├── data/
│   ├── raw/                             # Raw simulated CSV extracts
│   └── cleaned/                         # Python-cleansed CSV files ready for SQL bulk load
│       ├── customers.csv                # 50,000 customer rows
│       ├── date.csv                     # 731 calendar day rows
│       ├── products.csv                 # 500 merchandise SKU rows
│       ├── sales.csv                    # 320,536 sales line items
│       └── stores.csv                   # 30 store network rows
├── documentation/                       # Architecture, ETL, and requirement guides
├── docs/                                # Executive and analytical reports
│   └── sql_analysis_report.md           # This comprehensive Phase 8 report
├── python/
│   ├── generate_raw_data.py             # Synthetic raw retail dataset generator
│   └── data_cleaning.py                 # Automated Pandas cleaning, imputation, and validation pipeline
├── reports/
│   ├── cleaned_data_validation.csv      # Statistical validation outputs
│   └── data_quality_report.md           # Formal certification of cleaned dataset
└── sql/
    ├── database/
    │   ├── 01_create_database.sql       # Database creation and recovery model setup
    │   ├── 02_create_tables.sql         # DDL creating 4 Dimensions + 1 Central Fact table
    │   ├── 03_create_constraints.sql    # Primary keys, foreign keys, and commercial CHECK constraints
    │   ├── 04_create_indexes.sql        # Clustered and non-clustered performance indexes
    │   ├── 05_create_views.sql          # Analytical views (vw_SalesDetail, vw_MonthlySalesSummary, etc.)
    │   └── 06_validate_database.sql     # Automated schema and integrity test suite
    ├── staging/
    │   ├── 01_create_staging_tables.sql # DDL creating permissive [staging].stg_* tables
    │   ├── 02_load_staging_data.sql     # BULK INSERT script ingesting cleaned CSVs into staging
    │   ├── 03_validate_staging_data.sql # Post-ingestion row count and NULL verification
    │   ├── 04_transform_and_load.sql    # Atomic transactional ETL load from staging into production
    │   └── 05_validate_final_data.sql   # Post-load validation and referential reconciliation
    └── analysis/
        ├── 01_overall_performance.sql   # Task 8.1 - Overall Business Performance
        ├── 02_product_performance.sql   # Task 8.2 - Product Performance
        ├── 02_sales_trends.sql          # Task 8.2 - Sales Trends Analysis
        ├── 03_customer_performance.sql  # Task 8.3 - Customer Performance
        ├── 04_customer_segmentation.sql # Task 8.4 - Customer Segmentation & RFM
        ├── 05_store_performance.sql     # Task 8.5 - Store Performance Analysis
        ├── 06_regional_analysis.sql     # Task 8.6 - Regional Performance Analysis
        ├── 07_profitability_discount_analysis.sql # Task 8.7 - Profitability & Discounts
        └── 08_advanced_analysis.sql     # Task 8.8 - Advanced SQL Analytical Techniques
```

### Step-by-Step Reproduction Workflow

1. **Step 1: Python Data Cleaning**  
   Run `python python/data_cleaning.py` to process raw files from `data/raw/` and output certified files to `data/cleaned/`.
2. **Step 2: Database & Schema Provisioning**  
   Execute `sql/database/01_create_database.sql` through `sql/database/05_create_views.sql` to establish the `RetailSalesAnalytics` database, tables, constraints, indexes, and views.
3. **Step 3: Staging Ingestion & Staging Verification**  
   Run `sql/staging/01_create_staging_tables.sql` followed by `sql/staging/02_load_staging_data.sql` and `sql/staging/03_validate_staging_data.sql`.
4. **Step 4: Production ETL Load & Final Validation**  
   Execute `sql/staging/04_transform_and_load.sql` to populate production tables, verified via `sql/staging/05_validate_final_data.sql` and `sql/database/06_validate_database.sql`.
5. **Step 5: Analytical SQL Execution**  
   Execute any script in `sql/analysis/` in any order. All scripts are standalone and completely non-destructive.

---

## 9. Professional Portfolio & Resume Highlights

The Phase 8 implementation demonstrates several core analytical and data engineering competencies:

- **Enterprise Dimensional Modeling:** Practical mastery of Kimball dimensional modeling principles, star schema table role separation (conformed dimensions vs. additive facts), surrogate keys, and referential integrity.
- **Advanced Transact-SQL (T-SQL) Fluency:** Expertise in complex analytical queries using single/multi-stage Common Table Expressions (CTEs), multi-table relational joins, advanced window functions (`DENSE_RANK`, `ROW_NUMBER`, `NTILE`, `LAG`, `SUM() OVER`, `AVG() OVER`), window framing (`ROWS BETWEEN`), and conditional aggregation.
- **Commercial Retail Acumen:** Deep understanding of retail metrics: Gross Revenue, Cost of Goods Sold (COGS), Gross Profit, Profit Margin %, Average Order Value (AOV), Average Selling Price (ASP), retail sales per square foot, promotional discount erosion, and RFM behavioral modeling.
- **Data Engineering Defensiveness:** Production-quality query hygiene including consistent `NULLIF(..., 0)` division-by-zero protection, `COALESCE()` aggregate safeguards, explicit column projections (avoiding `SELECT *`), and deterministic tie-breaking.
- **End-to-End Pipeline Traceability:** Ability to connect raw operational records through Python cleaning, staging tables, production ETL, and business-facing analytical queries.

---

## 10. Analytical Limitations & Next Steps

### Limitations of Current SQL Analysis Layer
1. **Static Relational Reporting:** While the T-SQL scripts provide accurate tabular summaries and rankings, they do not offer dynamic drill-down capabilities or real-time interactive slicing across dimensions.
2. **Static Historical Horizon:** The dataset spans a discrete two-year historical window (2023-01-01 to 2024-12-31). It does not incorporate real-time transactional streaming or automated daily increment loads.
3. **Non-Predictive Scope:** The current SQL suite focuses strictly on descriptive and diagnostic analytics (what happened and why). It does not include machine learning forecasting models (e.g., ARIMA sales forecasting or predictive churn scoring).

### Planned Next Phase: Phase 9 (Business Intelligence & Reporting)
The logical next phase of the project is **Phase 9: Power BI Dashboard & Visual Analytics**, which will:
- Connect Power BI Desktop directly to `dbo.FactSales` and conformed dimensions (or the pre-built `dbo.vw_SalesDetail` view).
- Implement an enterprise DAX calculation model (defining explicit measures for Sales, Margin %, YoY Growth, and RFM metrics).
- Build executive and operational dashboards:
  1. *Executive Sales & Margin Overview*
  2. *Product & Category Profitability Explorer*
  3. *Customer Segmentation & RFM Matrix*
  4. *Store & Regional Geospatial Performance*

*(Note: In strict compliance with instructions, Phase 9 has not been implemented in this phase.)*

---

## 11. Final Project Checklist

The table below reflects the completed and verified state of all phases up to and including Phase 8:

- [x] Raw data generated (`python/generate_raw_data.py`)
- [x] Data cleaned (`python/data_cleaning.py`)
- [x] Data validated (`reports/data_quality_report.md`, `reports/cleaned_data_validation.csv`)
- [x] SQL Server database created (`sql/database/01_create_database.sql`)
- [x] Staging tables created (`sql/staging/01_create_staging_tables.sql`)
- [x] Staging data loaded (`sql/staging/02_load_staging_data.sql`)
- [x] Final dimensional tables loaded (`sql/staging/04_transform_and_load.sql`)
- [x] Final data validated (`sql/staging/05_validate_final_data.sql`, `sql/database/06_validate_database.sql`)
- [x] Overall performance analysis completed (`sql/analysis/01_overall_performance.sql`)
- [x] Product analysis completed (`sql/analysis/02_product_performance.sql`)
- [x] Sales trends analysis completed (`sql/analysis/02_sales_trends.sql`)
- [x] Customer analysis completed (`sql/analysis/03_customer_performance.sql`)
- [x] Customer segmentation analysis completed (`sql/analysis/04_customer_segmentation.sql`)
- [x] Store analysis completed (`sql/analysis/05_store_performance.sql`)
- [x] Regional analysis completed (`sql/analysis/06_regional_analysis.sql`)
- [x] Profitability/discount analysis completed (`sql/analysis/07_profitability_discount_analysis.sql`)
- [x] Advanced SQL analysis completed (`sql/analysis/08_advanced_analysis.sql`)
- [x] Documentation & final report completed (`docs/sql_analysis_report.md`)

---

## 12. Final Analysis File Map

This map provides an index for technical reviewers and recruiters navigating the repository's analytical assets:

| SQL File | Task Reference | Core Analytical Focus | Key Techniques Showcased |
|---|---|---|---|
| [`01_overall_performance.sql`](file:///d:/Data_Analytics/retail-sales-analytics/sql/analysis/01_overall_performance.sql) | Task 8.1 | Executive Macro KPIs | `SUM`, `COUNT DISTINCT`, `AVG`, `ROUND`, `NULLIF` |
| [`02_product_performance.sql`](file:///d:/Data_Analytics/retail-sales-analytics/sql/analysis/02_product_performance.sql) | Task 8.2 | Catalog SKU & Category Health | `INNER JOIN`, `DENSE_RANK`, `SUM() OVER ()`, Category Rollups |
| [`02_sales_trends.sql`](file:///d:/Data_Analytics/retail-sales-analytics/sql/analysis/02_sales_trends.sql) | Task 8.2 | Multi-Period Sales Velocity & Seasonality | `LAG()`, Running Totals (`ROWS BETWEEN`), YoY Pivot, Peak/Trough Ranking |
| [`03_customer_performance.sql`](file:///d:/Data_Analytics/retail-sales-analytics/sql/analysis/03_customer_performance.sql) | Task 8.3 | Customer Value & Distribution | `NTILE(3)`, Top 10 Filter, Revenue Contribution Ratios |
| [`04_customer_segmentation.sql`](file:///d:/Data_Analytics/retail-sales-analytics/sql/analysis/04_customer_segmentation.sql) | Task 8.4 | RFM Quintile Scoring & Cohorts | `NTILE(5)`, Multi-Condition `CASE`, Repeat vs One-Time, Cohort `DATEDIFF` |
| [`05_store_performance.sql`](file:///d:/Data_Analytics/retail-sales-analytics/sql/analysis/05_store_performance.sql) | Task 8.5 | Retail Outlets & Footprint Productivity | Two-Stage CTEs, Sq Ft Productivity Ratios, Format Variance, DQ Audit Suite |
| [`06_regional_analysis.sql`](file:///d:/Data_Analytics/retail-sales-analytics/sql/analysis/06_regional_analysis.sql) | Task 8.6 | Geographic Sales Territory Variance | `PARTITION BY Region`, Top Store Identification, Regional Monthly Trend |
| [`07_profitability_discount_analysis.sql`](file:///d:/Data_Analytics/retail-sales-analytics/sql/analysis/07_profitability_discount_analysis.sql) | Task 8.7 | Promotional Discounting & Margin Erosion | Discount Bands (`CASE`), Transaction Inspection, Loss-Maker Audit (`Profit <= 0`) |
| [`08_advanced_analysis.sql`](file:///d:/Data_Analytics/retail-sales-analytics/sql/analysis/08_advanced_analysis.sql) | Task 8.8 | Advanced Windowing & Lifecycle Patterns | Moving Averages (`ROWS BETWEEN 2 PRECEDING`), `ROW_NUMBER()`, `EXISTS`, Pareto Concentration |

---
*End of Report — Phase 8 Certified.*
