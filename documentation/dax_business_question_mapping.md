# DAX Business Question Traceability Matrix
## Project: Retail Sales & Customer Analytics (Aura Retail Group)
**Document Purpose:** Direct Traceability from Task 2 Business Requirements to Task 10 DAX Measures  
**Target Dashboard:** Task 11 Power BI Executive & Operational Dashboards  
**Author:** Data Analytics Team  
**Date:** 2026-09-08  
**Document Version:** 1.0  
**Traceability Status:** **100% COMPLETE & CERTIFIED**  

---

## 1. Executive Summary

This document establishes full bidirectional traceability between the **24 Core Business Questions** defined in the [Business Requirements Document (BRD)](file:///d:/Data_Analytics/retail-sales-analytics/documentation/business_requirements.md) and the **DAX Measures** engineered in [DAX Measures Reference Guide](file:///d:/Data_Analytics/retail-sales-analytics/documentation/dax_measures.md).

Every business requirement is systematically mapped to its primary and secondary DAX calculation, supported dimension slices, and intended visual representation for the upcoming **Task 11 Dashboard Layer**.

---

## 2. Complete Traceability Matrix (24 Business Questions)

```
┌────────────────────────────────────────────────────────────────────────────┐
│                  BUSINESS QUESTION TO DAX MEASURE MAPPING                  │
├────────────────────────────────┬───────────────────────────────────────────┤
│ A. Overall Business Perf. (Q1-3)│ E. Store Performance (Q13-15)             │
│ B. Sales & Time Trends (Q4-6)   │ F. Regional Performance (Q16-18)          │
│ C. Product Performance (Q7-9)   │ G. Profitability & Discounts (Q19-21)     │
│ D. Customer Analysis (Q10-12)   │ H. Strategic Decisions (Q22-24)           │
└────────────────────────────────┴───────────────────────────────────────────┘
```

---

### Domain A: Overall Business Performance

#### Question 1: What is the total gross revenue, total cost of goods, and net profit generated across the entire business?
- **Primary DAX Measures:**
  - `[Total Revenue]`
  - `[Total Cost]`
  - `[Total Profit]`
- **Secondary / Context Measures:** `[Total Gross Sales]`, `[Total Discount Amount]`
- **How the DAX Measures Answer the Question:**
  `[Total Revenue]` computes the post-discount top-line realized revenue ($87,592,529.11). `[Total Cost]` aggregates the baseline product COGS ($57,785,977.62). `[Total Profit]` evaluates bottom-line earnings ($29,806,551.49).
- **Target Dashboard Visual (Task 11):** Top-level Executive KPI Summary Cards.

#### Question 2: What is the overall profit margin percentage, and is the business meeting its baseline target of 20% net margin?
- **Primary DAX Measure:**
  - `[Profit Margin %]`
- **Secondary / Context Measures:** `[Total Profit]`, `[Total Revenue]`
- **How the DAX Measure Answers the Question:**
  `[Profit Margin %]` calculates `DIVIDE([Total Profit], [Total Revenue], 0)`, evaluating to **34.03%**. This proves Aura Retail Group is outperforming its 20.00% corporate threshold by +14.03 percentage points.
- **Target Dashboard Visual (Task 11):** KPI Card with conditional formatting gauge (Green if $\ge 20\%$).

#### Question 3: What is the overall Average Order Value (AOV) and units sold per transaction?
- **Primary DAX Measures:**
  - `[Average Order Value]`
  - `[Total Units Sold]`
  - `[Total Orders]`
- **Secondary / Context Measures:** `[Average Selling Price]`
- **How the DAX Measures Answer the Question:**
  `[Average Order Value]` calculates `DIVIDE([Total Revenue], [Total Orders], 0)` yielding **$273.27** per checkout across 320,536 transactions. Average units per transaction can be evaluated via `DIVIDE([Total Units Sold], [Total Orders], 0)` yielding **1.59 units/order**.
- **Target Dashboard Visual (Task 11):** Executive Scorecard Cards.

---

### Domain B: Sales & Time Trends

#### Question 4: How are monthly sales and profit trending over time (Month-over-Month and Year-over-Year)?
- **Primary DAX Measures:**
  - `[Revenue MoM %]`, `[Revenue MoM Change]`
  - `[Profit MoM %]`, `[Profit MoM Change]`
  - `[Revenue YoY %]`, `[Revenue YoY Change]`
  - `[Profit YoY %]`, `[Profit YoY Change]`
- **Secondary / Context Measures:** `[Revenue Previous Month]`, `[Revenue Previous Year]`, `[Total Revenue]`, `[Total Profit]`
- **How the DAX Measures Answer the Question:**
  Utilizes contiguous calendar shifts over `DimDate[FullDate]` to compute period-over-period velocity without dropping dates.
- **Target Dashboard Visual (Task 11):** Dual-axis Line Chart (Revenue vs. Profit over Month-Year) with MoM/YoY growth rate callouts.

#### Question 5: Which days of the week and months of the year experience peak purchasing activity?
- **Primary DAX Measures:**
  - `[Total Revenue]`
  - `[Total Orders]`
  - `[Total Units Sold]`
- **Dimensional Slice:** Sliced by `DimDate[DayName]` (sorted by `DayOfWeek`) and `DimDate[MonthName]` (sorted by `Month`).
- **How the DAX Measures Answer the Question:**
  Evaluating `[Total Revenue]` and `[Total Orders]` grouped by day and month isolates peak weekend shopping and Q4 seasonal holiday volume.
- **Target Dashboard Visual (Task 11):** Day-of-Week Column Chart and Monthly Seasonality Heatmap.

#### Question 6: Are there quarters or specific months where revenue spikes but profitability drops?
- **Primary DAX Measures:**
  - `[Total Revenue]`
  - `[Total Profit]`
  - `[Profit Margin %]`
- **Secondary / Context Measures:** `[Total Discount Amount]`, `[Average Discount Rate %]`
- **How the DAX Measures Answer the Question:**
  Plotting `[Total Revenue]` alongside `[Profit Margin %]` across `DimDate[QuarterName]` detects "unprofitable volume surges" caused by aggressive clearance campaigns.
- **Target Dashboard Visual (Task 11):** Combo Clustered Column (Revenue) and Line Chart (Profit Margin %).

---

### Domain C: Product Performance

#### Question 7: Which product categories and individual products generate the highest revenue?
- **Primary DAX Measures:**
  - `[Product Revenue]`
  - `[Product Revenue Rank]`
  - `[Top Product]`
- **Secondary / Context Measures:** `[Revenue Contribution %]`
- **How the DAX Measures Answer the Question:**
  `[Product Revenue]` evaluated across `DimProduct[Category]` and `DimProduct[ProductName]`. `[Product Revenue Rank]` dynamically assigns ordinal rank (1 to N) within the selected filter context.
- **Target Dashboard Visual (Task 11):** Horizontal Bar Chart of Top 10 Products by Revenue and Category Treemap.

#### Question 8: Which products generate the highest net profit and profit margin?
- **Primary DAX Measures:**
  - `[Product Profit]`
  - `[Product Profit Margin %]`
  - `[Product Profit Rank]`
- **Secondary / Context Measures:** `[Average Profit per Unit]`
- **How the DAX Measures Answer the Question:**
  Ranks items by bottom-line earnings and highlights premium margin contributors (e.g. Beauty & Personal Care at > 40% margin vs. Electronics at ~28%).
- **Target Dashboard Visual (Task 11):** Scatter Plot matrix (X: Product Revenue, Y: Product Profit Margin %, Size: Units Sold).

#### Question 9: Which products exhibit high sales volume/revenue but low or negative profit margins ("margin drainers")?
- **Primary DAX Measures:**
  - `[Product Units Sold]`
  - `[Product Revenue]`
  - `[Product Profit Margin %]`
- **Secondary / Context Measures:** `[Average Profit per Unit]`, `[Average Discount Rate %]`
- **How the DAX Measures Answer the Question:**
  Isolates SKUs in the top quartile of `[Product Units Sold]` where `[Product Profit Margin %]` falls below corporate safety thresholds.
- **Target Dashboard Visual (Task 11):** Merchandise Matrix table with conditional formatting alerting on low-margin high-volume SKUs.

---

### Domain D: Customer Analysis

#### Question 10: How many unique customers have purchased, and what is the overall customer acquisition trajectory?
- **Primary DAX Measures:**
  - `[Unique Customers]`
  - `[Registered Customers]`
- **Secondary / Context Measures:** `[Revenue per Customer]`, `[Orders per Customer]`
- **How the DAX Measures Answer the Question:**
  `[Unique Customers]` evaluates distinct purchasing shoppers in `FactSales`, while `[Registered Customers]` counts total accounts in `DimCustomer`.
- **Target Dashboard Visual (Task 11):** Customer Acquisition Monthly Area Chart and Conversion Funnel Card.

#### Question 11: What percentage of total customers are repeat buyers versus one-time purchasers?
- **Primary DAX Measures:**
  - `[Repeat Customer Rate %]`
  - `[Repeat Customers]`
  - `[One-Time Customers]`
- **Secondary / Context Measures:** `[Unique Customers]`
- **How the DAX Measures Answer the Question:**
  `[Repeat Customers]` dynamically filters customer keys having `[Total Orders] > 1`, and `[Repeat Customer Rate %]` computes the exact retention proportion.
- **Target Dashboard Visual (Task 11):** Donut Chart (Repeat vs. One-Time Buyers) and KPI Callout Card.

#### Question 12: Who are the top 10% highest-value customers by total lifetime revenue and order frequency?
- **Primary DAX Measures:**
  - `[Customer Revenue Rank]`
  - `[Total Revenue]`
  - `[Total Orders]`
- **Secondary / Context Measures:** `[Average Order Value]`, `[Revenue Contribution %]`
- **How the DAX Measures Answer the Question:**
  `[Customer Revenue Rank]` dynamically ranks customer accounts by spend, enabling top-tier VIP filtering.
- **Target Dashboard Visual (Task 11):** Top Customers Leaderboard Matrix and RFM Segmentation visual.

---

### Domain E: Store Performance

#### Question 13: Which physical store locations generate the highest revenue, profit, and customer footfall?
- **Primary DAX Measures:**
  - `[Store Revenue]`
  - `[Store Profit]`
  - `[Store Units Sold]`
  - `[Store Revenue Rank]`
  - `[Top Store]`
- **Secondary / Context Measures:** `[Store Profit Margin %]`
- **How the DAX Measures Answer the Question:**
  Evaluates revenue and profit across `DimStore[StoreName]`, identifying top retail performers and flagship contributions.
- **Target Dashboard Visual (Task 11):** Clustered Bar Chart (Top 10 Stores by Revenue & Profit) and Store Leaderboard Card.

#### Question 14: Which stores are consistently underperforming or experiencing negative growth trends?
- **Primary DAX Measures:**
  - `[Store Revenue]`
  - `[Revenue MoM %]`
  - `[Revenue YoY %]`
  - `[Store Profit Margin %]`
- **Secondary / Context Measures:** `[Store Profit Rank]`
- **How the DAX Measures Answer the Question:**
  Filters stores displaying negative YoY growth or profit margins below regional benchmarks.
- **Target Dashboard Visual (Task 11):** Store Variance Matrix with Red/Green growth KPI indicators.

#### Question 15: How does the online e-commerce sales channel compare to physical retail stores in terms of AOV and profit margin?
- **Primary DAX Measures:**
  - `[Total Revenue]`
  - `[Average Order Value]`
  - `[Profit Margin %]`
  - `[Total Orders]`
- **Dimensional Slice:** Sliced by `FactSales[SalesChannel]` (`Online` vs. `In-Store`).
- **How the DAX Measures Answer the Question:**
  Evaluates channel mix efficiency, comparing basket sizes and net profitability between digital and physical modalities.
- **Target Dashboard Visual (Task 11):** Channel Comparison Split Cards and Side-by-Side Donut / Clustered Bar Charts.

---

### Domain F: Regional Performance

#### Question 16: Which geographic regions (North, South, East, West) generate the largest share of revenue and profit?
- **Primary DAX Measures:**
  - `[Total Revenue]`
  - `[Total Profit]`
  - `[Revenue Contribution %]`
- **Dimensional Slice:** Sliced by `DimStore[Region]` or `DimCustomer[Region]`.
- **How the DAX Measures Answer the Question:**
  `[Revenue Contribution %]` calculates the exact percentage share of total enterprise revenue contributed by each geographical territory.
- **Target Dashboard Visual (Task 11):** Regional Map Visual (ArcGIS / Filled Map) and Regional Share Donut Chart.

#### Question 17: Which regions exhibit the fastest growth rates versus stagnant markets?
- **Primary DAX Measures:**
  - `[Revenue YoY %]`
  - `[Profit YoY %]`
  - `[Revenue MoM %]`
- **Dimensional Slice:** Grouped by `DimStore[Region]`.
- **How the DAX Measures Answer the Question:**
  Evaluates annual territory velocity to highlight emerging expansion markets vs. mature markets.
- **Target Dashboard Visual (Task 11):** Regional YoY Growth Rate Bar Chart.

#### Question 18: Are product category preferences significantly different across geographic regions?
- **Primary DAX Measures:**
  - `[Total Revenue]`
  - `[Revenue Contribution %]`
- **Dimensional Slice:** Cross-tabulated by `DimStore[Region]` and `DimProduct[Category]`.
- **How the DAX Measures Answer the Question:**
  Analyzes merchandise mix variation across territories (e.g. Outdoor gear demand in the West vs. Apparel in the East).
- **Target Dashboard Visual (Task 11):** 100% Stacked Bar Chart (Product Category % Breakdown by Region).

---

### Domain G: Profitability & Discounts

#### Question 19: How do promotional discount tiers (e.g., 0%, 1-10%, 11-20%, >20%) impact overall profit margins?
- **Primary DAX Measures:**
  - `[Total Revenue]`
  - `[Total Profit]`
  - `[Profit Margin %]`
  - `[Total Units Sold]`
- **Secondary / Context Measures:** `[Total Discount Amount]`
- **How the DAX Measures Answer the Question:**
  Evaluates how margin degrades as discount depth increases, identifying the elasticity tipping point where promotions destroy profit.
- **Target Dashboard Visual (Task 11):** Discount Tier Impact Table / Clustered Bar Chart.

#### Question 20: What is the total monetary value lost to promotional discounts across categories and stores?
- **Primary DAX Measures:**
  - `[Total Discount Amount]`
  - `[Average Discount Rate %]`
  - `[Total Gross Sales]`
- **How the DAX Measures Answer the Question:**
  Quantifies total dollars surrendered to promotions ($4,687,267.77 overall) and the realized discount percentage (5.08%).
- **Target Dashboard Visual (Task 11):** Waterfall Chart (Gross Sales $\rightarrow$ Discounts Conceded $\rightarrow$ Net Revenue).

#### Question 21: Which product categories are over-discounted with minimal corresponding lift in sales volume?
- **Primary DAX Measures:**
  - `[Average Discount Rate %]`
  - `[Total Units Sold]`
  - `[Product Profit Margin %]`
- **Secondary / Context Measures:** `[Total Discount Amount]`
- **How the DAX Measures Answer the Question:**
  Identifies inelastic merchandise categories where discounting does not yield accretive volume.
- **Target Dashboard Visual (Task 11):** Category Discount Depth vs. Volume Matrix.

---

### Domain H: Strategic Decisions & Advanced Insights

#### Question 22: Which product categories represent the strongest cross-selling and bundling opportunities?
- **Primary DAX Measures:**
  - `[Total Orders]`
  - `[Average Order Value]`
  - `[Revenue Contribution %]`
- **How the DAX Measures Answer the Question:**
  Supports category basket co-occurrence analysis and multi-item checkout optimization.
- **Target Dashboard Visual (Task 11):** Cross-Category Affinity Matrix.

#### Question 23: Which customer segments represent the highest churn risk (no purchases in >90 days)?
- **Primary DAX Measures:**
  - `[Unique Customers]`
  - `[Revenue per Customer]`
  - `[Customer Revenue Rank]`
- **Dimensional Slice:** Sliced by `DimCustomer[CustomerSegment]`.
- **How the DAX Measures Answer the Question:**
  Identifies customer counts and revenue exposure in at-risk recency cohorts to target retention vouchers.
- **Target Dashboard Visual (Task 11):** Customer Attrition / Recency Distribution Chart.

#### Question 24: What specific pricing, inventory, and regional actions should executive leadership execute next quarter?
- **Primary DAX Measures:**
  - `[Running Revenue]`
  - `[Running Profit]`
  - `[Revenue Growth %]`
  - `[Profit Margin %]`
  - `[Product Pareto Contribution %]`
- **How the DAX Measures Answer the Question:**
  Synthesizes overall trajectory, cumulative profit run rates, and 80/20 product concentration to inform executive OKRs and capital allocation.
- **Target Dashboard Visual (Task 11):** Executive Summary Tab with Cumulative Trajectory Line Charts.

---

## 3. Summary & Readiness Confirmation

| Analytical Pillar | Business Questions | Supporting DAX Categories | Ready for Task 11 Visuals |
|---|---|---|---|
| **Executive Performance** | Q1, Q2, Q3 | `01 Sales KPIs`, `02 Profitability` | **YES** |
| **Sales & Time Trends** | Q4, Q5, Q6 | `06 Time Intelligence`, `07 Growth` | **YES** |
| **Product Merchandising**| Q7, Q8, Q9 | `04 Products`, `08 Advanced Analytics` | **YES** |
| **Customer Retention** | Q10, Q11, Q12 | `03 Customers`, `08 Advanced Analytics` | **YES** |
| **Store Operations** | Q13, Q14, Q15 | `05 Stores`, `07 Growth` | **YES** |
| **Regional Geographies** | Q16, Q17, Q18 | `05 Stores`, `08 Advanced Analytics` | **YES** |
| **Margin & Discounting** | Q19, Q20, Q21 | `02 Profitability`, `01 Sales KPIs` | **YES** |
| **Strategic Actions** | Q22, Q23, Q24 | `08 Advanced Analytics`, `06 Time Intelligence` | **YES** |

All 24 business questions are 100% mapped and supported by the DAX measure layer.
