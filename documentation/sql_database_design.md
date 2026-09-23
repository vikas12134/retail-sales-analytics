# SQL Server Database Design Document
## Project: Retail Sales & Customer Analytics
**Enterprise:** Aura Retail Group  
**Database Name:** `RetailSalesAnalytics`  
**Document Version:** 1.0  
**Author:** Data Analytics Team  
**Date:** 2026-09-05  

---

## 1. Database Purpose

The `RetailSalesAnalytics` database serves as the centralized, relational Star Schema data warehouse for Aura Retail Group. It is engineered to consolidate multi-channel retail transaction data across 29 brick-and-mortar store locations and a national e-commerce storefront.

The database provides a clean, validated, and referentially sound foundation for:
1. **Relational T-SQL Analytical Queries:** Fast aggregations, cohort tracking, profitability analysis, and store benchmarking.
2. **Power BI Semantic Modeling:** Direct, star-schema-aligned dimensional modeling with clear 1-to-many single-direction filtering.
3. **DAX Measures & KPI Engineering:** Time intelligence calculations, customer lifetime value (LTV), customer segmentation (RFM), and margin drift detection.
4. **Executive & Operational Reporting:** Uniform metrics across merchandising, finance, regional operations, and marketing teams.

---

## 2. Dimensional Architecture & Star Schema Model

The warehouse implements a classic Ralph Kimball-style **Star Schema** dimensional design consisting of **4 Dimension Tables** surrounding **1 Central Fact Table**:

```text
                        ┌────────────────────────┐
                        │      dbo.DimDate       │
                        │ ────────────────────── │
                        │ PK: DateKey (INT)      │
                        │ FullDate, Year, Month  │
                        │ Quarter, Holiday, etc. │
                        └───────────┬────────────┘
                                    │ 1
                                    │
                                    │ *
┌────────────────────────┐          │          ┌────────────────────────┐
│    dbo.DimCustomer     │          │          │     dbo.DimProduct     │
│ ────────────────────── │          │          │ ────────────────────── │
│ PK: CustomerID (VC20)  │          │          │ PK: ProductID (VC20)   │
│ FirstName, LastName    │*         ▼         *│ ProductName, Category  │
│ Segment, City, State   ├──────►┌──────────────────────┐◄──────┤ Subcategory, Brand     │
│ JoinDate, DOB          │       │    dbo.FactSales     │       │ UnitCost, UnitPrice    │
└────────────────────────┘       │ ──────────────────── │       └────────────────────────┘
                                 │ PK: SalesID (VC20)   │
                                 │ FK: DateKey          │
                                 │ FK: CustomerID       │
                                 │ FK: ProductID        │
                                 │ FK: StoreID          │
                                 │ Quantity, UnitPrice  │
                                 │ DiscountAmount       │
                                 │ SalesAmount, Profit  │
                                 └──────────┬───────────┘
                                            ▲
                                            │ *
                                            │
                                            │ 1
                                 ┌──────────┴───────────┐
                                 │     dbo.DimStore     │
                                 │ ──────────────────── │
                                 │ PK: StoreID (VC20)   │
                                 │ StoreName, StoreType │
                                 │ City, State, Region  │
                                 │ SquareFootage        │
                                 └──────────────────────┘
```

---

## 3. Table Catalog & Data Dictionary

### 3.1. Conformed Dimension: `dbo.DimDate`
- **Role:** Conformed calendar dimension providing standard calendar, fiscal, holiday, and weekend attributes.
- **Granularity:** One record per calendar day covering a 2-year operational window (`2023-01-01` to `2024-12-31`).
- **Row Count:** 731 rows.

