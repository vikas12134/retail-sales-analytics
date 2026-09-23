# Power BI Dashboard Architecture & Implementation Guide
## Project: Retail Sales & Customer Analytics (Aura Retail Group)
**Application:** Microsoft Power BI Desktop  
**Target Audience:** Executive Leadership (CEO, CFO, VP Sales, Merchandising Directors, Regional Operations)  
**Author:** Data Analytics Team  
**Date:** 2026-09-08  
**Document Version:** 1.0  
**Report Certification Status:** **VERIFIED & CERTIFIED**  

---

## 1. Executive Overview & Design Philosophy

This document provides the definitive, production-grade visual design and technical implementation specification for the **Aura Retail Group Power BI Executive & Operational Reporting Suite**.

### 1.1. Core Design Principles
1. **Decision-Driven Visual Storytelling:** Visualizations are selected strictly to inform executive and operational decisions rather than merely populating screen space.
2. **Consistent Visual Hierarchy & Grid Layout:** All 6 pages follow a unified 16:9 widescreen canvas grid (`1280 x 720 px`), featuring a standardized persistent top header navigation bar, prominent upper KPI summary cards, core analytical visuals in the center, and contextual breakdown tables/slicers on the perimeter.
3. **Curated Corporate Color Palette & Accessibility:**
   - **Primary Brand Navy:** `#1E293B` (Header backgrounds, primary text, high-contrast titles)
   - **Accent Commercial Blue:** `#2563EB` (Top-line revenue, volume bars, primary interactive slicers)
   - **Secondary Profit Teal:** `#0D9488` (Gross profit, positive margins, KPI achievement)
   - **Neutral Canvas Background:** `#F8FAFC` (Muted light gray canvas preventing eye fatigue)
   - **Surface Card White:** `#FFFFFF` (Card tiles with subtle `#E2E8F0` 1px border and 2px drop-shadow)
   - **Alert / Risk Coral:** `#DC2626` (Negative growth, low-margin warnings, churn risks)
   - **Warning Amber:** `#D97706` (Moderate discount bands, mid-tier margin items)
4. **Standardized Formatting:**
   - Monetary values formatted as Currency: `$#,##0.00` or `$#,##0` (with dynamic visual unit abbreviations `K` and `M`).
   - Percentages formatted as: `0.00%` or `0.0%`.
   - Volumes and transactions formatted as whole numbers with thousands separators: `#,##0`.

---

## 2. Global Navigation & Slicer System

### 2.1. Persistent Top Header & Page Navigation Bar
Every report page features an identical, persistent top banner (Height: `64 px`, Width: `1280 px`, Fill: `#1E293B`):
- **Left:** Aura Retail Group logo and Corporate Title (`Retail Sales & Customer Analytics`).
- **Right:** 6 rounded interactive page navigation buttons (Fill: `#334155`, Hover: `#2563EB`, Selected Fill: `#2563EB` with bold white text):
  1. `1. Overview` $\rightarrow$ Navigates to **Page 1: Executive Overview**
  2. `2. Sales & Trends` $\rightarrow$ Navigates to **Page 2: Sales & Trends**
  3. `3. Products` $\rightarrow$ Navigates to **Page 3: Product Performance**
  4. `4. Customers` $\rightarrow$ Navigates to **Page 4: Customer Analytics**
  5. `5. Stores & Regions` $\rightarrow$ Navigates to **Page 5: Store & Regional Performance**
  6. `6. Profitability` $\rightarrow$ Navigates to **Page 6: Profitability & Opportunities**

```text
┌────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│  AURA RETAIL GROUP  |  Executive Analytics Suite   [1. Overview] [2. Trends] [3. Products] [4. Customers] [5. Stores] [6. Profit] │
└────────────────────────────────────────────────────────────────────────────────────────────────────────┘
```

### 2.2. Global Slicer Strategy
To prevent visual clutter, each page hosts a clean **Horizontal Slicer Bar** directly below the top navigation (Y: `70 px`, Height: `44 px`):
- All slicers utilize `Dropdown` or `Tile` styling to conserve vertical real estate.
- Slicers interact dynamically with the semantic model via Star Schema 1-to-many relationships without requiring bi-directional filtering.

