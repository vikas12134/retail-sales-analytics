# Retail Sales & Customer Analytics

An end-to-end enterprise data analytics and business intelligence solution simulating a multi-channel retail organization (**Aura Retail Group**). This project demonstrates a production-grade data analyst workflow—from raw transactional data cleaning and relational Star Schema data warehousing to advanced SQL analytics, robust DAX calculations, and an interactive 6-page Power BI executive reporting suite.

---

## 1. Project Overview

Modern retail enterprises manage vast volumes of transactional data across physical stores and digital storefronts. Without centralized data modeling and automated analytics, leadership faces critical blindspots regarding net profitability, promotional discount efficiency, customer retention, and regional store performance.

This project delivers an enterprise-grade analytics ecosystem built on two full operational years of multi-channel retail data for **Aura Retail Group**:

- **Operational Scale**:
  - **320,536** completed sales transactions across 2023–2024
  - **50,000** registered customers (**47,495** active purchasing accounts)
  - **500** catalog SKUs across 5 core merchandise categories
  - **30** store locations (29 physical retail outlets across 4 regions + 1 direct e-commerce storefront)
  - **731** continuous calendar days modeled in a conformed Date dimension

- **Enterprise Financial & Operational Baseline**:
  - **Total Net Revenue**: **$87,592,529.11** ($87.59M net sales after discounts)
  - **Total Cost of Goods Sold (COGS)**: **$57,785,977.62** ($57.79M procurement cost)
  - **Total Net Profit**: **$29,806,551.49** ($29.81M gross commercial profit)
  - **Net Profit Margin**: **34.03%** (exceeding the corporate benchmark of 20.00%)
  - **Total Physical Units Sold**: **511,058 units**
  - **Average Order Value (AOV)**: **$273.27**
  - **Repeat Customer Rate**: **76.95%** (36,547 repeat buyers generating 88.40% of total revenue)
  - **Annual Year-over-Year (YoY) Growth**: **+8.85%** net revenue expansion

---

## 2. Business Objective

The primary objective is to replace fragmented data silos and manual spreadsheet reporting with an automated, single source of truth that empowers executive stakeholders (CEO, CFO, VP of Sales, Chief Merchandising Officer, and Regional Directors) to make confident, data-backed decisions.

Key strategic goals include:
1. **Profitability & Margin Transparency**: Accurately track true profitability by accounting for Cost of Goods Sold (COGS) and price concessions, preventing misleading top-line revenue assumptions.
2. **Merchandising & Assortment Optimization**: Separate high-margin star products from high-volume, low-margin "margin drainers" to guide procurement, inventory allocation, and supplier negotiations.
3. **Customer Retention & Lifetime Value (LTV)**: Quantify customer acquisition dynamics, repeat buyer behavior, and RFM loyalty segments (Regular, Silver, Gold, VIP Platinum) to optimize retention marketing spend.
4. **Multi-Channel & Regional Benchmarking**: Compare performance across physical store formats (Flagship, Mall Outlet, Standalone, Express) and the e-commerce channel across four geographic territories (North, South, East, West).
5. **Promotional Discount Governance**: Assess margin elasticity across discount tiers (0%, 1–5%, 6–10%, >10%) to curb margin erosion while preserving sales momentum.
6. **Executive Decision Support**: Deliver certified, reproducible business intelligence through interactive visual storytelling, drill-through paths, and actionable recommendations.

---

## 3. Tech Stack: Python, Pandas, SQL Server, Power BI, DAX

| Technology | Role / Domain | Practical Application in Project |
|---|---|---|
| **Python** | Data Engineering & Automation | Scripted ETL pipeline, synthetic retail transaction generation, data profiling, file system orchestration, and logging. |
| **Pandas** | Data Hygiene & Validation | Column-level quality audits, missing value imputation, datatype enforcement, string standardization, duplicate elimination, and referential integrity validation. |
| **SQL Server (T-SQL)** | Relational Data Warehousing | Dedicated staging schema isolation, defensive `BULK INSERT`, atomic transaction loading (`BEGIN TRANSACTION ... COMMIT`), Star Schema dimensional design (Fact + 4 Dimensions), primary/foreign keys, CHECK constraints, non-clustered covering indexes, analytical views, and 9 business query suites. |
| **Power BI** | Business Intelligence & Visual Modeling | VertiPaQ in-memory columnar model (Import Mode), 1-to-many conformed star schema relationships, persistent navigation system, corporate design system (16:9 canvas), dynamic cross-filtering, and custom tooltips. |
| **DAX** | Quantitative KPI Engineering | 50+ explicit measures organized into 8 display folders within a dedicated `_Measures` table; Time Intelligence (`SAMEPERIODLASTYEAR`, `DATEADD`, `TOTALYTD`), dynamic iterators (`SUMX`, `AVERAGEX`), defensive division (`DIVIDE`), and RFM segmentation. |