| Column Name | Data Type | Nullable | Description & Example |
|---|---|---|---|
| `DateKey` | `INT` | **NO (PK)** | Surrogate key in `YYYYMMDD` format (e.g. `20230101`). |
| `FullDate` | `DATE` | **NO** | Standard calendar date (`2023-01-01`). |
| `Year` | `SMALLINT` | **NO** | Calendar year (e.g. `2023`, `2024`). |
| `Quarter` | `TINYINT` | **NO** | Calendar quarter number (`1` to `4`). |
| `QuarterName` | `VARCHAR(10)` | **NO** | Formatted quarter label (`2023-Q1`). |
| `Month` | `TINYINT` | **NO** | Calendar month number (`1` to `12`). |
| `MonthName` | `VARCHAR(15)` | **NO** | Full month name (`January`, `February`, etc.). |
| `MonthYear` | `VARCHAR(10)` | **NO** | Display label (`Jan-2023`). |
| `WeekOfYear` | `TINYINT` | **NO** | ISO calendar week number (`1` to `53`). |
| `DayOfWeek` | `TINYINT` | **NO** | Day of week number (`1` = Monday, `7` = Sunday). |
| `DayName` | `VARCHAR(10)` | **NO** | Full day name (`Sunday`, `Monday`, etc.). |
| `DayOfMonth` | `TINYINT` | **NO** | Day of month (`1` to `31`). |
| `IsWeekend` | `BIT` | **NO** | Flag: `1` for Saturday/Sunday, `0` for Weekdays. |
| `IsHoliday` | `BIT` | **NO** | Flag: `1` for major retail holidays (Black Friday, Christmas, etc.). |
| `FiscalYear` | `VARCHAR(10)` | **NO** | Corporate fiscal year label (`FY2023`). |
| `FiscalQuarter` | `VARCHAR(10)` | **NO** | Corporate fiscal quarter label (`FQ1`). |

---

### 3.2. Customer Dimension: `dbo.DimCustomer`
- **Role:** Customer demographic and loyalty segmentation master table.
- **Granularity:** One record per registered retail shopper.
- **Row Count:** 50,000 rows.

| Column Name | Data Type | Nullable | Description & Example |
|---|---|---|---|
| `CustomerID` | `VARCHAR(20)` | **NO (PK)** | Unique customer business identifier (`CUST-00001`). |
| `FirstName` | `VARCHAR(50)` | **NO** | Cleaned, whitespace-trimmed first name (`Shawn`). |
| `LastName` | `VARCHAR(50)` | **NO** | Cleaned, whitespace-trimmed last name (`Baker`). |
| `Email` | `VARCHAR(100)` | **NO** | Contact email or `'Not Provided'` (in-store POS opt-out). |
| `Phone` | `VARCHAR(30)` | **NO** | Contact phone or `'Not Provided'` (online guest checkout opt-out). |
| `Gender` | `VARCHAR(20)` | **NO** | Cleaned gender category (`Female`, `Male`, `Other`). |
| `DateOfBirth` | `DATE` | **YES** | Customer birth date (`1984-01-25`) or `NULL` (preserves demographic age statistics). |
| `City` | `VARCHAR(50)` | **NO** | Customer residential city (`New York`). |
| `State` | `VARCHAR(10)` | **NO** | Standardized 2-letter uppercase postal state code (`NY`). |
| `Region` | `VARCHAR(20)` | **NO** | Corporate geographic sales region (`East`, `North`, `South`, `West`). |
| `PostalCode` | `VARCHAR(10)` | **NO** | 5-digit zero-padded postal code (`10061`, `07198`). |
| `CustomerSegment` | `VARCHAR(30)` | **NO** | Loyalty classification tier (`Regular`, `Silver`, `Gold`, `VIP Platinum`). |
| `JoinDate` | `DATE` | **NO** | Account registration timestamp (`2024-03-29`). |

---

### 3.3. Product Catalog Dimension: `dbo.DimProduct`
- **Role:** Master catalog of merchandise offerings.
- **Granularity:** One record per unique product SKU.
- **Row Count:** 500 rows.

| Column Name | Data Type | Nullable | Description & Example |
|---|---|---|---|
| `ProductID` | `VARCHAR(20)` | **NO (PK)** | Unique product SKU key (`PROD-0001`). |
| `ProductName` | `VARCHAR(150)` | **NO** | Descriptive product label (`NovaTech Smartphones Classic 1`). |
| `Category` | `VARCHAR(50)` | **NO** | One of 5 canonical categories (`Electronics & Gadgets`). |
| `Subcategory` | `VARCHAR(50)` | **NO** | One of 25 merchandise subcategories (`Smartphones & Tablets`). |
| `Brand` | `VARCHAR(50)` | **NO** | Brand manufacturer label (`NovaTech`). |
| `UnitCost` | `DECIMAL(10, 2)` | **NO** | Base merchandise cost of goods sold (`291.77`). |
| `UnitPrice` | `DECIMAL(10, 2)` | **NO** | Base catalog retail selling price (`396.71`). |
| `Status` | `VARCHAR(20)` | **NO** | Product lifecycle status (`Active`). |