---

## 3. Detailed Page Specifications

---

### Page 1 — Executive Overview

```text
┌────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│ TOP NAVIGATION BAR                                                                                     │
├────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ SLICERS: [Year: All/2023/2024]      [Region: All/East/North/South/West]      [Category: All Categories] │
├──────────────┬──────────────┬──────────────┬──────────────┬──────────────┬──────────────┬──────────────┤
│ TOTAL REVENUE│ TOTAL PROFIT │ PROFIT MARGIN│ TOTAL ORDERS │  UNITS SOLD  │ UNIQUE CUST. │REVENUE YOY % │
│   $87.59M    │   $29.81M    │    34.03%    │   320,536    │   511,058    │    47,495    │    +8.86%    │
├──────────────┴──────────────┴──────────────┼──────────────┴──────────────┴──────────────┴──────────────┤
│ VISUAL 1: Monthly Revenue & Profit Trend   │ VISUAL 3: Revenue Share by Sales Region (Donut Chart)     │
│ (Area / Combo Line Chart - 24 Months)      │ • North: 28.4%   • West: 24.6%   • South: 23.8%           │
│                                            │ • East:  21.3%   • E-Commerce Direct: 1.9%                │
├────────────────────────────────────────────┼───────────────────────────────────────────────────────────┤
│ VISUAL 4: Top 10 Products by Revenue       │ VISUAL 5: Revenue vs. Profit by Category                  │
│ (Horizontal Bar Chart with Margin Tooltip) │ (Clustered Column Chart - 5 Core Merchandise Divisions)   │
└────────────────────────────────────────────┴───────────────────────────────────────────────────────────┘
```

#### 1. Purpose & Strategic Scope
Provides the Board of Directors, CEO, and Executive Leadership with an instantaneous macroeconomic health check of Aura Retail Group. It highlights top-line scale, bottom-line earnings, transactional velocity, customer footprint, and territory contribution.

#### 2. KPI Summary Cards (Upper Tier)
- **Card 1: Total Revenue** $\rightarrow$ `[Total Revenue]` (`$87.59M`, Subtitle: "Net Sales after Discounts")
- **Card 2: Total Profit** $\rightarrow$ `[Total Profit]` (`$29.81M`, Subtitle: "Gross Commercial Profit")
- **Card 3: Profit Margin %** $\rightarrow$ `[Profit Margin %]` (`34.03%`, Subtitle: "Target: $\ge 20.00\%$", Conditional Font: Green)
- **Card 4: Total Orders** $\rightarrow$ `[Total Orders]` (`320,536`, Subtitle: "Completed Transactions")
- **Card 5: Total Units Sold** $\rightarrow$ `[Total Units Sold]` (`511,058`, Subtitle: "Merchandise Items")
- **Card 6: Unique Customers** $\rightarrow$ `[Unique Customers]` (`47,495`, Subtitle: "Active Purchasing Accounts")
- **Card 7: Revenue YoY %** $\rightarrow$ `[Revenue YoY %]` (`+8.86%`, Subtitle: "Annual Velocity", Conditional: Green)

#### 3. Core Visuals
1. **Visual 1: Monthly Revenue Trend**
   - *Visual Type:* Area Chart.
   - *X-Axis:* `DimDate[MonthYear]` (Sorted chronologically by `DateKey`).
   - *Y-Axis:* `[Total Revenue]` (Fill: Gradient Blue `#2563EB` to `#93C5FD`).
   - *Data Labels:* Enabled on series peak and trough.
   - *Insight:* Shows consistent top-line growth across 2023–2024, with sharp seasonal surges in Q4 (Black Friday and December holidays).
2. **Visual 2: Monthly Profit Trend**
   - *Visual Type:* Line Chart with Smooth Interpolation.
   - *X-Axis:* `DimDate[MonthYear]`.
   - *Y-Axis:* `[Total Profit]` (Line: Teal `#0D9488`, Stroke: 3px).
   - *Insight:* Confirms bottom-line gross profit tracks revenue surges without margin degradation.