---

## 4. End-to-End Pipeline

```
Raw CSV ──► Python Cleaning ──► SQL Server ETL ──► SQL Analysis ──► Power BI ──► Business Insights
```

### Stage 1: Raw CSV Ingestion & Profiling
- Ingested multi-channel retail datasets (`customers.csv`, `products.csv`, `stores.csv`, `sales.csv`, `date.csv`) reflecting real-world data collection anomalies, including inconsistent casing, trailing whitespace, missing birth dates, and promotional price variances.

### Stage 2: Python Cleaning & Validation (`python/data_cleaning.py`)
- Standardized merchandise category names and customer segment strings using canonical domain maps.
- Imputed missing values (e.g., median imputation for missing customer birth dates, standardizing phone formatting).
- Applied business logic validation: recalculated and verified `SalesAmount = Quantity * UnitPrice * (1 - Discount)` and `CostAmount = Quantity * UnitCost`.
- Enforced zero duplicates, positive constraints on numerical fields, and referential integrity across parent-child entities.
- Generated clean, standardized production datasets in `data/cleaned/` and automated validation reports in `reports/`.

### Stage 3: SQL Server ETL & Dimensional Warehousing (`sql/staging/` & `sql/database/`)
- **Staging Isolation**: Ingested cleaned CSVs into a dedicated `staging` schema using fast, tab-locked `BULK INSERT` with permissive `VARCHAR` types to prevent conversion crashes.
- **Pre-Load Quality Gate**: Executed 27 automated data quality verification checks on staging tables.
- **Atomic Transformation & Load**: Executed `sql/staging/04_transform_and_load.sql` inside a single atomic transaction block (`BEGIN TRANSACTION ... COMMIT TRANSACTION`) with rollback protection, inserting records in strict foreign-key order into the production `dbo` Star Schema:
  - `dbo.DimDate` (731 rows)
  - `dbo.DimCustomer` (50,000 rows)
  - `dbo.DimProduct` (500 rows)
  - `dbo.DimStore` (30 rows)
  - `dbo.FactSales` (320,536 rows)
- **Post-Load Quality Gate**: Executed 28 automated validation tests verifying row counts, primary key uniqueness, foreign key integrity, and financial reconciliation.

### Stage 4: SQL Exploratory & Diagnostic Analysis (`sql/analysis/`)
- Authored 9 modular T-SQL analytical query suites leveraging Common Table Expressions (CTEs), window functions (`ROW_NUMBER`, `DENSE_RANK`), aggregate rollups, and subqueries to systematically solve the 24 business questions defined in the Business Requirements Document (BRD).

### Stage 5: Power BI Semantic Modeling & DAX (`powerbi/`)
- Connected Power BI Desktop to `RetailSalesAnalytics` via high-performance **Import Mode**.
- Configured a clean Star Schema with 1-to-many, single-direction relationships from dimensions to `FactSales`.
- Set `DimDate` as the official Date Table for robust time-series calculations.
- Engineered 50+ explicit DAX measures housed in a centralized `_Measures` table across 8 standardized display folders: `01 Sales KPIs`, `02 Profitability`, `03 Customers`, `04 Products`, `05 Stores`, `06 Time Intelligence`, `07 Growth`, and `08 Advanced Analytics`.

### Stage 6: Business Insights & Strategic Reporting (`reports/`)
- Developed a 6-page interactive executive reporting suite with custom multi-metric tooltips, dynamic drill-down hierarchies (Year → Quarter → Month; Category → Subcategory → SKU), and strategic diagnostic charts.
- Synthesized quantitative outputs into executive-ready business reports (`reports/business_insights.md` and `reports/portfolio_insights_summary.md`) addressing pricing governance, catalog re-balancing, and customer lifecycle marketing.