---

### 3.4. Store Network Dimension: `dbo.DimStore`
- **Role:** Physical store outlets and digital storefronts.
- **Granularity:** One record per retail location.
- **Row Count:** 30 rows (1 Online Flagship + 29 Physical Outlets).

| Column Name | Data Type | Nullable | Description & Example |
|---|---|---|---|
| `StoreID` | `VARCHAR(20)` | **NO (PK)** | Store outlet identifier (`STR-01`). |
| `StoreName` | `VARCHAR(100)` | **NO** | Standardized retail name (`Aura Direct E-Commerce`, `Aura Chicago Flagship`). |
| `StoreType` | `VARCHAR(50)` | **NO** | Retail format (`Online`, `Flagship Store`, `Mall Outlet`, `Standalone Store`, `Express Store`). |
| `City` | `VARCHAR(50)` | **NO** | Operating city (`Chicago`, `National Online`). |
| `State` | `VARCHAR(20)` | **NO** | Operating state (`IL`, `NATIONAL`). |
| `Region` | `VARCHAR(20)` | **NO** | Operating sales region (`North`, `National`, etc.). |
| `SquareFootage` | `INT` | **NO** | Retail floor area in sq ft (`31515`; `0` for Online). |
| `OpenDate` | `DATE` | **NO** | Store grand opening date (`2020-01-15`). |
| `ManagerName` | `VARCHAR(100)` | **NO** | Store General Manager (`Alex Rivera`). |

---

### 3.5. Central Fact Table: `dbo.FactSales`
- **Role:** Central transactional sales fact table containing numerical commercial measures and foreign key joins to all dimensions.
- **Granularity:** One record per transaction line item.
- **Row Count:** 320,536 clean rows.
- **Key Design Rule:** Contains **zero redundant dimensional text attributes** (e.g. no `CustomerName`, `ProductName`, `Category`, `StoreName`, or `Region`). All dimensional context is retrieved via foreign key joins.

| Column Name | Data Type | Nullable | Measure Type | Description & Example |
|---|---|---|---|---|
| `SalesID` | `VARCHAR(20)` | **NO (PK)** | Degenerate Key | Unique sale identifier (corresponds to `TXN-0000001`). |
| `DateKey` | `INT` | **NO (FK)** | Foreign Key | Joins to `DimDate.DateKey` (`20230101`). |
| `OrderDate` | `DATE` | **NO** | Attribute | Calendar date of transaction (`2023-01-01`). |
| `CustomerID` | `VARCHAR(20)` | **NO (FK)** | Foreign Key | Joins to `DimCustomer.CustomerID` (`CUST-09588`). |
| `ProductID` | `VARCHAR(20)` | **NO (FK)** | Foreign Key | Joins to `DimProduct.ProductID` (`PROD-0476`). |
| `StoreID` | `VARCHAR(20)` | **NO (FK)** | Foreign Key | Joins to `DimStore.StoreID` (`STR-12`). |
| `SalesChannel` | `VARCHAR(20)` | **NO** | Degenerate Dim | Channel modality: `'Online'` or `'In-Store'`. |
| `Quantity` | `INT` | **NO** | Additive | Number of units purchased (`>= 1`). |
| `UnitPrice` | `DECIMAL(10, 2)` | **NO** | Non-Additive | Catalog price per unit at sale time (`245.29`). |
| `Discount` | `DECIMAL(4, 2)` | **NO** | Non-Additive | Promotional discount rate (`0.05` = 5%). |
| `DiscountAmount` | `DECIMAL(10, 2)` | **NO** | Additive | Monetary discount given: `round(Gross * Discount, 2)` (`12.26`). |
| `SalesAmount` | `DECIMAL(10, 2)` | **NO** | Additive | Net revenue: `round(Gross - DiscountAmount, 2)` (`233.03`). |
| `UnitCost` | `DECIMAL(10, 2)` | **NO** | Non-Additive | Product acquisition cost at sale time (`127.34`). |
| `CostAmount` | `DECIMAL(10, 2)` | **NO** | Additive | Total COGS: `round(Quantity * UnitCost, 2)` (`127.34`). |
| `Profit` | `DECIMAL(10, 2)` | **NO** | Additive | Net gross profit: `round(SalesAmount - CostAmount, 2)` (`105.69`). |
| `PaymentMethod` | `VARCHAR(30)` | **NO** | Degenerate Dim | POS payment method (`Cash`, `Credit Card`, `Debit Card`, etc.). |

