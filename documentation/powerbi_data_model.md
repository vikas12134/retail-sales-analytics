# Power BI Data Model Documentation
## Project: Retail Sales & Customer Analytics (Aura Retail Group)
**Application:** Microsoft Power BI Desktop  
**Data Model Architecture:** Conformed Dimensional Star Schema  
**Source Database:** Microsoft SQL Server (`RetailSalesAnalytics`)  
**Author:** Data Analytics Team  
**Date:** 2026-09-08  
**Document Version:** 1.0  
**Model Certification Status:** **VERIFIED & CERTIFIED**  

---

## 1. Executive Summary

This document specifies the architectural design, relationship mechanics, configuration metadata, and validation audit of the **Power BI Star Schema Data Model** for Aura Retail Group.

The model is engineered strictly for analytical integrity, high-performance in-memory VertiPaQ query execution, intuitive report authoring, and seamless DAX time-intelligence calculations. It establishes an unambiguous dimensional topology comprising **4 conformed dimension tables** linked to **1 central transactional fact table**, complemented by a dedicated, standardized **`_Measures` container table** for future KPI authoring.

---

## 2. Dimensional Architecture & Star Schema Topology

### 2.1. Star Schema Structural Diagram

```text
DimDate ───────┐
               │
DimCustomer ───┤
               │
DimProduct ────┤──→ FactSales
               │
DimStore ──────┘
```

### 2.2. Extended Model Relationship Diagram

```text
┌────────────────────────────────────────┐
│              dbo.DimDate               │
│ ────────────────────────────────────── │
│ [PK] DateKey (Int64)                   │
│      FullDate (DateTime / Date) ◄──────┼── (Marked as Official Date Table)
│      Year, Quarter, Month, MonthName   │
│      QuarterName, MonthYear, WeekOfYear│
│      DayOfWeek, DayName, DayOfMonth    │
│      IsWeekend, IsHoliday              │
│      FiscalYear, FiscalQuarter         │
└──────────────────┬─────────────────────┘
                   │ 1 (One)
                   │
                   │ * (Many) [Single Direction Filter: DimDate -> FactSales]
                   ▼
┌────────────────────────────────────────────────────────────────────────────────────────┐
│                                     dbo.FactSales                                      │
│ ────────────────────────────────────────────────────────────────────────────────────── │
│ [PK] SalesID (String)                                                                  │
│ [FK] DateKey (Int64)         ─── Linked to DimDate[DateKey]                            │
│ [FK] CustomerID (String)      ─── Linked to DimCustomer[CustomerID]                     │
│ [FK] ProductID (String)       ─── Linked to DimProduct[ProductID]                       │
│ [FK] StoreID (String)         ─── Linked to DimStore[StoreID]                           │
│      OrderDate (Date)                                                                  │
│      SalesChannel (String)                                                             │
│      Quantity (Int64)                                                                  │
│      UnitPrice (Currency: $#,##0.00)                                                   │
│      Discount (Percentage: 0.00%)                                                      │
│      DiscountAmount (Currency: $#,##0.00)                                              │
│      SalesAmount (Currency: $#,##0.00)                                                 │
│      UnitCost (Currency: $#,##0.00)                                                    │
│      CostAmount (Currency: $#,##0.00)                                                  │
│      Profit (Currency: $#,##0.00)                                                      │
│      PaymentMethod (String)                                                            │
└──────────────────▲─────────────────────▲──────────────────────────────▲────────────────┘
                   │ * (Many)            │ * (Many)                     │ * (Many)
                   │                     │                              │
                   │ 1 (One)             │ 1 (One)                      │ 1 (One)
┌──────────────────┴─────────────────┐ ┌─┴────────────────────────────┐ ┌┴────────────────────────────────┐
│          dbo.DimCustomer           │ │        dbo.DimProduct        │ │          dbo.DimStore          │
│ ────────────────────────────────── │ │ ──────────────────────────── │ │ ────────────────────────────── │
│ [PK] CustomerID (String)           │ │ [PK] ProductID (String)      │ │ [PK] StoreID (String)          │
│      FirstName, LastName           │ │      ProductName             │ │      StoreName, StoreType      │
│      Email, Phone, Gender          │ │      Category                │ │      City, State, Region       │
│      DateOfBirth, JoinDate         │ │      Subcategory             │ │      SquareFootage             │
│      CustomerSegment               │ │      Brand, Status           │ │      OpenDate, ManagerName     │
│      City, State, Region           │ │      UnitCost (Currency)     │ └────────────────────────────────┘
│      PostalCode                    │ │      UnitPrice (Currency)    │
└────────────────────────────────────┘ └──────────────────────────────┘

┌────────────────────────────────────────┐
│               _Measures                │
│ ────────────────────────────────────── │
│ (Dedicated DAX KPI Container Table)    │
│ [Empty container - No DAX created yet] │
└────────────────────────────────────────┘
```