---

## 5. Key Business Questions

The project answers **24 core business questions** across 8 operational domains:

### A. Overall Business Performance
1. **Total Financial Scale**: What is the total gross revenue, cost of goods sold, and net profit across the enterprise?
2. **Margin Health**: What is the overall profit margin percentage, and does it meet the enterprise target threshold of $\ge 20\%$?
3. **Basket Dynamics**: What is the enterprise Average Order Value (AOV) and average units sold per transaction?

### B. Sales Pacing & Time Trends
4. **Longitudinal Trends**: How are monthly revenue and net profit trending over time on a Month-over-Month (MoM) and Year-over-Year (YoY) basis?
5. **Seasonality & Purchasing Habits**: Which calendar months and days of the week experience peak purchasing activity?
6. **Profitability Anomalies**: Are there quarters or seasonal events where sales volume surges but profit margins compress?

### C. Product & Merchandise Performance
7. **Volume Drivers**: Which product categories and individual SKUs generate the largest share of net sales revenue?
8. **Profit Leaders**: Which products deliver the highest net profit dollars and highest profit margin percentages?
9. **Margin Drainers**: Which products generate high transaction volume but yield low or negative profit margins?

### D. Customer Demographics & Retention
10. **Customer Acquisition**: How many unique customers have purchased, and what is the monthly new customer acquisition velocity?
11. **Repeat Purchase Economics**: What proportion of active customers are repeat buyers versus one-time purchasers, and what is their revenue contribution?
12. **High-Value Loyalty Tiers**: Who are the top high-value customers by lifetime spend, and how does spend distribute across RFM loyalty tiers?

### E. Physical Store Performance
13. **Store Footprint Benchmarking**: Which store locations generate benchmark revenue, profit, and transaction volume?
14. **Underperforming Locations**: Which retail stores exhibit declining growth or operate below regional profitability averages?
15. **Format Comparison**: How do Flagship, Mall Outlet, Standalone, and Express store formats perform on sales volume and AOV?

### F. Regional Market Dynamics
16. **Territory Contribution**: How is revenue and net profit distributed across the North, South, East, and West sales regions?
17. **Regional Growth Rates**: Which territories represent expanding growth markets versus stagnant operations?
18. **Assortment Variance**: How do merchandise category preferences differ by geographic territory?

### G. Profitability & Promotional Discount Impact
19. **Discount Band Elasticity**: How do promotional discount tiers (0%, 1–5%, 6–10%, >10%) impact gross profit margins?
20. **Price Concession Costs**: What is the total dollar cost surrendered to promotional discounts across categories and channels?
21. **Inelastic Categories**: Which product lines suffer margin erosion from discounting without generating compensatory volume lift?

### H. Strategic Business Opportunities & Risk Mitigation
22. **Product Bundling**: Which categories exhibit natural cross-selling affinity for high-margin accessory bundling?
23. **Churn Prevention**: Which customer segments are at imminent risk of lapsing (>90 days since last order)?
24. **Executive Operational Roadmap**: What prioritized pricing, promotional, inventory, and regional actions should leadership execute next quarter?

---

## 6. Power BI Dashboard Pages

The Power BI reporting suite (`powerbi/Retail_Sales_Customer_Analytics.pbix`) is engineered on a standardized 16:9 widescreen canvas (`1280 x 720 px`) featuring persistent top navigation, horizontal slicers, and contextual tooltips.

```
┌────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│  AURA RETAIL GROUP  |  Executive Analytics Suite   [1. Overview] [2. Trends] [3. Products] [4. Customers] [5. Stores] [6. Profit] │
└────────────────────────────────────────────────────────────────────────────────────────────────────────┘
```