---

## 4. Primary and Foreign Key Relationships

All foreign key relationships strictly enforce referential integrity with **Dimensions on the ONE side** and **FactSales on the MANY side**:

1. **`FK_FactSales_DimDate`**:
   - `dbo.FactSales(DateKey)` $\rightarrow$ `dbo.DimDate(DateKey)`
   - *Purpose:* Guarantees every transaction maps to a valid calendar day in the 2-year analysis window. Powers DAX time-intelligence functions (`TOTALYTD`, `SAMEPERIODLASTYEAR`).
2. **`FK_FactSales_DimCustomer`**:
   - `dbo.FactSales(CustomerID)` $\rightarrow$ `dbo.DimCustomer(CustomerID)`
   - *Purpose:* Associates purchase behavior with verified customer demographic and loyalty tiers. Powers customer cohort retention and RFM segmentation.
3. **`FK_FactSales_DimProduct`**:
   - `dbo.FactSales(ProductID)` $\rightarrow$ `dbo.DimProduct(ProductID)`
   - *Purpose:* Connects line items to product categories, subcategories, and brands. Powers product margin and merchandise mix analytics.
4. **`FK_FactSales_DimStore`**:
   - `dbo.FactSales(StoreID)` $\rightarrow$ `dbo.DimStore(StoreID)`
   - *Purpose:* Attributes revenue to specific physical stores or the e-commerce storefront. Powers regional performance benchmarking and channel mix analysis.

---

## 5. Data Integrity Constraints (CHECK Constraints)

Thirteen `CHECK` constraints enforce statistical and commercial business rules validated during the Task 5 data cleaning pipeline:

| Constraint Name | Target Table | Expression | Business Rationale |
|---|---|---|---|
| `CK_FactSales_Quantity` | `FactSales` | `Quantity > 0` | Transactions must represent positive unit sales; zero-unit and corrupt negative quantities are disallowed. |
| `CK_FactSales_Discount` | `FactSales` | `Discount >= 0.00 AND Discount <= 1.00` | Discount rate must be bounded between 0% and 100%. |
| `CK_FactSales_UnitPrice` | `FactSales` | `UnitPrice >= 0.00` | Retail prices cannot be negative. |
| `CK_FactSales_UnitCost` | `FactSales` | `UnitCost >= 0.00` | Product acquisition costs cannot be negative. |
| `CK_FactSales_SalesAmount` | `FactSales` | `SalesAmount >= 0.00` | Net revenue cannot be negative. |
| `CK_FactSales_CostAmount` | `FactSales` | `CostAmount >= 0.00` | Total cost of goods sold cannot be negative. |
| `CK_FactSales_SalesChannel` | `FactSales` | `SalesChannel IN ('Online', 'In-Store')` | Constrains channels strictly to approved retail modalities. |
| `CK_DimProduct_UnitPrice` | `DimProduct` | `UnitPrice >= 0.00` | Catalog prices must be positive. |
| `CK_DimProduct_UnitCost` | `DimProduct` | `UnitCost >= 0.00` | Catalog costs must be positive. |
| `CK_DimProduct_Category` | `DimProduct` | `Category IN ('Electronics & Gadgets', 'Home & Kitchen', 'Apparel & Accessories', 'Beauty & Personal Care', 'Sports & Outdoors')` | Enforces the 5 canonical corporate merchandise categories. |
| `CK_DimCustomer_Segment` | `DimCustomer` | `CustomerSegment IN ('Regular', 'Silver', 'Gold', 'VIP Platinum')` | Enforces canonical loyalty segment classifications. |
| `CK_DimCustomer_Gender` | `DimCustomer` | `Gender IN ('Female', 'Male', 'Other')` | Enforces standardized customer demographic gender options. |
| `CK_DimStore_SquareFootage` | `DimStore` | `SquareFootage >= 0` | Floor space must be positive (or 0 for digital storefront). |

---

## 6. Indexing Strategy & Query Optimization

Eleven performance-tuned B-Tree indexes support high-throughput analytical query patterns:

### 6.1. FactSales Covering Indexes
1. **`IX_FactSales_DateKey`**:
   - `ON dbo.FactSales(DateKey) INCLUDE (SalesAmount, CostAmount, Profit, Quantity)`
   - *Supported Query Pattern:* Monthly, quarterly, and yearly financial rollups. Covering index eliminates table lookups.