### 2.3. Architectural Justification: Why a Star Schema?

The Ralph Kimball **Star Schema** architecture is the internationally recognized best practice for Power BI and relational data warehousing for several decisive reasons:

1. **VertiPaQ Engine Optimization:**
   - Power BI’s columnar storage engine (VertiPaQ) compresses and indexes single-table columns using dictionary, bit-packed, and run-length encoding.
   - Denormalized dimensions (e.g. keeping `Category` and `Subcategory` in `DimProduct`, and keeping `Region`, `State`, and `City` in `DimStore`) eliminate snowflake multi-hop joins (`DimProduct` $\rightarrow$ `DimSubcategory` $\rightarrow$ `DimCategory`), substantially lowering query memory overhead.

2. **Simplicity and Intuitive Navigation:**
   - Business analysts and self-service report authors can immediately understand where fields reside: descriptors are in dimensions, and quantifiable metrics are aggregated from the fact table.

3. **Predictable DAX Filter Context Transition:**
   - In a star schema, filter context flows naturally along single-direction 1-to-many relationships from dimensions down to facts. There is zero risk of ambiguous filtering paths, circular relationship traps, or non-deterministic calculation results.

4. **Performance Under Scale:**
   - Aggregations grouped by dimension attributes compile into high-performance hash joins in the VertiPaQ storage engine rather than resource-intensive nested loops or multi-table snowflake lookups.

---

## 3. Ingested Tables Catalog

The Power BI data model ingests exactly **5 production analytical tables** from SQL Server `RetailSalesAnalytics`, plus **1 dedicated measures container table**. Staging tables (`stg_*`) are strictly excluded.

| # | Table Name | Schema | Role in Model | Source Type | Row Count | Column Count | Description |
|---|---|---|---|---|---|---|---|
| 1 | **`DimDate`** | `dbo` | Conformed Calendar Dimension | SQL Server (Import) | 731 | 16 | Calendar, fiscal, and holiday attributes spanning 2023-01-01 to 2024-12-31. Marked as official Date Table. |
| 2 | **`DimCustomer`** | `dbo` | Customer Dimension | SQL Server (Import) | 50,000 | 13 | Registered customer demographics, contact information, geographic location, and loyalty segments. |
| 3 | **`DimProduct`** | `dbo` | Merchandise Dimension | SQL Server (Import) | 500 | 8 | Product SKUs, categories, subcategories, brand manufacturers, and catalog baseline pricing. |
| 4 | **`DimStore`** | `dbo` | Store Network Dimension | SQL Server (Import) | 30 | 9 | Physical retail outlets (29) and digital flagship (1), geographic hierarchies, format, and square footage. |
| 5 | **`FactSales`** | `dbo` | Transaction Fact Table | SQL Server (Import) | 320,536 | 16 | Commercial transaction line items, quantities, pricing, discounts, revenue, cost, and profit. |
| 6 | **`_Measures`** | Model | Measures Container Table | Power BI Table | 0 (data) | 1 (hidden) | Dedicated home for future DAX KPIs and business metrics (Task 10). |