### Page 1 — Executive Overview
- **Purpose**: Provides C-suite leadership with an immediate macroeconomic health check of enterprise performance, revenue velocity, and regional contribution.
- **KPI Summary Cards**:
  - *Total Revenue*: **$87.59M** (Net sales after discounts)
  - *Total Profit*: **$29.81M** (Gross commercial profit)
  - *Profit Margin %*: **34.03%** (Target: $\ge 20.00\%$)
  - *Total Orders*: **320,536** (Completed transactions)
  - *Total Units Sold*: **511,058** (Merchandise volume)
  - *Unique Customers*: **47,495** (Active purchasing accounts)
  - *Revenue YoY %*: **+8.86%** (Annual revenue growth)
- **Core Visuals**:
  - *Monthly Revenue Trend* (Area Chart with chronological date sorting)
  - *Monthly Profit Trend* (Line Chart tracking bottom-line gross profit)
  - *Revenue Share by Region* (Donut Chart showing balanced territorial distribution)
  - *Top 10 Products by Revenue* (Horizontal Bar Chart with profit margin tooltips)
  - *Revenue vs. Profit by Category* (Clustered Column Chart across 5 merchandise divisions)

### Page 2 — Sales & Trends
- **Purpose**: Equips sales leadership and FP&A analysts with longitudinal visibility into seasonal cycles, quarterly pacing, and channel velocity.
- **Core Visuals**:
  - *Revenue vs. Profit Trend with Margin %* (Dual-Axis Combo Chart with Year → Quarter → Month drill-down)
  - *Category Revenue Trajectory* (Stacked Column Chart highlighting seasonal mix shifts)
  - *Regional Sales Velocity* (Stacked Area Chart tracking territorial momentum over 24 months)
  - *Store Format Comparison* (Clustered Bar Chart evaluating Flagship, Mall, Standalone, and Express formats)
  - *Monthly Financial Matrix (P&L Rollup)* (Grid displaying Revenue, Cost, Profit, Margin %, Orders, Units, and MoM/YoY growth indicators)

### Page 3 — Product Performance
- **Purpose**: Enables merchandising officers and category managers to audit catalog profitability, identify star SKUs, and eliminate low-margin loss leaders.
- **Core Visuals**:
  - *Top 10 Products by Revenue vs. Top 10 by Profit* (Side-by-side comparative ranking bars)
  - *Category & Subcategory Profitability Breakdown* (Hierarchical Treemap sized by revenue and shaded by profit margin)
  - *Strategic Portfolio Pricing Matrix* (Scatter Chart mapping Product Revenue vs. Profit Margin % with reference lines for median revenue and target margin, classifying items into Stars, Niche Opportunities, Volume Drivers, and Underperformers)
  - *Bottom 10 Products by Revenue* (Review Table identifying clearance and discontinuation candidates)

### Page 4 — Customer Analytics
- **Purpose**: Enables marketing leadership and CRM teams to evaluate acquisition cohorts, monitor repeat retention rates, and analyze loyalty tier spend.
- **KPI Summary Cards**:
  - *Unique Customers*: **47,495**
  - *Repeat Customers*: **36,547**
  - *Repeat Customer Rate %*: **76.95%** (Target: $\ge 70.00\%$)
  - *Revenue per Customer*: **$1,844.25**
  - *Orders per Customer*: **6.75 transactions/account**
- **Core Visuals**:
  - *Repeat vs. One-Time Customer Split* (Donut Chart: 76.95% repeat vs. 23.05% one-time buyers)
  - *Customer Loyalty Segment Performance* (Combo Chart tracking Revenue, Customer Count, and AOV across Regular, Silver, Gold, and VIP Platinum tiers)
  - *Customer Lifetime Spend Distribution* (Binned Frequency Histogram: `<$500`, `$500-$1K`, `$1K-$2.5K`, `$2.5K-$5K`, `>$5K`)
  - *Top 10 High-Value Customers* (VIP Leaderboard Matrix showing lifetime spend, order count, and AOV)
  - *Demographic Channel Preference* (100% Stacked Bar Chart evaluating gender and sales channel split)

### Page 5 — Store & Regional Performance
- **Purpose**: Enables regional vice presidents and retail operations directors to benchmark store performance, analyze geographic footprint density, and target underperforming stores.
- **Core Visuals**:
  - *Geographic Footprint Density Map* (Bubble Map where size indicates revenue and color saturation represents profit margin %)
  - *Regional Performance Breakdown* (Clustered Bar Chart showing revenue and profit across North, West, South, and East)
  - *Store Network Benchmarking Matrix* (Comprehensive table ranking all 30 retail locations by revenue, profit, margin %, units sold, and YoY growth)
  - *Top 5 Overperforming Stores* (Card tiles highlighting benchmark flagship locations)
  - *Bottom 5 Underperforming Stores* (Card tiles identifying operational intervention and marketing targets)