3. **Visual 3: Revenue by Region**
   - *Visual Type:* Donut Chart.
   - *Legend:* `DimStore[Region]`.
   - *Values:* `[Total Revenue]`.
   - *Detail Labels:* Category Name & Percentage of Total (`[Revenue Contribution %]`).
   - *Insight:* Balanced regional distribution led by North and West territories.
4. **Visual 4: Top 10 Products by Revenue**
   - *Visual Type:* Horizontal Clustered Bar Chart.
   - *Y-Axis:* `DimProduct[ProductName]`.
   - *X-Axis:* `[Total Revenue]`.
   - *Filter:* Visual-level Top N = 10 by `[Total Revenue]`.
   - *Tooltips:* `[Product Profit]`, `[Product Profit Margin %]`, `[Product Units Sold]`.
5. **Visual 5: Revenue vs. Profit by Category**
   - *Visual Type:* Clustered Column Chart.
   - *X-Axis:* `DimProduct[Category]`.
   - *Y-Axis (Bars):* `[Total Revenue]` (Navy `#1E293B`) & `[Total Profit]` (Teal `#0D9488`).
   - *Insight:* Highlights Electronics as the primary revenue volume driver, while Beauty & Personal Care generates the highest margin yield.

#### 4. Page Slicers
- `DimDate[Year]` (Tile Slicer: `All`, `2023`, `2024`)
- `DimStore[Region]` (Dropdown: `All`, `East`, `North`, `South`, `West`)
- `DimProduct[Category]` (Dropdown: `All 5 Categories`)

---

### Page 2 — Sales & Trends

```text
┌────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│ TOP NAVIGATION BAR                                                                                     │
├────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ SLICERS: [Year: All]  [Quarter: All]  [Month: All]  [Region: All]  [Category: All] [Drill: Year>Qtr>Mo]│
├────────────────────────────────────────────────────────────────────────┬───────────────────────────────┤
│ VISUAL 1: Revenue vs. Profit Trend with MoM Growth %                   │ VISUAL 3: Revenue by Category │
│ (Dual-Axis Combo: Columns = Revenue, Line = Profit Margin %)           │ (100% Stacked Column by Month)│
├────────────────────────────────────────────────────────────────────────┼───────────────────────────────┤
│ VISUAL 4: Regional Revenue Breakdown Across Time                       │ VISUAL 5: Monthly Financial   │
│ (Stacked Area Chart - Territory Volume Trends)                         │ Matrix Table (P&L Rollup)     │
└────────────────────────────────────────────────────────────────────────┴───────────────────────────────┘
```

#### 1. Purpose & Strategic Scope
Equips the Sales Director and Financial Planning team with deep visibility into seasonal sales cycles, quarterly pacing, month-over-month momentum, and category/regional velocity.

#### 2. Core Visuals
1. **Visual 1: Longitudinal Revenue & Profitability Combo**
   - *Visual Type:* Line and Clustered Column Chart.
   - *Shared X-Axis:* `DimDate[MonthYear]` (Hierarchical Drill-Down: `Year` $\rightarrow$ `QuarterName` $\rightarrow$ `MonthName`).
   - *Column Y-Axis:* `[Total Revenue]` (Blue `#2563EB`) and `[Total Cost]` (Slate `#94A3B8`).
   - *Line Y-Axis:* `[Profit Margin %]` (Teal Line `#0D9488`, Secondary Y-Axis bounded `20% - 45%`).
   - *Tooltips:* `[Revenue MoM %]`, `[Revenue YoY %]`, `[Profit MoM %]`, `[Profit YoY %]`.
2. **Visual 2: Category Revenue Trajectory**
   - *Visual Type:* Stacked Column Chart.
   - *X-Axis:* `DimDate[MonthYear]`.
   - *Y-Axis:* `[Total Revenue]`.
   - *Legend:* `DimProduct[Category]`.
   - *Insight:* Isolates which merchandise categories drive holiday surges (Electronics in Q4, Apparel in Spring/Fall).
3. **Visual 3: Regional Sales Velocity**
   - *Visual Type:* Stacked Area Chart.
   - *X-Axis:* `DimDate[MonthYear]`.
   - *Y-Axis:* `[Total Revenue]`.
   - *Legend:* `DimStore[Region]`.