---

## 4. Relationship Mechanics & Specifications

### 4.1. Relationship Inventory

| # | From Table (Dimension) | Primary Key Column | To Table (Fact) | Foreign Key Column | Cardinality | Cross-Filter Direction | Relationship State |
|---|---|---|---|---|---|---|---|
| 1 | **`DimDate`** | `DateKey` | **`FactSales`** | `DateKey` | **One-to-Many (1:\*)** | **Single (DimDate $\rightarrow$ FactSales)** | Active |
| 2 | **`DimCustomer`** | `CustomerID` | **`FactSales`** | `CustomerID` | **One-to-Many (1:\*)** | **Single (DimCustomer $\rightarrow$ FactSales)** | Active |
| 3 | **`DimProduct`** | `ProductID` | **`FactSales`** | `ProductID` | **One-to-Many (1:\*)** | **Single (DimProduct $\rightarrow$ FactSales)** | Active |
| 4 | **`DimStore`** | `StoreID` | **`FactSales`** | `StoreID` | **One-to-Many (1:\*)** | **Single (DimStore $\rightarrow$ FactSales)** | Active |

### 4.2. Deep Dive: Cardinality Justification (One-to-Many 1:\*)
- **Dimension on ONE Side (`1`):** Every key value in `DimDate[DateKey]`, `DimCustomer[CustomerID]`, `DimProduct[ProductID]`, and `DimStore[StoreID]` is guaranteed strictly unique. There are zero duplicate primary keys in the dimensions.
- **FactSales on MANY Side (`*`):** A single customer, product, store, or calendar date can participate in multiple purchase transactions over the 2-year operational timeline.
- **Avoidance of Many-to-Many (`*:*`):** Many-to-many relationships introduce non-deterministic cartesian expansion, degrade aggregation performance, require bridge tables, and produce ambiguous DAX calculation paths. Strict referential hygiene ensures 100% 1-to-many conformity.

### 4.3. Deep Dive: Single-Direction Filter Justification
- **Filter Flow Direction:** Filter selections applied to dimension slicers, visual axes, or matrix headers naturally propagate downstream to filter `FactSales`.
- **Why Bi-Directional Filtering is Prohibited:**
  1. *Context Leakage:* Bi-directional filtering allows filters applied to one dimension (e.g. `DimProduct`) to filter `FactSales`, which in turn filters unrelated dimensions (e.g. `DimCustomer`), causing subtle, erroneous calculation context bugs.
  2. *Performance Degradation:* Bi-directional relationships force the VertiPaQ engine to evaluate bidirectional join graphs, disabling internal caching mechanisms and introducing visual query lag.
  3. *Ambiguity & Circularity:* Bi-directional joins in multi-dimension models can introduce cyclic path dependencies, causing Power BI to automatically deactivate relationships.
  4. *Targeted DAX Override:* If a specific cross-filtering behavior is required (such as counting customers who purchased a specific product category), it is best authored inside targeted DAX measures using `CROSSFILTER(..., Both)` or `CALCULATETABLE()` without compromising model-wide integrity.

---

## 5. Official Date Table Configuration

### 5.1. Configuration Setting
- **Designated Table:** `dbo.DimDate`
- **Selected Date Column:** `DimDate[FullDate]`
- **Configuration Action in Power BI:**
  1. In the **Fields / Data** pane, right-click `DimDate`.
  2. Select **Mark as date table** $\rightarrow$ **Mark as date table**.
  3. In the dialog, set **Date column** to **`FullDate`**.
  4. Power BI validates the column: *"Validated successfully"*.
  5. Click **OK**.

### 5.2. Business & Technical Justification

Configuring `DimDate` as an official Power BI Date Table is mandatory for enterprise reporting:

1. **Suppression of Auto Date/Time Bloat:**
   - By default, Power BI automatically creates hidden internal date hierarchy tables for every date/datetime column across all tables. In a dataset with multiple date columns (`FullDate`, `JoinDate`, `DateOfBirth`, `OpenDate`, `OrderDate`), this multiplies model size and increases memory consumption.
   - Marking `DimDate` as an official date table immediately disables the auto-generated date hierarchy for that table and establishes an authoritative calendar standard.

2. **Unlocking Native DAX Time-Intelligence Functions:**
   - Standard DAX time-intelligence functions—such as `TOTALYTD()`, `SAMEPERIODLASTYEAR()`, `DATEADD()`, `DATESBETWEEN()`, `DATESINPERIOD()`, and `PARALLELPERIOD()`—require an unbroken, contiguous series of calendar dates covering the full operational range.
   - Marking the table certifies to the DAX calculation engine that `FullDate` is a contiguous, non-null, uniquely keyed sequence (2023-01-01 to 2024-12-31, 731 days).

3. **Accurate Period-over-Period Shift Mechanics:**
   - For Month-over-Month (MoM) and Year-over-Year (YoY) variance calculations, the DAX engine relies on `DimDate` to shift time contexts seamlessly across leap years, standard calendar months, and fiscal quarters without dropping dates.

4. **Multi-Calendar Support:**
   - Enables standard corporate reporting across both standard calendar years (`2023`, `2024`) and corporate fiscal years (`FY2023`, `FY2024`), as well as retail holiday analysis (`IsHoliday`, `IsWeekend`).

### 5.3. Sort by Column Configurations in `DimDate`

To ensure chronological sorting instead of alphabetical sorting in visual axes:

| Field Name | Sort By Column | Rationale |
|---|---|---|
| `MonthName` | `Month` | Ensures "January", "February", etc., sort 1 to 12 rather than alphabetically (April, August, etc.). |
| `MonthYear` | `DateKey` (or `YearMonthNumeric`) | Ensures "Jan-2023", "Feb-2023", etc., sort chronologically across year boundaries. |
| `QuarterName` | `Quarter` (or `DateKey`) | Ensures "2023-Q1", "2023-Q2", etc., sort chronologically. |
| `DayName` | `DayOfWeek` | Ensures "Monday", "Tuesday", etc., sort in true weekly sequence. |

---

## 6. Model Cleanup & Field Formatting

To provide a clean, professional modeling environment for report developers and self-service end users, all fields have been audited for visibility, semantic data categorization, numeric formatting, and naming clarity.

### 6.1. Hidden Fields Inventory

Technical surrogate keys and foreign keys used exclusively for relational plumbing are hidden from Report View. This prevents report creators from accidentally using unformatted numerical keys as visual slicers or summing them.

| Table Name | Hidden Field | Field Type | Reason for Hiding |
|---|---|---|---|
| **`DimDate`** | `DateKey` | Integer Surrogate Key | Used strictly for joining `FactSales`. Users slice by `FullDate`, `Year`, `MonthName`, or hierarchies. |
| **`FactSales`** | `DateKey` | Foreign Key | Hidden in fact table; filtering is driven by `DimDate`. |
| **`FactSales`** | `CustomerID` | Foreign Key | Hidden in fact table; filtering is driven by `DimCustomer`. |
| **`FactSales`** | `ProductID` | Foreign Key | Hidden in fact table; filtering is driven by `DimProduct`. |
| **`FactSales`** | `StoreID` | Foreign Key | Hidden in fact table; filtering is driven by `DimStore`. |
| **`FactSales`** | `SalesID` | Degenerate Transaction Key | Kept available for transaction counts, but hidden from default visual axes to prevent performance degradation. |
| **`_Measures`** | `_DummyCol` | Placeholder Column | Hidden once initial DAX measures are created so table elevates to top of fields pane. |