### Page 6 — Profitability & Opportunities
- **Purpose**: Directs senior executives to margin preservation opportunities, quantifies discount-driven margin erosion, and presents data-backed operational actions.
- **Core Visuals**:
  - *Enterprise Financial Waterfall*:
    - Gross Sales: **$92,279,796.88**
    - Promotional Discounts: **-$4,687,267.77**
    - Net Sales Revenue: **$87,592,529.11**
    - Cost of Goods Sold (COGS): **-$57,785,977.62**
    - Net Commercial Profit: **$29,806,551.49**
  - *Promotional Discount Tier Impact Analysis* (Clustered Column and Line Chart illustrating margin compression from 36.8% at full price down to 26.1% on discounts $>10\%$)
  - *Strategic Portfolio Pricing Matrix* (Scatter Chart evaluating subcategory margin elasticity against sales volume)
  - *Margin Drainer Alert Table* (Detailed table listing high-volume SKUs operating below the 25% margin threshold)
  - *Executive Actionable Strategic Insights Panel* (Text card outlining prioritized commercial recommendations)

---

## 7. Project Structure

```text
retail-sales-analytics/
│
├── data/
│   ├── raw/                                 # Original raw CSV files (customers, products, stores, sales, date)
│   └── cleaned/                             # Validated, cleansed CSV files ready for SQL bulk ingestion
│
├── python/
│   ├── generate_raw_data.py                 # Synthetic retail transactional dataset generator
│   └── data_cleaning.py                     # Automated cleaning, validation, and QA pipeline script
│
├── sql/
│   ├── database/                            # Schema DDL, constraints, indexes, and views
│   │   ├── 01_create_database.sql           # Database creation and configuration
│   │   ├── 02_create_tables.sql             # Star Schema dimensional table definitions
│   │   ├── 03_create_constraints.sql        # Primary keys, foreign keys, and CHECK constraints
│   │   ├── 04_create_indexes.sql            # Non-clustered composite analytical indexes
│   │   ├── 05_create_views.sql              # Analytical reporting views (vw_SalesDetail, etc.)
│   │   └── 06_validate_database.sql         # Automated database schema validation suite
│   ├── staging/                             # ELT staging and data ingestion pipeline
│   │   ├── 01_create_staging_tables.sql     # Permissive staging table definitions
│   │   ├── 02_load_staging_data.sql         # BULK INSERT scripts for staging ingestion
│   │   ├── 03_validate_staging_data.sql     # Pre-load staging quality validation gate (27 checks)
│   │   ├── 04_transform_and_load.sql        # Atomic transactional ELT load into production dbo
│   │   └── 05_validate_final_data.sql       # Post-load production validation gate (28 checks)
│   ├── transformations/                     # Additional schema transformation assets
│   └── analysis/                            # Analytical T-SQL query suites solving BRD questions
│       ├── 01_overall_performance.sql       # Enterprise top-line revenue, profit, and margin KPIs
│       ├── 02_product_performance.sql       # SKU rankings, category margins, and margin drainers
│       ├── 02_sales_trends.sql              # MoM/YoY growth pacing, seasonality, and day-of-week trends
│       ├── 03_customer_performance.sql       # Customer spend tiers, AOV, and purchasing frequency
│       ├── 04_customer_segmentation.sql     # RFM segmentation, customer lifetime value, and cohort retention
│       ├── 05_store_performance.sql         # Store benchmarking, revenue per sq. ft., and format analysis
│       ├── 06_regional_analysis.sql         # Regional market share and geographic demand variance
│       ├── 07_profitability_discount_analysis.sql # Discount band elasticity and gross margin compression
│       └── 08_advanced_analysis.sql         # Multi-item basket affinity, cross-selling, and churn risk
│
├── powerbi/
│   └── Retail_Sales_Customer_Analytics.pbix # Complete Power BI report (Import Mode, Star Schema, DAX)
│
├── reports/
│   ├── business_insights.md                 # In-depth executive business insights report
│   ├── portfolio_insights_summary.md        # High-impact portfolio case study summary
│   ├── data_quality_report.md               # Data quality validation metrics and anomaly log
│   ├── dashboard_validation.md              # Dashboard audit and metric reconciliation guide
│   └── screenshots/                         # Visual export inventory and report screenshots
│       └── README.md                        # Screenshot documentation and capture inventory
│
├── documentation/                           # Architecture specifications and technical manuals
│   ├── business_requirements.md             # Business Requirements Document (24 questions & 12 KPIs)
│   ├── data_cleaning_rules.md               # Detailed cleaning specifications and domain maps
│   ├── sql_database_design.md               # Star Schema relational architecture and ERD documentation
│   ├── sql_etl_process.md                   # Complete ELT architecture and script execution guide
│   ├── sql_setup_guide.md                   # Step-by-step SSMS database deployment manual
│   ├── sql_data_loading_guide.md            # BULK INSERT procedures and path configuration
│   ├── powerbi_data_model.md                # Semantic dimensional model and VertiPaQ architecture
│   ├── dax_measures.md                      # Comprehensive 50+ DAX measure reference guide
│   ├── dax_business_question_mapping.md     # Matrix mapping DAX measures to BRD business questions
│   ├── powerbi_connection_guide.md          # SQL Server Import mode connection walkthrough
│   ├── powerbi_dashboard_guide.md           # 6-page visual architecture, grid layout, and UI guide
│   └── business_analysis_interview_notes.md # Stakeholder interview transcripts and domain context
│
└── README.md                                # Master project documentation
```