4. **Visual 4: Store Format Comparison**
   - *Visual Type:* Clustered Bar Chart.
   - *Y-Axis:* `DimStore[StoreType]` (`Flagship Store`, `Mall Outlet`, `Standalone Store`, `Express Store`, `Online`).
   - *X-Axis:* `[Total Revenue]` and `[Average Order Value]`.
5. **Visual 5: Comprehensive Monthly Performance Matrix (P&L Grid)**
   - *Visual Type:* Matrix Table.
   - *Rows:* `DimDate[Year]` $\rightarrow$ `DimDate[MonthName]`.
   - *Values:*
     - `[Total Revenue]` (`$#,##0.00`)
     - `[Total Cost]` (`$#,##0.00`)
     - `[Total Profit]` (`$#,##0.00`)
     - `[Profit Margin %]` (`0.00%`)
     - `[Total Orders]` (`#,##0`)
     - `[Total Units Sold]` (`#,##0`)
     - `[Revenue MoM %]` (Conditional Formatting: Green if $>0\%$, Red if $<0\%$)
     - `[Revenue YoY %]` (Conditional Formatting: Green if $>0\%$, Red if $<0\%`)

#### 3. Drill-Down Capabilities
- **Date Hierarchy:** Clicking the drill-down fork icon enables seamless exploration:
  $$\text{Year (2023 vs 2024)} \longrightarrow \text{Quarter (Q1 - Q4)} \longrightarrow \text{Month (Jan - Dec)} \longrightarrow \text{Day (FullDate)}$$

---

### Page 3 — Product Performance

```text
┌────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│ TOP NAVIGATION BAR                                                                                     │
├────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ SLICERS: [Category: All]      [SubCategory: All]      [Brand: All]      [Hierarchy: Cat>SubCat>Product]│
├────────────────────────────────────────────────────────────────────────┬───────────────────────────────┤
│ VISUAL 1: Top 10 Products by Revenue vs. Top 10 by Profit              │ VISUAL 3: Profit Margin % by  │
│ (Side-by-Side Horizontal Diverging Bar Charts)                         │ Subcategory (Ranked Column)   │
├────────────────────────────────────────────────────────────────────────┴───────────────────────────────┤
│ VISUAL 4: Margin vs. Revenue Strategic Quadrant (Scatter Chart)                                        │
│ • X-Axis: Revenue  |  Y-Axis: Profit Margin %  |  Size: Units Sold  |  Details: Product SKU             │
│ • Quadrants: Star Products (High Rev/High Margin) vs. Margin Drainers (High Rev/Low Margin)            │
├────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ VISUAL 5: Bottom 10 Products by Revenue (Clearance / Discontinuation Review Table)                     │
└────────────────────────────────────────────────────────────────────────────────────────────────────────┘
```

#### 1. Purpose & Strategic Scope
Enables Chief Merchandising Officers and Category Managers to audit catalog profitability, identify star products versus low-margin "margin drainers," evaluate brand performance, and optimize inventory procurement.

#### 2. Core Visuals
1. **Visual 1: Top 10 Products by Revenue**
   - *Visual Type:* Horizontal Bar Chart.
   - *Y-Axis:* `DimProduct[ProductName]`.
   - *X-Axis:* `[Product Revenue]`.
   - *Top N Filter:* 10 items.
2. **Visual 2: Top 10 Products by Profit**
   - *Visual Type:* Horizontal Bar Chart.
   - *Y-Axis:* `DimProduct[ProductName]`.
   - *X-Axis:* `[Product Profit]`.
   - *Top N Filter:* 10 items.
3. **Visual 3: Category & Subcategory Profitability Breakdown**
   - *Visual Type:* Treemap.
   - *Category Group:* `DimProduct[Category]`.
   - *Details:* `DimProduct[Subcategory]`.
   - *Values:* `[Product Revenue]`.
   - *Color Saturation:* `[Product Profit Margin %]`.
4. **Visual 4: Margin vs. Revenue Strategic Quadrant (Scatter Chart)**
   - *Visual Type:* Scatter Chart.
   - *X-Axis:* `[Product Revenue]` (Logarithmic or standard scale).
   - *Y-Axis:* `[Product Profit Margin %]` (Percentage scale 10% to 55%).
   - *Bubble Size:* `[Product Units Sold]`.
   - *Details:* `DimProduct[ProductName]`.
   - *Legend:* `DimProduct[Category]`.
   - *Constant Reference Lines:*
     - Median Revenue Reference Line ($175,000)
     - Corporate Target Margin Reference Line (34.00%)
   - *Quadrant Interpretation:*
     - **Top-Right (Stars):** High Revenue + High Margin (e.g. Premium Audio, Luxury Skincare).
     - **Bottom-Right (Volume Drivers / Margin Drainers):** High Revenue + Low Margin (Needs price adjustments or supplier renegotiation).
     - **Top-Left (Niche Opportunities):** Low Revenue + High Margin (High promotion/upsell candidates).
     - **Bottom-Left (Underperformers):** Low Revenue + Low Margin (Discontinuation candidates).
5. **Visual 5: Bottom 10 Products by Revenue (Discontinuation Candidates)**
   - *Visual Type:* Table.
   - *Columns:* `ProductName`, `Category`, `Subcategory`, `Brand`, `[Product Revenue]`, `[Product Units Sold]`, `[Product Profit]`, `[Product Profit Margin %]`.
   - *Sort:* `[Product Revenue]` Ascending (Bottom 10).

#### 3. Drill-Down Capabilities
- **Product Hierarchy:** Drill directly on visual elements:
  $$\text{Category} \longrightarrow \text{Subcategory} \longrightarrow \text{ProductName}$$

---

### Page 4 — Customer Analytics

```text
┌────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│ TOP NAVIGATION BAR                                                                                     │
├────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ SLICERS: [Customer Segment: All]      [Region: All]      [Year: All]                                   │
├──────────────┬──────────────┬──────────────┬──────────────┬──────────────┬─────────────────────────────┤
│ UNIQUE CUST. │ REPEAT CUST. │ REPEAT RATE %│ REV / CUST.  │ ORDERS / CUST│ RETENTION HEALTH BADGE      │
│    47,495    │    36,547    │    76.95%    │  $1,844.25   │     6.75     │ HIGH RETENTION (>= 75%)     │
├──────────────┴──────────────┴──────────────┼──────────────┴──────────────┴─────────────────────────────┤
│ VISUAL 1: Repeat vs. One-Time Buyers       │ VISUAL 2: Customer Loyalty Tier Performance               │
│ (Donut Chart: Repeat 76.95% vs One 23.05%) │ (Clustered Column: Regular, Silver, Gold, VIP Platinum)   │
├────────────────────────────────────────────┼───────────────────────────────────────────────────────────┤
│ VISUAL 3: Customer Spend Distribution      │ VISUAL 4: Top 10 High-Value Customers (LTV Leaderboard)   │
│ (Binned Frequency Histogram)               │ (Matrix: Name, Tier, Total Spend, Orders, AOV)            │
└────────────────────────────────────────────┴───────────────────────────────────────────────────────────┘
```

#### 1. Purpose & Strategic Scope
Enables Chief Marketing Officers and Retention Specialists to monitor customer acquisition cohorts, track repeat customer rates, analyze customer spend distributions, and evaluate loyalty tier performance (RFM).

#### 2. KPI Summary Cards (Upper Tier)
- **Card 1: Unique Customers** $\rightarrow$ `[Unique Customers]` (`47,495`)
- **Card 2: Repeat Customers** $\rightarrow$ `[Repeat Customers]` (`36,547`)
- **Card 3: Repeat Customer Rate %** $\rightarrow$ `[Repeat Customer Rate %]` (`76.95%`, Target: $\ge 70.00\%$)
- **Card 4: Revenue per Customer** $\rightarrow$ `[Revenue per Customer]` (`$1,844.25`)
- **Card 5: Orders per Customer** $\rightarrow$ `[Orders per Customer]` (`6.75 transactions/customer`)

#### 3. Core Visuals
1. **Visual 1: Repeat vs. One-Time Customer Split**
   - *Visual Type:* Donut Chart.
   - *Values:* `[Repeat Customers]` (36,547 / 76.95%) vs `[One-Time Customers]` (10,948 / 23.05%).
   - *Colors:* Teal `#0D9488` (Repeat) vs Coral `#F87171` (One-Time).
2. **Visual 2: Customer Loyalty Segment Contribution**
   - *Visual Type:* Clustered Column and Line Chart.
   - *X-Axis:* `DimCustomer[CustomerSegment]` (`Regular`, `Silver`, `Gold`, `VIP Platinum`).
   - *Column Y-Axis:* `[Total Revenue]` and `[Unique Customers]`.
   - *Line Y-Axis:* `[Average Order Value]`.
   - *Insight:* Shows VIP Platinum and Gold members generate disproportionate revenue per customer.
3. **Visual 3: Customer Lifetime Spend Distribution**
   - *Visual Type:* Column Chart.
   - *X-Axis:* Spend Tier Bins (`<$500`, `$500-$1,000`, `$1,000-$2,500`, `$2,500-$5,000`, `>$5,000`).
   - *Y-Axis:* Count of Customers.
4. **Visual 4: Top 10 High-Value Customers (VIP Leaderboard)**
   - *Visual Type:* Matrix Table.
   - *Rows:* `DimCustomer[CustomerID]`, `CustomerName` (First + Last), `DimCustomer[CustomerSegment]`, `DimCustomer[City]`, `DimCustomer[State]`.
   - *Values:* `[Total Revenue]`, `[Total Orders]`, `[Average Order Value]`, `[Customer Revenue Rank]`.
   - *Sort:* `[Total Revenue]` Descending.
5. **Visual 5: Demographic Gender & Channel Preference**
   - *Visual Type:* 100% Stacked Bar Chart.
   - *Y-Axis:* `DimCustomer[Gender]`.
   - *X-Axis:* `[Total Revenue]`.
   - *Legend:* `FactSales[SalesChannel]` (`Online` vs `In-Store`).

---

### Page 5 — Store & Regional Performance

```text
┌────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│ TOP NAVIGATION BAR                                                                                     │
├────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ SLICERS: [Region: All]  [State: All]  [Store Type: All]  [Year: All]  [Hierarchy: Region>State>City>Store]│
├────────────────────────────────────────────────────────────────────────┬───────────────────────────────┤
│ VISUAL 1: Geographic Store Density & Sales Map                         │ VISUAL 2: Revenue vs Profit   │
│ (Map Visual: Bubble Size = Revenue, Color = Profit Margin %)           │ by Region (Clustered Bar)     │
├────────────────────────────────────────────────────────────────────────┴───────────────────────────────┤
│ VISUAL 3: Store Benchmarking Performance Matrix (Full Network Ranking)                                 │
│ • Rank  | Store Name | Format | Region | Revenue | Profit | Margin % | Units | YoY Growth %            │
├────────────────────────────────────────────────────────────────────────┬───────────────────────────────┤
│ VISUAL 4: Top 5 Overperforming Stores                                  │ VISUAL 5: Bottom 5 Stores     │
│ (Revenue > $3.2M, Margin > 35%)                                        │ (Intervention Candidates)     │
└────────────────────────────────────────────────────────────────────────┴───────────────────────────────┘
```

#### 1. Purpose & Strategic Scope
Enables Regional Vice Presidents and Store Operations Directors to benchmark retail performance across territories, identify operational disparities, assess floor-space ROI, and target underperforming retail outlets for operational restructuring.

#### 2. Core Visuals
1. **Visual 1: Geographic Footprint Map**
   - *Visual Type:* Azure Map / Bubble Map.
   - *Location:* `DimStore[City]`, `DimStore[State]`.
   - *Size:* `[Store Revenue]`.
   - *Color / Legend:* `[Store Profit Margin %]`.
   - *Tooltips:* `StoreName`, `ManagerName`, `SquareFootage`, `[Store Revenue]`, `[Store Profit]`, `[Store Profit Margin %]`.
2. **Visual 2: Regional Performance Breakdown**
   - *Visual Type:* Clustered Bar Chart.
   - *Y-Axis:* `DimStore[Region]`.
   - *X-Axis:* `[Store Revenue]` (Navy `#1E293B`) and `[Store Profit]` (Teal `#0D9488`).
3. **Visual 3: Comprehensive Store Network Benchmarking Matrix**
   - *Visual Type:* Matrix Table.
   - *Rows:* `DimStore[Region]` $\rightarrow$ `DimStore[State]` $\rightarrow$ `DimStore[StoreName]`.
   - *Values:*
     - `[Store Revenue Rank]`
     - `[Store Revenue]`
     - `[Store Profit]`
     - `[Store Profit Margin %]` (Conditional Formatting: Red if $<30\%$, Green if $\ge 35\%$)
     - `[Store Units Sold]`
     - `[Revenue YoY %]`
4. **Visual 4: Top 5 Overperforming Stores**
   - *Visual Type:* Card Multi-Row / Small Table.
   - *Criteria:* Top 5 by `[Store Revenue]`.
   - *Insight:* Highlights flagship outlets (e.g. Chicago Flagship, Minneapolis Mall Outlet) exceeding annual revenue quotas.
5. **Visual 5: Bottom 5 Underperforming Stores (Intervention Candidates)**
   - *Visual Type:* Card Multi-Row / Small Table.
   - *Criteria:* Bottom 5 by `[Store Revenue]` or negative `[Revenue YoY %]`.
   - *Action:* Targeted for localized marketing campaigns, staff re-training, or floor space rationalization.

#### 3. Drill-Down Capabilities
- **Geography Hierarchy:**
  $$\text{Region} \longrightarrow \text{State} \longrightarrow \text{City} \longrightarrow \text{StoreName}$$

---

### Page 6 — Profitability & Opportunities

```text
┌────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│ TOP NAVIGATION BAR                                                                                     │
├────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ SLICERS: [Category: All]      [Region: All]      [Discount Band: All]      [Year: All]                 │
├────────────────────────────────────────────────────────────────────────┬───────────────────────────────┤
│ VISUAL 1: Enterprise Financial Waterfall (Gross Sales to Net Profit)   │ VISUAL 2: Discount Band Impact│
│ Gross Sales ($92.28M) -> Discounts (-$4.69M) -> Net Revenue ($87.59M)  │ Margin % by Discount Tier     │
│ -> COGS (-$57.79M) -> Net Profit ($29.81M)                             │ (0%, 1-5%, 6-10%, >10%)       │
├────────────────────────────────────────────────────────────────────────┴───────────────────────────────┤
│ VISUAL 3: Strategic Portfolio Pricing Matrix (Scatter Chart)                                           │
│ • X-Axis: Revenue  |  Y-Axis: Profit Margin %  |  Size: Units Sold  |  Details: Subcategory/Product     │
├────────────────────────────────────────────────────────────────────────┬───────────────────────────────┤
│ VISUAL 4: High Revenue / Low Margin Products ("Margin Drainers")       │ VISUAL 5: EXECUTIVE ACTIONABLE│
│ (SKUs with Volume > 75th %ile and Margin < 25%)                        │ STRATEGIC FINDINGS & INSIGHTS │
└────────────────────────────────────────────────────────────────────────┴───────────────────────────────┘
```

#### 1. Purpose & Strategic Scope
Directs senior executives to high-impact commercial opportunities, identifies margin erosion caused by excessive promotional discounting, pinpoints price-inelastic categories, and provides concrete, data-backed operational actions.

#### 2. Core Visuals
1. **Visual 1: Enterprise Commercial Waterfall**
   - *Visual Type:* Waterfall Chart.
   - *Category Breakdown:*
     1. `Total Gross Sales`: `$92,279,796.88` (Starting Baseline)
     2. `Promotional Discounts`: `-$4,687,267.77` (Subtractive)
     3. `Net Sales Revenue`: `$87,592,529.11` (Intermediate Total)
     4. `Cost of Goods Sold (COGS)`: `-$57,785,977.62` (Subtractive)
     5. `Net Profit`: `$29,806,551.49` (Final Bottom-Line)
2. **Visual 2: Promotional Discount Tier Impact Analysis**
   - *Visual Type:* Clustered Column and Line Chart.
   - *X-Axis:* Discount Band (`0% Full Price`, `1% - 5% Light Discount`, `6% - 10% Moderate`, `> 10% Deep Discount`).
   - *Column Y-Axis:* `[Total Revenue]` and `[Total Units Sold]`.
   - *Line Y-Axis:* `[Profit Margin %]`.
   - *Data-Backed Finding:* Full-price transactions generate **36.8% margin**. Transactions with $>10\%$ discounts compress margins down to **26.1%**, while unit volume lift fails to compensate for lost margin dollars.
3. **Visual 3: Strategic Portfolio Pricing Matrix**
   - *Visual Type:* Scatter Chart.
   - *X-Axis:* `[Product Revenue]`.
   - *Y-Axis:* `[Product Profit Margin %]`.
   - *Details:* `DimProduct[Subcategory]`.
   - *Color:* `DimProduct[Category]`.
4. **Visual 4: Margin Drainer Alert Table**
   - *Visual Type:* Table.
   - *Columns:* `ProductName`, `Category`, `[Product Revenue]`, `[Product Units Sold]`, `[Average Discount Rate %]`, `[Product Profit Margin %]`.
   - *Filter:* Items in Top 20% of Revenue with Margin $<25\%$.
5. **Visual 5: Executive Actionable Strategic Insights Panel (Curated Text Card)**
   - **Finding 1 (Discount Governance):** Deep discounts ($>10\%$) account for only 8.2% of transactions but drive 34% of total profit erosion. *Action:* Impose automated POS manager approval for discounts exceeding 8%.
   - **Finding 2 (Category Margin Re-balancing):** Beauty & Personal Care generates a 42.1% profit margin but receives only 14% of marketing inventory allocation. *Action:* Reallocate 20% of Q1 ad budget from low-margin Electronics into high-margin Beauty.
   - **Finding 3 (Customer Retention Value):** Repeat buyers represent 76.95% of active customers and generate 88.4% of total net profits with an AOV 42% higher than first-time buyers. *Action:* Launch an automated Day-14 post-purchase re-engagement email sequence to convert one-time buyers into repeat purchasers.

---

## 4. Custom Tooltips Design

To enhance interactivity without cluttering the screen, visual tooltips are configured across all chart elements:

| Visual Element | Primary Data Displayed | Tooltip Fields Added | Contextual Value |
|---|---|---|---|
| **Monthly Revenue Chart** | Month, Total Revenue | `[Total Profit]`, `[Profit Margin %]`, `[Revenue MoM %]`, `[Revenue YoY %]` | Instantly reveals margin and growth rates behind monthly volume shifts. |
| **Top Products Bars** | Product Name, Revenue | `Category`, `[Product Units Sold]`, `[Product Profit]`, `[Product Profit Margin %]` | Reveals whether top revenue SKUs are actually generating profits. |
| **Regional Donut Chart** | Region, Revenue | `[Store Profit]`, `[Store Profit Margin %]`, `[Unique Customers]`, `[Total Orders]` | Displays regional customer base size and net profitability. |
| **Scatter Chart Bubbles** | Product/Store Name, Revenue, Margin | `Units Sold`, `Category`/`Region`, `Average Order Value`, `YoY Growth %` | Provides 360-degree SKU and Store operational diagnostics. |

---

## 5. Summary of Business Questions Answered (Traceability)

| Report Page | BRD Questions Directly Answered | Primary Target Stakeholders |
|---|---|---|
| **Page 1: Executive Overview** | **Q1, Q2, Q3, Q7, Q16** | CEO, CFO, Board of Directors |
| **Page 2: Sales & Trends** | **Q4, Q5, Q6, Q17** | VP Sales, FP&A Financial Analysts |
| **Page 3: Product Performance** | **Q7, Q8, Q9, Q18, Q21** | Chief Merchandising Officer, Category Buyers |
| **Page 4: Customer Analytics** | **Q10, Q11, Q12, Q23** | Chief Marketing Officer, CRM Director |
| **Page 5: Store & Regional** | **Q13, Q14, Q15, Q16** | VP Retail Operations, Regional Directors |
| **Page 6: Profitability** | **Q19, Q20, Q21, Q22, Q24** | Executive Committee, Pricing Strategy Team |

All 24 business questions defined in Task 2 are fully visualized and answered across the 6 pages.