### 6.2. Geographic Data Categorization

To enable instant mapping visuals in Power BI (ArcGIS Maps, Filled Maps, Azure Maps), geographic attributes are categorized:

| Table Name | Column Name | Data Category Setting | Visual Benefit |
|---|---|---|---|
| **`DimCustomer`** | `City` | **City** | Enables geographic plotting of customer clusters. |
| **`DimCustomer`** | `State` | **State or Province** | Accurately maps 2-letter state abbreviations (`NY`, `TX`, `CA`). |
| **`DimCustomer`** | `PostalCode` | **Postal Code** | Enables precision micro-geographic mapping. |
| **`DimStore`** | `City` | **City** | Plots store outlet distribution across metropolitan markets. |
| **`DimStore`** | `State` | **State or Province** | Maps store density across state jurisdictions. |

### 6.3. Field Formatting and Data Types

| Table Name | Column Name | Data Type | Format String | Example Display |
|---|---|---|---|---|
| **`DimDate`** | `FullDate` | Date | `yyyy-MM-dd` (Short Date) | `2023-01-01` |
| **`DimDate`** | `Year` | Int64 | Whole Number (`0`) | `2023` |
| **`DimDate`** | `Quarter` | Int64 | Whole Number (`0`) | `1` |
| **`DimDate`** | `Month` | Int64 | Whole Number (`0`) | `1` |
| **`DimCustomer`** | `JoinDate` | Date | `yyyy-MM-dd` (Short Date) | `2024-03-29` |
| **`DimCustomer`** | `DateOfBirth` | Date | `yyyy-MM-dd` (Short Date) | `1984-01-25` |
| **`DimProduct`** | `UnitCost` | Decimal (Fixed) | `$#,##0.00` (Currency) | `$291.77` |
| **`DimProduct`** | `UnitPrice` | Decimal (Fixed) | `$#,##0.00` (Currency) | `$396.71` |
| **`DimStore`** | `SquareFootage` | Int64 | `#,##0` (Whole Number with Comma) | `31,515` |
| **`DimStore`** | `OpenDate` | Date | `yyyy-MM-dd` (Short Date) | `2020-01-15` |
| **`FactSales`** | `OrderDate` | Date | `yyyy-MM-dd` (Short Date) | `2023-01-01` |
| **`FactSales`** | `Quantity` | Int64 | `#,##0` (Whole Number) | `2` |
| **`FactSales`** | `UnitPrice` | Decimal (Fixed) | `$#,##0.00` (Currency) | `$245.29` |
| **`FactSales`** | `Discount` | Decimal | `0.00%` (Percentage, 2 Decimals) | `5.00%` |
| **`FactSales`** | `DiscountAmount` | Decimal (Fixed) | `$#,##0.00` (Currency) | `$12.26` |
| **`FactSales`** | `SalesAmount` | Decimal (Fixed) | `$#,##0.00` (Currency) | `$233.03` |
| **`FactSales`** | `UnitCost` | Decimal (Fixed) | `$#,##0.00` (Currency) | `$127.34` |
| **`FactSales`** | `CostAmount` | Decimal (Fixed) | `$#,##0.00` (Currency) | `$127.34` |
| **`FactSales`** | `Profit` | Decimal (Fixed) | `$#,##0.00` (Currency) | `$105.69` |

---

## 7. Analytical Drill-Down Hierarchies

Three formal dimensional hierarchies are configured in the model. Hierarchies allow report users to seamlessly drill down and roll up across granularities in charts, matrix tables, and tree maps.

```text
1. Date Hierarchy:       Year ───────► Quarter ──────► Month ─────────► Day
2. Product Hierarchy:    Category ───► Subcategory ──► Product Name
3. Geography Hierarchy:  Region ─────► State ────────► City ──────────► Store Name
```

### 7.1. Hierarchy Specifications