---

## 8. Key Skills Demonstrated

- **Data Engineering & Hygiene**: Built an automated Python and Pandas data cleaning pipeline handling missing values, casing inconsistencies, whitespaces, date formatting, and referential integrity constraints across 320,000+ records.
- **Relational Data Warehousing**: Architected a certified Kimball Star Schema in Microsoft SQL Server featuring staging schema isolation, defensive `BULK INSERT` routines, atomic transaction control (`BEGIN TRANSACTION ... COMMIT`), primary/foreign keys, and composite B-tree covering indexes.
- **Defensive Data Quality Control**: Implemented two automated SQL validation gates (27 pre-load checks and 28 post-load checks) ensuring zero orphan keys, zero duplicate records, and 100% financial balance reconciliation.
- **Advanced T-SQL Analytics**: Developed production queries employing window functions (`ROW_NUMBER`, `DENSE_RANK`), Common Table Expressions (CTEs), multi-level grouping sets, cohort retention matrices, and RFM scoring models.
- **Semantic Data Modeling**: Configured a conformed Star Schema in Power BI with 1-to-many, single-direction relationships, explicit dimension keys, and an official Date dimension table.
- **DAX Formula Engineering**: Authored 50+ explicit measures within a centralized `_Measures` table across 8 display folders, incorporating Time Intelligence (`SAMEPERIODLASTYEAR`, `DATEADD`, `TOTALYTD`), dynamic iterators (`SUMX`, `AVERAGEX`), defensive division (`DIVIDE`), and dynamic ranking (`RANKX`).
- **Executive Visual Storytelling & UI/UX**: Designed a 6-page report suite on a structured 16:9 canvas using an intentional corporate color palette, persistent header navigation, custom multi-metric tooltips, interactive drill-downs, financial waterfalls, and strategic scatter quadrants.
- **Commercial Business Acumen**: Translated complex transactional patterns into quantified business strategies, including promotional discount governance, high-margin category re-balancing, and targeted customer retention initiatives.

---

## 9. How to Run / Use the Project

### Prerequisites
- **Python 3.9+** with `pandas` and `numpy` installed (`pip install pandas numpy`)
- **Microsoft SQL Server** (2019, 2022, 2025, or SQL Server Express)
- **SQL Server Management Studio (SSMS)**, **Azure Data Studio**, or `sqlcmd`
- **Microsoft Power BI Desktop** (Latest version recommended)

---

### Step 1: Clone or Open the Repository
```bash
git clone https://github.com/vikas12134/retail-sales-analytics.git
cd retail-sales-analytics
```