2. **`IX_FactSales_CustomerID`**:
   - `ON dbo.FactSales(CustomerID) INCLUDE (OrderDate, SalesAmount, Profit)`
   - *Supported Query Pattern:* Customer order frequency, customer lifetime spend (Monetary), and RFM score calculation.
3. **`IX_FactSales_ProductID`**:
   - `ON dbo.FactSales(ProductID) INCLUDE (Quantity, SalesAmount, CostAmount, Profit)`
   - *Supported Query Pattern:* SKU-level sales velocity, top 10 products, and profit margin analysis by item.
4. **`IX_FactSales_StoreID`**:
   - `ON dbo.FactSales(StoreID) INCLUDE (SalesAmount, CostAmount, Profit, Quantity)`
   - *Supported Query Pattern:* Store revenue benchmarking, physical vs. online channel contribution.
5. **`IX_FactSales_OrderDate`**:
   - `ON dbo.FactSales(OrderDate)`
   - *Supported Query Pattern:* Rolling window moving averages (30/60/90-day trends) and date-range scan operations.

### 6.2. Dimension Filter & Hierarchy Indexes
6. **`IX_DimCustomer_Region_State`**: `ON dbo.DimCustomer(Region, State) INCLUDE (CustomerSegment)` — Powers regional demographic slicers.
7. **`IX_DimCustomer_Segment`**: `ON dbo.DimCustomer(CustomerSegment)` — Accelerates loyalty tier filtering.
8. **`IX_DimProduct_Category_Subcategory`**: `ON dbo.DimProduct(Category, Subcategory)` — Accelerates matrix drill-down from category to subcategory.
9. **`IX_DimProduct_Brand`**: `ON dbo.DimProduct(Brand)` — Powers manufacturer brand performance filters.
10. **`IX_DimStore_Region_StoreType`**: `ON dbo.DimStore(Region, StoreType)` — Accelerates store format comparisons across regional territories.
11. **`IX_DimDate_Year_Month`**: `ON dbo.DimDate(Year, Month) INCLUDE (QuarterName, MonthName, IsHoliday, IsWeekend)` — Supports fiscal and calendar time intelligence joins.

---

## 7. Foundational Analytical Views

Four curated analytical views provide standard access layers for reporting tools:

1. **`dbo.vw_SalesDetail`**:
   - Combines `FactSales` with all 4 dimension tables.
   - Provides full customer, product, store, and date descriptors alongside line-item financial metrics.
   - Aliases `SalesID` as `TransactionID` for bidirectional traceability with CSV datasets.
2. **`dbo.vw_MonthlySalesSummary`**:
   - Pre-aggregates revenue, COGS, profit, orders, units, and margin percentage by calendar and fiscal month.
   - Powers executive Month-over-Month (MoM) and Year-over-Year (YoY) scorecards.
3. **`dbo.vw_CategoryPerformance`**:
   - Rolls up units, revenue, gross profit, and margin percentages across the 5 categories and 25 subcategories.
   - Pinpoints high-margin merchandise lines vs. low-margin volume drivers.
4. **`dbo.vw_CustomerRFMBase`**:
   - Precomputes customer-level RFM components: `RecencyDays` (relative to 2024-12-31), `OrderFrequency`, `MonetaryValue`, and `TotalProfitContributed`.

---

## 8. Why the Star Schema is Ideal for Retail Analytics & Power BI

1. **Optimized for Power BI VertiPaq Storage Engine:**
   - VertiPaq uses columnar in-memory compression. Star schemas result in high-cardinality facts referencing low-cardinality, highly-compressible dimension tables, achieving 10x compression ratios and sub-second visual renders.
2. **Simplified, Ambiguity-Free DAX Calculations:**
   - In a star schema, all filter relationships flow unidirectionally from the 1-side (Dimensions) to the *-side (FactSales). This eliminates circular filter paths, ambiguous relationships, and the need for complex `USERELATIONSHIP` overrides.
3. **Business User Understandability:**
   - Business analysts immediately grasp "slicing" sales facts by "who" (Customer), "what" (Product), "where" (Store), and "when" (Date).
4. **Drill-Down and Cross-Filtering Flexibility:**
   - Slicing by Category automatically filters Products, which filters Sales, while preserving independent slicing across Customer Segments and Geographic Regions.