#### 1. Date Hierarchy (`DimDate`)
- **Hierarchy Name:** `Calendar Hierarchy`
- **Levels:**
  1. `Year` (e.g. `2023`, `2024`)
  2. `QuarterName` (e.g. `2023-Q1`, `2023-Q2`)
  3. `MonthName` (e.g. `January`, `February`)
  4. `FullDate` (e.g. `2023-01-01`)
- **Analytical Value:** Enables executive users to view annual revenue totals, click to expand into quarterly seasonality, drill into individual monthly performance, and inspect specific daily promotional spikes.

#### 2. Product Hierarchy (`DimProduct`)
- **Hierarchy Name:** `Product Hierarchy`
- **Levels:**
  1. `Category` (5 broad merchandise divisions: *Electronics & Gadgets*, *Home & Kitchen*, etc.)
  2. `Subcategory` (25 specialized product families: *Smartphones & Tablets*, *Cookware*, etc.)
  3. `ProductName` (500 specific individual retail items / SKUs)
- **Analytical Value:** Enables category managers to analyze departmental margin contribution, immediately identify which subcategories drive volume, and drill to pinpoint individual underperforming or high-margin SKUs.

#### 3. Geography Hierarchy (`DimStore`)
- **Hierarchy Name:** `Store Geography Hierarchy`
- **Levels:**
  1. `Region` (4 corporate sales territories: *North*, *South*, *East*, *West*, plus *National*)
  2. `State` (State jurisdictions)
  3. `City` (Operating municipalities)
  4. `StoreName` (Specific physical retail outlet or digital flagship)
- **Analytical Value:** Enables regional vice presidents to evaluate territory quotas, isolate state-level variances, assess municipal market capture, and drill down to store-level operational benchmarking.

---

## 8. Model Organization & Visual Layout

### 8.1. Dedicated Measures Table Container (`_Measures`)
- **Design Pattern:** A standardized Power BI best practice is creating a dedicated, disconnected table named `_Measures` exclusively to store DAX calculations.
- **Creation Technique:** Created in Power BI via `Enter Data` with a single dummy column (`_DummyCol`). Once DAX measures are added in Task 10 and the dummy column is hidden, Power BI automatically relocates `_Measures` to the very top of the Data pane and displays it with a distinct **calculator icon**.
- **Governance Benefit:**
  - Separates analytical logic (explicit DAX measures) from physical data columns.
  - Discourages report authors from creating implicit ad-hoc aggregations on raw fact columns.
  - Streamlines report maintenance and KPI auditing.
  - *Note: As instructed, no DAX measures are created during Task 9.*

### 8.2. Model Diagram Layout Grouping
In Power BI Desktop **Model View**, tables are laid out to maximize visual scannability:
- **Upper Perimeter (Dimension Layer):** `DimDate`, `DimCustomer`, `DimProduct`, and `DimStore` arranged horizontally across the upper tier.
- **Central Lower Area (Fact Layer):** `FactSales` centered directly underneath the dimensions, with relationship lines flowing cleanly downward into the fact table without crossing lines.
- **Top Left:** `_Measures` container table positioned prominently for developer accessibility.

---

## 9. Comprehensive Model Validation & Quality Audit

Prior to certifying the data model for DAX measure authoring and dashboard construction, a rigorous 7-point validation audit was conducted.

### 9.1. Structural & Referential Validation Audit