---

### Step 2: (Optional) Run the Python Data Cleaning Pipeline
The repository already includes pre-cleaned datasets in `data/cleaned/`. To re-run the cleaning pipeline from raw data:
```bash
python python/data_cleaning.py
```
This script profiles the raw data, applies standardization rules, verifies financial reconciliation, and outputs cleaned CSVs to `data/cleaned/`.

---

### Step 3: Deploy the SQL Server Data Warehouse
Open **SQL Server Management Studio (SSMS)** and connect to your local database engine (`localhost` or `.\SQLEXPRESS`).

1. **Create Database**:
   - Open and execute `sql/database/01_create_database.sql` to initialize `[RetailSalesAnalytics]`.
2. **Create Star Schema Tables**:
   - Open and execute `sql/database/02_create_tables.sql` to create `DimDate`, `DimCustomer`, `DimProduct`, `DimStore`, and `FactSales`.
3. **Apply Constraints & Indexes**:
   - Open and execute `sql/database/03_create_constraints.sql` (Foreign Keys and CHECK constraints).
   - Open and execute `sql/database/04_create_indexes.sql` (Analytical B-Tree indexes).
4. **Create Reporting Views**:
   - Open and execute `sql/database/05_create_views.sql` (e.g., `vw_SalesDetail`, `vw_MonthlySalesSummary`).
5. **Verify Database Structure**:
   - Open and execute `sql/database/06_validate_database.sql` to verify table schemas and constraints.

---

### Step 4: Execute the SQL Server ETL Ingestion Pipeline
1. **Create Staging Schema & Tables**:
   - Execute `sql/staging/01_create_staging_tables.sql`.
2. **Bulk Ingest Cleaned Data**:
   - Open `sql/staging/02_load_staging_data.sql`.
   - Update the file paths to point to your local absolute path for `data/cleaned/` (e.g., `D:\Data_Analytics\retail-sales-analytics\data\cleaned\*.csv`).
   - Execute the script to load data into the staging tables.
3. **Run Pre-Load Validation**:
   - Execute `sql/staging/03_validate_staging_data.sql` to verify 27 quality checks.
4. **Transform and Load into Production**:
   - Execute `sql/staging/04_transform_and_load.sql` to populate the `dbo` Star Schema tables inside an atomic transaction.
5. **Run Post-Load Validation**:
   - Execute `sql/staging/05_validate_final_data.sql` to verify the 28 production quality tests.

---

### Step 5: Run Exploratory SQL Analysis Queries
Open and execute any of the scripts in `sql/analysis/` in SSMS to query business metrics directly:
- `01_overall_performance.sql`
- `02_product_performance.sql`
- `02_sales_trends.sql`
- `03_customer_performance.sql`
- `04_customer_segmentation.sql`
- `05_store_performance.sql`
- `06_regional_analysis.sql`
- `07_profitability_discount_analysis.sql`
- `08_advanced_analysis.sql`

---

### Step 6: Explore the Power BI Report
1. Launch **Microsoft Power BI Desktop**.
2. Open `powerbi/Retail_Sales_Customer_Analytics.pbix`.
3. Because the report is saved in **Import Mode**, all data, DAX measures, and visual dashboards are fully pre-loaded and interactive offline.
4. *(Optional Refresh)*: To point the report to your local SQL Server instance, select **Transform Data** $\rightarrow$ **Data source settings**, enter your local SQL Server instance name and database (`RetailSalesAnalytics`), and click **Refresh**.

---

## 10. GitHub Portfolio Note

This project is developed as an end-to-end data analytics portfolio showcase designed to demonstrate technical proficiency, structured data modeling, analytical rigor, and executive visual storytelling according to real-world enterprise standards.

All metrics, data schemas, SQL transformations, DAX expressions, and business findings contained in this repository are fully documented and reproducible. Technical recruiters, hiring managers, and analytics leaders are invited to inspect the source code, data model, and project documentation.

- **Author**: Data Analytics Candidate
- **Repository**: [github.com/vikas12134/retail-sales-analytics](https://github.com/vikas12134/retail-sales-analytics)
- **Connect**: [LinkedIn Profile](https://linkedin.com) | [Portfolio Website](https://github.com/vikas12134)