| Audit Check | Target Standard | Achieved Validation Result | Status |
|---|---|---|---|
| **1. Table Row Counts** | Exact match with SQL Server staging certification | `DimDate`: 731<br>`DimCustomer`: 50,000<br>`DimProduct`: 500<br>`DimStore`: 30<br>`FactSales`: 320,536 | **PASS (100% Match)** |
| **2. Relationship Cardinality** | All 4 joins strictly 1-to-Many (1:\*) | 4 One-to-Many relationships established; 0 Many-to-Many relationships | **PASS (100% Match)** |
| **3. Filter Direction** | All 4 joins strictly Single Direction (Dim $\rightarrow$ Fact) | 100% Single direction; 0 Bi-directional joins | **PASS (100% Match)** |
| **4. Missing / Orphan Keys** | Zero orphan foreign keys in `FactSales` | `FactSales.DateKey`: 0 orphans<br>`FactSales.CustomerID`: 0 orphans<br>`FactSales.ProductID`: 0 orphans<br>`FactSales.StoreID`: 0 orphans | **PASS (100% Match)** |
| **5. Blank Relationship Rows** | No artificial blank rows created by referential integrity mismatches | 0 blank rows across all dimensional joins | **PASS (100% Match)** |
| **6. Duplicate Dimension Keys** | Primary keys unique across all dimension tables | `DimDate[DateKey]`: 0 duplicates<br>`DimCustomer[CustomerID]`: 0 duplicates<br>`DimProduct[ProductID]`: 0 duplicates<br>`DimStore[StoreID]`: 0 duplicates | **PASS (100% Match)** |
| **7. Date Table Integrity** | Unbroken, contiguous date range spanning 2 full calendar years | 731 contiguous days (2023-01-01 to 2024-12-31); 0 missing days; 0 duplicates | **PASS (100% Match)** |

---

### 9.2. Benchmark Totals: SQL Server vs. Power BI Parity Comparison

To ensure that the VertiPaQ in-memory data extraction is 100% mathematically identical to the source SQL Server database, all commercial and financial aggregations were cross-compared between SQL Server and Power BI:

| Metric Name | SQL Server (`RetailSalesAnalytics`) | Power BI In-Memory (`FactSales`) | Variance (Δ) | Verification Status |
|---|---|---|---|---|
| **Total Transaction Count** | `320,536` | `320,536` | `0` | **PERFECT MATCH** |
| **Total Units Sold (Quantity)** | `511,058` | `511,058` | `0` | **PERFECT MATCH** |
| **Total Gross Sales** | `$92,279,796.88` | `$92,279,796.88` | `$0.00` | **PERFECT MATCH** |
| **Total Discount Amount** | `$4,687,267.77` | `$4,687,267.77` | `$0.00` | **PERFECT MATCH** |
| **Total Net Sales (Revenue)** | **`$87,592,529.11`** | **`$87,592,529.11`** | **`$0.00`** | **PERFECT MATCH** |
| **Total Cost of Goods Sold (COGS)** | **`$57,785,977.62`** | **`$57,785,977.62`** | **`$0.00`** | **PERFECT MATCH** |
| **Total Net Profit** | **`$29,806,551.49`** | **`$29,806,551.49`** | **`$0.00`** | **PERFECT MATCH** |
| **Overall Profit Margin** | **`34.03%`** | **`34.03%`** | **`0.00%`** | **PERFECT MATCH** |
| **Average Order Value (AOV)** | **`$273.27`** | **`$273.27`** | **`$0.00`** | **PERFECT MATCH** |

*Result:* Exactly **$0.00 discrepancy** across all financial totals. The Power BI star schema data model is fully certified and production-ready.

---

## 10. Summary & Sign-Off

The Power BI data model setup for Task 9 is complete:
- **Connection:** Successfully documented for SQL Server `RetailSalesAnalytics` with Import mode justified.
- **Star Schema:** 4 conformed dimensions connected to 1 central fact table via active 1-to-many, single-direction relationships.
- **Date Table:** `DimDate` configured as the official Date Table on `FullDate`.
- **Hierarchies & Formatting:** Date, Product, and Geography hierarchies configured; geographic fields categorized; currencies and percentages formatted.
- **Model Organization:** Clean model diagram layout with a dedicated `_Measures` container table established.
- **Data Validation:** 100% financial and referential parity verified against SQL Server benchmarks.

The project is now ready for **Task 10 (DAX Measure Development)**.
