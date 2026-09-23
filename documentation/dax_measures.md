# DAX Measures Reference Guide
## Project: Retail Sales & Customer Analytics (Aura Retail Group)
**Application:** Microsoft Power BI Desktop  
**Data Model Architecture:** Conformed Star Schema  
**Container Table:** `_Measures`  
**Author:** Data Analytics Team  
**Date:** 2026-09-08  
**Document Version:** 1.0  
**Layer Status:** **VERIFIED & CERTIFIED**  

---

## 1. Overview & Measure Governance

This document provides the definitive, production-grade DAX (Data Analysis Expressions) measure catalog for Aura Retail Group's Power BI reporting ecosystem.

### 1.1. Core Architectural Principles
1. **Measures Over Calculated Columns:** All business KPIs, ratios, and variances are engineered as explicit DAX measures rather than calculated columns. Measures consume zero in-memory tabular storage, calculate dynamically at query time, and dynamically respond to slicers, cross-filtering, and visual coordinates.
2. **Standardized Container Table (`_Measures`):** All 50+ DAX measures reside in a dedicated, disconnected container table named `_Measures`. The dummy placeholder column (`_DummyCol`) is hidden, elevating `_Measures` to the top of the Data pane with a distinct calculator icon.
3. **Hierarchical Category Folders:** Measures are systematically structured into **8 standardized display folders**:
   - `01 Sales KPIs`
   - `02 Profitability`
   - `03 Customers`
   - `04 Products`
   - `05 Stores`
   - `06 Time Intelligence`
   - `07 Growth`
   - `08 Advanced Analytics`
4. **Base Measure Reusability:** Complex measures build systematically upon core base measures (`[Total Revenue]`, `[Total Cost]`, `[Total Profit]`, `[Total Orders]`, `[Total Units Sold]`) rather than repeating raw tabular column aggregations.
5. **Defensive Mathematical Division:** All ratios and percentages strictly utilize `DIVIDE(Numerator, Denominator, [AlternateResult])` to guarantee defense against zero-division (`#DIV/0!`) and null references.

---

## 2. Comprehensive Measure Catalog by Category

---

### Category 01: Sales KPIs
**Display Folder:** `01 Sales KPIs`

#### 1. Total Revenue
```dax
Total Revenue = 
SUM(FactSales[SalesAmount])
```
- **Format:** Currency (`$#,##0.00`)
- **What it calculates:** Sum of net sales revenue (`SalesAmount`) across all filtered transactions after applied discounts.
- **Business purpose:** Establishes the foundational commercial top-line metric of the enterprise.
- **Important DAX concepts:** Native scalar column aggregation (`SUM`). Evaluates through active relationship filter context.

#### 2. Total Cost
```dax
Total Cost = 
SUM(FactSales[CostAmount])
```
- **Format:** Currency (`$#,##0.00`)
- **What it calculates:** Sum of total Cost of Goods Sold (`CostAmount = Quantity * UnitCost`).
- **Business purpose:** Quantifies total product procurement expense required to generate sales volume.
- **Important DAX concepts:** Native scalar column aggregation (`SUM`).

#### 3. Total Profit
```dax
Total Profit = 
SUM(FactSales[Profit])
```
- **Format:** Currency (`$#,##0.00`)
- **What it calculates:** Net gross commercial profit (`SalesAmount - CostAmount`).
- **Business purpose:** Quantifies bottom-line financial yield across all corporate channels and product categories.
- **Important DAX concepts:** Additive aggregation (`SUM`). Can also be expressed as `[Total Revenue] - [Total Cost]`.

#### 4. Total Orders
```dax
Total Orders = 
DISTINCTCOUNT(FactSales[SalesID])
```
- **Format:** Whole Number (`#,##0`)
- **What it calculates:** Count of unique completed sales transactions (`SalesID`).
- **Business purpose:** Measures customer checkout frequency and total transactional velocity.
- **Important DAX concepts:** `DISTINCTCOUNT` ensures exact transaction uniqueness. Since each row in `FactSales` represents a unique sale, it is equivalent in speed to `COUNTROWS(FactSales)`.

#### 5. Total Units Sold
```dax
Total Units Sold = 
SUM(FactSales[Quantity])
```
- **Format:** Whole Number (`#,##0`)
- **What it calculates:** Total physical item quantity purchased by customers.
- **Business purpose:** Monitors physical merchandise movement, distribution velocity, and inventory turnover.
- **Important DAX concepts:** Native scalar column aggregation (`SUM`).

#### 6. Unique Customers
```dax
Unique Customers = 
DISTINCTCOUNT(FactSales[CustomerID])
```
- **Format:** Whole Number (`#,##0`)
- **What it calculates:** Count of distinct customer IDs that completed at least one purchase within the current filter context.
- **Business purpose:** Evaluates the active purchasing customer base size.
- **Important DAX concepts:** `DISTINCTCOUNT` over foreign key column in the fact table.

#### 7. Average Order Value
```dax
Average Order Value = 
DIVIDE(
    [Total Revenue],
    [Total Orders],
    0
)
```
- **Format:** Currency (`$#,##0.00`)
- **What it calculates:** Net revenue generated per distinct sales transaction (`Total Revenue / Total Orders`).
- **Business purpose:** Core retail benchmark evaluating customer basket size and willingness to spend.
- **Important DAX concepts:** Reusable measure composition, safe division via `DIVIDE()`.

#### 8. Average Selling Price
```dax
Average Selling Price = 
DIVIDE(
    [Total Revenue],
    [Total Units Sold],
    0
)
```
- **Format:** Currency (`$#,##0.00`)
- **What it calculates:** Effective realized net price per unit sold across all products.
- **Business purpose:** Evaluates realized pricing power after discounts against list catalog prices.
- **Important DAX concepts:** Weighted average calculation via measure division.

#### 9. Revenue per Customer
```dax
Revenue per Customer = 
DIVIDE(
    [Total Revenue],
    [Unique Customers],
    0
)
```
- **Format:** Currency (`$#,##0.00`)
- **What it calculates:** Average monetary spend per unique purchasing customer.
- **Business purpose:** Measures average customer yield and customer monetary value across marketing segments.
- **Important DAX concepts:** Measure division using `[Total Revenue]` and `[Unique Customers]`.

---

### Category 02: Profitability
**Display Folder:** `02 Profitability`

#### 10. Profit Margin %
```dax
Profit Margin % = 
DIVIDE(
    [Total Profit],
    [Total Revenue],
    0
)
```
- **Format:** Percentage (`0.00%`)
- **What it calculates:** Share of net revenue converted into bottom-line profit (`Total Profit / Total Revenue`).
- **Business purpose:** Monitors commercial pricing health, operational efficiency, and margin targets (corporate baseline > 20%).
- **Important DAX concepts:** Calculated from aggregated measures. Avoids the catastrophic statistical distortion of taking an average of row-level margin percentages.

#### 11. Average Profit per Order
```dax
Average Profit per Order = 
DIVIDE(
    [Total Profit],
    [Total Orders],
    0
)
```
- **Format:** Currency (`$#,##0.00`)
- **What it calculates:** Net profit contributed per customer checkout transaction.
- **Business purpose:** Determines the commercial viability and contribution margin per customer interaction.
- **Important DAX concepts:** Measure ratio using `DIVIDE()`.

#### 12. Average Profit per Unit
```dax
Average Profit per Unit = 
DIVIDE(
    [Total Profit],
    [Total Units Sold],
    0
)
```
- **Format:** Currency (`$#,##0.00`)
- **What it calculates:** Net profit generated per individual item sold.
- **Business purpose:** Used by category managers to isolate high-unit-margin merchandise from low-margin commodity volume.
- **Important DAX concepts:** Measure ratio using `DIVIDE()`.

#### 13. Total Discount Amount
```dax
Total Discount Amount = 
SUM(FactSales[DiscountAmount])
```
- **Format:** Currency (`$#,##0.00`)
- **What it calculates:** Total dollar value given away in promotional price concessions.
- **Business purpose:** Evaluates margin erosion and total cost of promotional campaigns.
- **Important DAX concepts:** Additive aggregation (`SUM`).

#### 14. Total Gross Sales
```dax
Total Gross Sales = 
[Total Revenue] + [Total Discount Amount]
```
- **Format:** Currency (`$#,##0.00`)
- **What it calculates:** Theoretical top-line revenue before deductions of promotional discounts.
- **Business purpose:** Establishes pre-promotional retail volume baseline.
- **Important DAX concepts:** Measure addition.

#### 15. Average Discount Rate %
```dax
Average Discount Rate % = 
DIVIDE(
    [Total Discount Amount],
    [Total Gross Sales],
    0
)
```
- **Format:** Percentage (`0.00%`)
- **What it calculates:** Realized enterprise discount depth (`Total Discount Amount / Total Gross Sales`).
- **Business purpose:** Prevents margin compression by ensuring average discounts stay within corporate guidelines (< 6%).
- **Important DAX concepts:** Safe ratio computation via `DIVIDE()`.

---

### Category 03: Customers
**Display Folder:** `03 Customers`

#### 16. Registered Customers
```dax
Registered Customers = 
COUNTROWS(DimCustomer)
```
- **Format:** Whole Number (`#,##0`)
- **What it calculates:** Total registered accounts in the customer master database.
- **Business purpose:** Baseline population for customer penetration analysis.
- **Important DAX concepts:** Table row count (`COUNTROWS`).

#### 17. Repeat Customers
```dax
Repeat Customers = 
COUNTROWS(
    FILTER(
        VALUES(FactSales[CustomerID]),
        CALCULATE([Total Orders]) > 1
    )
)
```
- **Format:** Whole Number (`#,##0`)
- **What it calculates:** Total count of unique active customers who have completed strictly **more than one sales transaction** (`OrderCount > 1`).
- **Business purpose:** Identifies retained, loyal customers who generate sustained enterprise cash flow.
- **Important DAX concepts:** Iterative table filtering (`FILTER`), distinct key extraction (`VALUES`), and contextual measure evaluation (`CALCULATE`).

#### 18. One-Time Customers
```dax
One-Time Customers = 
COUNTROWS(
    FILTER(
        VALUES(FactSales[CustomerID]),
        CALCULATE([Total Orders]) = 1
    )
)
```
- **Format:** Whole Number (`#,##0`)
- **What it calculates:** Total count of unique active customers who have completed **exactly one transaction** (`OrderCount = 1`).
- **Business purpose:** Quantifies top-of-funnel acquisition cohorts that require targeted post-purchase re-engagement.
- **Important DAX concepts:** `FILTER` and `VALUES` with single-order condition.

#### 19. Repeat Customer Rate %
```dax
Repeat Customer Rate % = 
DIVIDE(
    [Repeat Customers],
    [Unique Customers],
    0
)
```
- **Format:** Percentage (`0.00%`)
- **What it calculates:** Proportion of active purchasing customers who have returned for subsequent orders (`Repeat Customers / Unique Customers`).
- **Business purpose:** Core benchmark of customer retention, product-market satisfaction, and loyalty health.
- **Important DAX concepts:** Measure-based ratio using `DIVIDE()`.

#### 20. Orders per Customer
```dax
Orders per Customer = 
DIVIDE(
    [Total Orders],
    [Unique Customers],
    0
)
```
- **Format:** Decimal (`0.00`)
- **What it calculates:** Average purchase frequency per active customer.
- **Business purpose:** Measures transaction velocity and purchase cadence across segments.
- **Important DAX concepts:** Safe division.

#### 21. Average Customer Revenue
```dax
Average Customer Revenue = 
DIVIDE(
    [Total Revenue],
    [Unique Customers],
    0
)
```
- **Format:** Currency (`$#,##0.00`)
- **What it calculates:** Average cumulative monetary yield per active customer.
- **Business purpose:** Supports customer lifetime value (LTV) tracking and tier segmentation.
- **Important DAX concepts:** Reusable measure division.

---

### Category 04: Products
**Display Folder:** `04 Products`

#### 22. Product Revenue
```dax
Product Revenue = [Total Revenue]
```
- **Format:** Currency (`$#,##0.00`)
- **What it calculates:** Total sales revenue evaluated in the context of the merchandise dimension (`DimProduct`).
- **Business purpose:** Standardized alias for product-level reporting.
- **Important DAX concepts:** Dynamic context transition via star schema relationship.

#### 23. Product Profit
```dax
Product Profit = [Total Profit]
```
- **Format:** Currency (`$#,##0.00`)
- **What it calculates:** Net gross profit evaluated in the context of `DimProduct`.
- **Business purpose:** Measures bottom-line earnings generated by individual categories, subcategories, or SKUs.
- **Important DAX concepts:** Standardized base measure alias.

#### 24. Product Units Sold
```dax
Product Units Sold = [Total Units Sold]
```
- **Format:** Whole Number (`#,##0`)
- **What it calculates:** Total physical units sold for the selected product context.
- **Business purpose:** Analyzes SKU sales velocity and warehouse replenishment rates.
- **Important DAX concepts:** Base measure alias.

#### 25. Product Profit Margin %
```dax
Product Profit Margin % = 
DIVIDE(
    [Product Profit],
    [Product Revenue],
    0
)
```
- **Format:** Percentage (`0.00%`)
- **What it calculates:** Profit margin percentage across product categories and SKUs.
- **Business purpose:** Differentiates high-margin specialty items from low-margin commodity volume drivers.
- **Important DAX concepts:** Safe ratio via `DIVIDE()`.

#### 26. Product Revenue Rank
```dax
Product Revenue Rank = 
IF(
    ISINSCOPE(DimProduct[ProductName]),
    RANKX(
        ALLSELECTED(DimProduct[ProductName]),
        [Total Revenue],
        ,
        DESC,
        DENSE
    )
)
```
- **Format:** Whole Number (`#,##0`)
- **What it calculates:** Ordinal rank (1 = highest revenue) of products within the currently selected category/subcategory filter.
- **Business purpose:** Powers "Top 10 Products" visual rankings and merchandising leaderboards.
- **Important DAX concepts:** `ISINSCOPE` prevents meaningless grand total rankings; `ALLSELECTED` preserves user-applied category slicers while ranking individual products; `RANKX` with `DENSE`.

#### 27. Product Profit Rank
```dax
Product Profit Rank = 
IF(
    ISINSCOPE(DimProduct[ProductName]),
    RANKX(
        ALLSELECTED(DimProduct[ProductName]),
        [Total Profit],
        ,
        DESC,
        DENSE
    )
)
```
- **Format:** Whole Number (`#,##0`)
- **What it calculates:** Ordinal rank (1 = highest profit) of products within the active filter scope.
- **Business purpose:** Identifies true profit drivers versus high-volume/low-margin items.
- **Important DAX concepts:** `ISINSCOPE`, `RANKX`, `ALLSELECTED`.

---

### Category 05: Stores
**Display Folder:** `05 Stores`

#### 28. Store Revenue
```dax
Store Revenue = [Total Revenue]
```
- **Format:** Currency (`$#,##0.00`)
- **What it calculates:** Total sales revenue evaluated in the context of retail outlets (`DimStore`).
- **Business purpose:** Measures retail sales volume across physical stores and the digital e-commerce storefront.
- **Important DAX concepts:** Base measure alias evaluated over `DimStore` relationships.

#### 29. Store Profit
```dax
Store Profit = [Total Profit]
```
- **Format:** Currency (`$#,##0.00`)
- **What it calculates:** Net gross profit generated by store locations.
- **Business purpose:** Evaluates store-level commercial profitability.
- **Important DAX concepts:** Base measure alias.

#### 30. Store Profit Margin %
```dax
Store Profit Margin % = 
DIVIDE(
    [Store Profit],
    [Store Revenue],
    0
)
```
- **Format:** Percentage (`0.00%`)
- **What it calculates:** Profit margin percentage across stores, cities, states, and sales regions.
- **Business purpose:** Identifies operational margin variance across store formats (Mall vs. Flagship vs. Online).
- **Important DAX concepts:** Safe ratio via `DIVIDE()`.

#### 31. Store Units Sold
```dax
Store Units Sold = [Total Units Sold]
```
- **Format:** Whole Number (`#,##0`)
- **What it calculates:** Total physical units sold by store.
- **Business purpose:** Monitors checkout volume and store logistics capacity.
- **Important DAX concepts:** Base measure alias.

#### 32. Store Revenue Rank
```dax
Store Revenue Rank = 
IF(
    ISINSCOPE(DimStore[StoreName]),
    RANKX(
        ALLSELECTED(DimStore[StoreName]),
        [Total Revenue],
        ,
        DESC,
        DENSE
    )
)
```
- **Format:** Whole Number (`#,##0`)
- **What it calculates:** Ordinal rank of stores by sales revenue within the selected geographic territory.
- **Business purpose:** Supports regional store benchmarking, manager competitions, and bonus allocations.
- **Important DAX concepts:** `ISINSCOPE`, `ALLSELECTED`, `RANKX`.

#### 33. Store Profit Rank
```dax
Store Profit Rank = 
IF(
    ISINSCOPE(DimStore[StoreName]),
    RANKX(
        ALLSELECTED(DimStore[StoreName]),
        [Total Profit],
        ,
        DESC,
        DENSE
    )
)
```
- **Format:** Whole Number (`#,##0`)
- **What it calculates:** Ordinal rank of stores by bottom-line net profit.
- **Business purpose:** Highlights stores generating maximum return on floor space.
- **Important DAX concepts:** `ISINSCOPE`, `ALLSELECTED`, `RANKX`.

---

### Category 06: Time Intelligence
**Display Folder:** `06 Time Intelligence`
*Note: All time-intelligence measures strictly leverage the certified official Date Table: `DimDate[FullDate]`.*

#### 34. Revenue Previous Month
```dax
Revenue Previous Month = 
CALCULATE(
    [Total Revenue],
    DATEADD(DimDate[FullDate], -1, MONTH)
)
```
- **Format:** Currency (`$#,##0.00`)
- **What it calculates:** Total revenue for the immediately preceding calendar month.
- **Business purpose:** Baseline for Month-over-Month (MoM) trend tracking.
- **Important DAX concepts:** Context modification via `CALCULATE()` and `DATEADD()` over contiguous date table.

#### 35. Profit Previous Month
```dax
Profit Previous Month = 
CALCULATE(
    [Total Profit],
    DATEADD(DimDate[FullDate], -1, MONTH)
)
```
- **Format:** Currency (`$#,##0.00`)
- **What it calculates:** Total net profit for the immediately preceding calendar month.
- **Business purpose:** Baseline for MoM profit growth analysis.
- **Important DAX concepts:** `CALCULATE()` and `DATEADD()`.

#### 36. Revenue MoM Change
```dax
Revenue MoM Change = 
VAR _Current = [Total Revenue]
VAR _Previous = [Revenue Previous Month]
RETURN
    IF(
        NOT ISBLANK(_Current) && NOT ISBLANK(_Previous),
        _Current - _Previous
    )
```
- **Format:** Currency (`$#,##0.00`)
- **What it calculates:** Dollar variance between current month and prior month sales revenue.
- **Business purpose:** Quantifies absolute monthly revenue expansion or contraction.
- **Important DAX concepts:** Variables (`VAR`/`RETURN`), safe blank handling (`ISBLANK`).

#### 37. Revenue MoM %
```dax
Revenue MoM % = 
DIVIDE(
    [Revenue MoM Change],
    [Revenue Previous Month],
    BLANK()
)
```
- **Format:** Percentage (`0.00%`)
- **What it calculates:** Percentage growth rate of revenue month-over-month.
- **Business purpose:** Measures short-term sales acceleration or deceleration.
- **Important DAX concepts:** `DIVIDE()` returning `BLANK()` for the first chronological period (Jan 2023).

#### 38. Profit MoM Change
```dax
Profit MoM Change = 
VAR _Current = [Total Profit]
VAR _Previous = [Profit Previous Month]
RETURN
    IF(
        NOT ISBLANK(_Current) && NOT ISBLANK(_Previous),
        _Current - _Previous
    )
```
- **Format:** Currency (`$#,##0.00`)
- **What it calculates:** Dollar variance between current month and prior month net profit.
- **Business purpose:** Quantifies monthly profit expansion or contraction.
- **Important DAX concepts:** Variables and conditional verification.

#### 39. Profit MoM %
```dax
Profit MoM % = 
DIVIDE(
    [Profit MoM Change],
    [Profit Previous Month],
    BLANK()
)
```
- **Format:** Percentage (`0.00%`)
- **What it calculates:** Percentage growth rate of net profit month-over-month.
- **Business purpose:** Flags sudden monthly margin shocks or profitability erosion.
- **Important DAX concepts:** Safe ratio via `DIVIDE()`.

#### 40. Revenue Previous Year
```dax
Revenue Previous Year = 
CALCULATE(
    [Total Revenue],
    SAMEPERIODLASTYEAR(DimDate[FullDate])
)
```
- **Format:** Currency (`$#,##0.00`)
- **What it calculates:** Total revenue for the identical calendar period one year prior (e.g. October 2023 when viewing October 2024).
- **Business purpose:** Foundational baseline for Year-over-Year (YoY) annual comparison.
- **Important DAX concepts:** `SAMEPERIODLASTYEAR` operating over `DimDate[FullDate]`.

#### 41. Profit Previous Year
```dax
Profit Previous Year = 
CALCULATE(
    [Total Profit],
    SAMEPERIODLASTYEAR(DimDate[FullDate])
)
```
- **Format:** Currency (`$#,##0.00`)
- **What it calculates:** Total net profit for the identical period one year prior.
- **Business purpose:** Baseline for YoY bottom-line annual comparison.
- **Important DAX concepts:** `CALCULATE()` with `SAMEPERIODLASTYEAR()`.

#### 42. Revenue YoY Change
```dax
Revenue YoY Change = 
VAR _Current = [Total Revenue]
VAR _Previous = [Revenue Previous Year]
RETURN
    IF(
        NOT ISBLANK(_Current) && NOT ISBLANK(_Previous),
        _Current - _Previous
    )
```
- **Format:** Currency (`$#,##0.00`)
- **What it calculates:** Dollar variance between current period revenue and prior year revenue.
- **Business purpose:** Measures annual revenue expansion in real dollar terms.
- **Important DAX concepts:** Variables, defensive blank validation.

#### 43. Revenue YoY %
```dax
Revenue YoY % = 
DIVIDE(
    [Revenue YoY Change],
    [Revenue Previous Year],
    BLANK()
)
```
- **Format:** Percentage (`0.00%`)
- **What it calculates:** Year-over-Year percentage growth rate in revenue.
- **Business purpose:** The primary strategic benchmark reported to executive leadership and investors.
- **Important DAX concepts:** Safe division handling unpopulated baseline periods cleanly.

#### 44. Profit YoY Change
```dax
Profit YoY Change = 
VAR _Current = [Total Profit]
VAR _Previous = [Profit Previous Year]
RETURN
    IF(
        NOT ISBLANK(_Current) && NOT ISBLANK(_Previous),
        _Current - _Previous
    )
```
- **Format:** Currency (`$#,##0.00`)
- **What it calculates:** Dollar variance between current period profit and prior year profit.
- **Business purpose:** Measures annual profit expansion.
- **Important DAX concepts:** Variables, defensive blank handling.

#### 45. Profit YoY %
```dax
Profit YoY % = 
DIVIDE(
    [Profit YoY Change],
    [Profit Previous Year],
    BLANK()
)
```
- **Format:** Percentage (`0.00%`)
- **What it calculates:** Year-over-Year percentage growth rate in net profit.
- **Business purpose:** Ensures bottom-line profitability is compounding at or above top-line revenue growth.
- **Important DAX concepts:** Safe ratio via `DIVIDE()`.

#### 46. Revenue YTD
```dax
Revenue YTD = 
TOTALYTD(
    [Total Revenue],
    DimDate[FullDate]
)
```
- **Format:** Currency (`$#,##0.00`)
- **What it calculates:** Cumulative Year-to-Date revenue accumulated from January 1 of the selected year through the current date.
- **Business purpose:** Tracks progress toward annual sales targets.
- **Important DAX concepts:** `TOTALYTD` function leveraging the official Date Table.

#### 47. Profit YTD
```dax
Profit YTD = 
TOTALYTD(
    [Total Profit],
    DimDate[FullDate]
)
```
- **Format:** Currency (`$#,##0.00`)
- **What it calculates:** Cumulative Year-to-Date net profit accumulated from January 1 through the current date.
- **Business purpose:** Monitors cumulative annual fiscal profitability.
- **Important DAX concepts:** `TOTALYTD` function.

#### 48. Revenue Previous Year YTD
```dax
Revenue Previous Year YTD = 
CALCULATE(
    [Revenue YTD],
    SAMEPERIODLASTYEAR(DimDate[FullDate])
)
```
- **Format:** Currency (`$#,##0.00`)
- **What it calculates:** Cumulative Year-to-Date revenue for the identical period of the previous year.
- **Business purpose:** Enables apples-to-apples annual pacing comparisons (e.g. YTD through August 2024 vs. YTD through August 2023).
- **Important DAX concepts:** Composing `SAMEPERIODLASTYEAR` around `TOTALYTD`.

#### 49. Profit Previous Year YTD
```dax
Profit Previous Year YTD = 
CALCULATE(
    [Profit YTD],
    SAMEPERIODLASTYEAR(DimDate[FullDate])
)
```
- **Format:** Currency (`$#,##0.00`)
- **What it calculates:** Cumulative Year-to-Date profit for the identical period of the previous year.
- **Business purpose:** Evaluates annual profit trajectory against prior-year benchmarks.
- **Important DAX concepts:** Nested time-intelligence context modification.

---

### Category 07: Growth
**Display Folder:** `07 Growth`

#### 50. Revenue Growth %
```dax
Revenue Growth % = [Revenue YoY %]
```
- **Format:** Percentage (`0.00%`)
- **What it calculates:** Standardized enterprise annual revenue growth percentage.
- **Business purpose:** Primary top-line expansion KPI for executive scorecards.
- **Important DAX concepts:** Reusable measure alias.

#### 51. Profit Growth %
```dax
Profit Growth % = [Profit YoY %]
```
- **Format:** Percentage (`0.00%`)
- **What it calculates:** Standardized enterprise annual profit growth percentage.
- **Business purpose:** Primary bottom-line expansion KPI.
- **Important DAX concepts:** Reusable measure alias.

#### 52. Units Previous Month
```dax
Units Previous Month = 
CALCULATE(
    [Total Units Sold],
    DATEADD(DimDate[FullDate], -1, MONTH)
)
```
- **Format:** Whole Number (`#,##0`)
- **What it calculates:** Total physical units sold during the prior month.
- **Business purpose:** Baseline for monthly inventory velocity tracking.
- **Important DAX concepts:** `CALCULATE()` and `DATEADD()`.

#### 53. Units MoM %
```dax
Units MoM % = 
VAR _Current = [Total Units Sold]
VAR _Previous = [Units Previous Month]
RETURN
    IF(
        NOT ISBLANK(_Current) && NOT ISBLANK(_Previous) && _Previous > 0,
        DIVIDE(_Current - _Previous, _Previous, BLANK())
    )
```
- **Format:** Percentage (`0.00%`)
- **What it calculates:** Percentage change in merchandise units sold month-over-month.
- **Business purpose:** Isolates volume shocks from price changes.
- **Important DAX concepts:** Safe conditional division.

#### 54. Units Previous Year
```dax
Units Previous Year = 
CALCULATE(
    [Total Units Sold],
    SAMEPERIODLASTYEAR(DimDate[FullDate])
)
```
- **Format:** Whole Number (`#,##0`)
- **What it calculates:** Total units sold during the identical calendar period one year prior.
- **Business purpose:** Annual volume pacing baseline.
- **Important DAX concepts:** `SAMEPERIODLASTYEAR`.

#### 55. Units YoY %
```dax
Units YoY % = 
VAR _Current = [Total Units Sold]
VAR _Previous = [Units Previous Year]
RETURN
    IF(
        NOT ISBLANK(_Current) && NOT ISBLANK(_Previous) && _Previous > 0,
        DIVIDE(_Current - _Previous, _Previous, BLANK())
    )
```
- **Format:** Percentage (`0.00%`)
- **What it calculates:** Year-over-Year percentage change in physical units sold.
- **Business purpose:** Evaluates true unit demand growth independent of inflation or price adjustments.
- **Important DAX concepts:** Safe ratio with variable caching.

#### 56. Units Growth %
```dax
Units Growth % = [Units YoY %]
```
- **Format:** Percentage (`0.00%`)
- **What it calculates:** Annual unit volume growth KPI.
- **Business purpose:** High-level supply chain and fulfillment KPI.
- **Important DAX concepts:** Measure alias.

#### 57. Orders Previous Month
```dax
Orders Previous Month = 
CALCULATE(
    [Total Orders],
    DATEADD(DimDate[FullDate], -1, MONTH)
)
```
- **Format:** Whole Number (`#,##0`)
- **What it calculates:** Total distinct transactions completed in the prior month.
- **Business purpose:** Monthly transaction volume baseline.
- **Important DAX concepts:** `CALCULATE()` and `DATEADD()`.

#### 58. Orders MoM %
```dax
Orders MoM % = 
VAR _Current = [Total Orders]
VAR _Previous = [Orders Previous Month]
RETURN
    IF(
        NOT ISBLANK(_Current) && NOT ISBLANK(_Previous) && _Previous > 0,
        DIVIDE(_Current - _Previous, _Previous, BLANK())
    )
```
- **Format:** Percentage (`0.00%`)
- **What it calculates:** Month-over-Month percentage change in transaction checkout volume.
- **Business purpose:** Tracks monthly customer footfall and checkout traffic momentum.
- **Important DAX concepts:** Safe conditional division.

#### 59. Orders Previous Year
```dax
Orders Previous Year = 
CALCULATE(
    [Total Orders],
    SAMEPERIODLASTYEAR(DimDate[FullDate])
)
```
- **Format:** Whole Number (`#,##0`)
- **What it calculates:** Total distinct transactions completed in the identical period of the previous year.
- **Business purpose:** Annual transaction volume baseline.
- **Important DAX concepts:** `SAMEPERIODLASTYEAR`.

#### 60. Orders YoY %
```dax
Orders YoY % = 
VAR _Current = [Total Orders]
VAR _Previous = [Orders Previous Year]
RETURN
    IF(
        NOT ISBLANK(_Current) && NOT ISBLANK(_Previous) && _Previous > 0,
        DIVIDE(_Current - _Previous, _Previous, BLANK())
    )
```
- **Format:** Percentage (`0.00%`)
- **What it calculates:** Year-over-Year percentage change in sales transactions.
- **Business purpose:** Evaluates long-term customer transaction growth.
- **Important DAX concepts:** Variables and defensive division.

#### 61. Orders Growth %
```dax
Orders Growth % = [Orders YoY %]
```
- **Format:** Percentage (`0.00%`)
- **What it calculates:** Annual transaction volume growth rate.
- **Business purpose:** High-level customer activity indicator.
- **Important DAX concepts:** Measure alias.

---

### Category 08: Advanced Analytics
**Display Folder:** `08 Advanced Analytics`

#### 62. Revenue Contribution %
```dax
Revenue Contribution % = 
VAR _CurrentRevenue = [Total Revenue]
VAR _TotalSelectedRevenue = 
    CALCULATE(
        [Total Revenue],
        ALLSELECTED()
    )
RETURN
    DIVIDE(_CurrentRevenue, _TotalSelectedRevenue, 0)
```
- **Format:** Percentage (`0.00%`)
- **What it calculates:** The percentage of total active revenue represented by the current row or slice (e.g. Category, Subcategory, Store, Region, or Channel).
- **Business purpose:** Enables dynamic mix analysis and visual share-of-wallet breakdowns that respond to user slicers.
- **Important DAX concepts:** `ALLSELECTED()` preserves external slicers while clearing internal visual row-level filter context.

#### 63. Running Revenue
```dax
Running Revenue = 
VAR _MaxDate = MAX(DimDate[FullDate])
RETURN
    CALCULATE(
        [Total Revenue],
        FILTER(
            ALL(DimDate[FullDate]),
            DimDate[FullDate] <= _MaxDate
        )
    )
```
- **Format:** Currency (`$#,##0.00`)
- **What it calculates:** Cumulative chronological running sum of net revenue from the start of the data horizon (`2023-01-01`) through the current date.
- **Business purpose:** Visualizes cumulative corporate growth trajectory across days, months, and quarters.
- **Important DAX concepts:** `MAX()` context capture, `ALL()` to clear date axis filters, and `FILTER()` to accumulate historical dates.

#### 64. Running Profit
```dax
Running Profit = 
VAR _MaxDate = MAX(DimDate[FullDate])
RETURN
    CALCULATE(
        [Total Profit],
        FILTER(
            ALL(DimDate[FullDate]),
            DimDate[FullDate] <= _MaxDate
        )
    )
```
- **Format:** Currency (`$#,##0.00`)
- **What it calculates:** Cumulative chronological running sum of net profit.
- **Business purpose:** Tracks progressive accumulation of earnings across the reporting horizon.
- **Important DAX concepts:** `ALL()` date table override and progressive cumulative filter.

#### 65. Top Product
```dax
Top Product = 
VAR _TopProductTable = 
    TOPN(
        1,
        VALUES(DimProduct[ProductName]),
        [Total Revenue],
        DESC
    )
RETURN
    CONCATENATEX(
        _TopProductTable,
        DimProduct[ProductName],
        ", "
    )
```
- **Format:** Text
- **What it calculates:** Text name of the single highest-revenue product under the current filter context.
- **Business purpose:** Populates dynamic executive KPI card headers and category summaries.
- **Important DAX concepts:** Table constructor `TOPN()`, distinct column values `VALUES()`, and scalar text iterator `CONCATENATEX()`.

#### 66. Top Store
```dax
Top Store = 
VAR _TopStoreTable = 
    TOPN(
        1,
        VALUES(DimStore[StoreName]),
        [Total Revenue],
        DESC
    )
RETURN
    CONCATENATEX(
        _TopStoreTable,
        DimStore[StoreName],
        ", "
    )
```
- **Format:** Text
- **What it calculates:** Text name of the single highest-revenue retail store under the current filter context.
- **Business purpose:** Populates dynamic regional cards and executive summary callouts.
- **Important DAX concepts:** `TOPN()` and `CONCATENATEX()`.

#### 67. Customer Revenue Rank
```dax
Customer Revenue Rank = 
IF(
    ISINSCOPE(DimCustomer[CustomerID]),
    RANKX(
        ALLSELECTED(DimCustomer[CustomerID]),
        [Total Revenue],
        ,
        DESC,
        DENSE
    )
)
```
- **Format:** Whole Number (`#,##0`)
- **What it calculates:** Ordinal rank of customers based on total net monetary spend within the selected cohort or tier.
- **Business purpose:** Powers VIP customer leaderboards, loyalty segmentation, and high-value customer identification.
- **Important DAX concepts:** `ISINSCOPE`, `ALLSELECTED`, and `RANKX`.

#### 68. Product Pareto Contribution %
```dax
Product Pareto Contribution % = 
VAR _CurrentProductRevenue = [Total Revenue]
VAR _AllProductRevenue = 
    CALCULATE(
        [Total Revenue],
        ALLSELECTED(DimProduct)
    )
VAR _CumulativeRevenue = 
    CALCULATE(
        [Total Revenue],
        FILTER(
            ALLSELECTED(DimProduct[ProductID]),
            [Total Revenue] >= _CurrentProductRevenue
        )
    )
RETURN
    DIVIDE(_CumulativeRevenue, _AllProductRevenue, 0)
```
- **Format:** Percentage (`0.00%`)
- **What it calculates:** Running cumulative percentage of total catalog revenue contributed by products ranked from highest to lowest revenue.
- **Business purpose:** Powers 80/20 ABC inventory categorization and Pareto distribution visuals.
- **Important DAX concepts:** Multi-variable calculation, `ALLSELECTED()` over dimensional grain, and cumulative threshold filtering.

---

## 3. Summary of Formats and Settings

| Category | Measure Name | Data Type | Formatting String | Display Folder |
|---|---|---|---|---|
| **Sales KPIs** | `Total Revenue` | Decimal (Fixed) | `$#,##0.00` | `01 Sales KPIs` |
| **Sales KPIs** | `Total Cost` | Decimal (Fixed) | `$#,##0.00` | `01 Sales KPIs` |
| **Sales KPIs** | `Total Profit` | Decimal (Fixed) | `$#,##0.00` | `01 Sales KPIs` |
| **Sales KPIs** | `Total Orders` | Int64 | `#,##0` | `01 Sales KPIs` |
| **Sales KPIs** | `Total Units Sold` | Int64 | `#,##0` | `01 Sales KPIs` |
| **Sales KPIs** | `Unique Customers` | Int64 | `#,##0` | `01 Sales KPIs` |
| **Sales KPIs** | `Average Order Value` | Decimal (Fixed) | `$#,##0.00` | `01 Sales KPIs` |
| **Sales KPIs** | `Average Selling Price` | Decimal (Fixed) | `$#,##0.00` | `01 Sales KPIs` |
| **Sales KPIs** | `Revenue per Customer` | Decimal (Fixed) | `$#,##0.00` | `01 Sales KPIs` |
| **Profitability** | `Profit Margin %` | Decimal | `0.00%` | `02 Profitability` |
| **Profitability** | `Average Profit per Order` | Decimal (Fixed) | `$#,##0.00` | `02 Profitability` |
| **Profitability** | `Average Profit per Unit` | Decimal (Fixed) | `$#,##0.00` | `02 Profitability` |
| **Profitability** | `Total Discount Amount` | Decimal (Fixed) | `$#,##0.00` | `02 Profitability` |
| **Profitability** | `Total Gross Sales` | Decimal (Fixed) | `$#,##0.00` | `02 Profitability` |
| **Profitability** | `Average Discount Rate %` | Decimal | `0.00%` | `02 Profitability` |
| **Customers** | `Registered Customers` | Int64 | `#,##0` | `03 Customers` |
| **Customers** | `Repeat Customers` | Int64 | `#,##0` | `03 Customers` |
| **Customers** | `One-Time Customers` | Int64 | `#,##0` | `03 Customers` |
| **Customers** | `Repeat Customer Rate %` | Decimal | `0.00%` | `03 Customers` |
| **Customers** | `Orders per Customer` | Decimal | `0.00` | `03 Customers` |
| **Customers** | `Average Customer Revenue` | Decimal (Fixed) | `$#,##0.00` | `03 Customers` |
| **Products** | `Product Revenue` | Decimal (Fixed) | `$#,##0.00` | `04 Products` |
| **Products** | `Product Profit` | Decimal (Fixed) | `$#,##0.00` | `04 Products` |
| **Products** | `Product Units Sold` | Int64 | `#,##0` | `04 Products` |
| **Products** | `Product Profit Margin %` | Decimal | `0.00%` | `04 Products` |
| **Products** | `Product Revenue Rank` | Int64 | `#,##0` | `04 Products` |
| **Products** | `Product Profit Rank` | Int64 | `#,##0` | `04 Products` |
| **Stores** | `Store Revenue` | Decimal (Fixed) | `$#,##0.00` | `05 Stores` |
| **Stores** | `Store Profit` | Decimal (Fixed) | `$#,##0.00` | `05 Stores` |
| **Stores** | `Store Profit Margin %` | Decimal | `0.00%` | `05 Stores` |
| **Stores** | `Store Units Sold` | Int64 | `#,##0` | `05 Stores` |
| **Stores** | `Store Revenue Rank` | Int64 | `#,##0` | `05 Stores` |
| **Stores** | `Store Profit Rank` | Int64 | `#,##0` | `05 Stores` |
| **Time Intelligence** | `Revenue Previous Month` | Decimal (Fixed) | `$#,##0.00` | `06 Time Intelligence` |
| **Time Intelligence** | `Profit Previous Month` | Decimal (Fixed) | `$#,##0.00` | `06 Time Intelligence` |
| **Time Intelligence** | `Revenue MoM Change` | Decimal (Fixed) | `$#,##0.00` | `06 Time Intelligence` |
| **Time Intelligence** | `Revenue MoM %` | Decimal | `0.00%` | `06 Time Intelligence` |
| **Time Intelligence** | `Profit MoM Change` | Decimal (Fixed) | `$#,##0.00` | `06 Time Intelligence` |
| **Time Intelligence** | `Profit MoM %` | Decimal | `0.00%` | `06 Time Intelligence` |
| **Time Intelligence** | `Revenue Previous Year` | Decimal (Fixed) | `$#,##0.00` | `06 Time Intelligence` |
| **Time Intelligence** | `Profit Previous Year` | Decimal (Fixed) | `$#,##0.00` | `06 Time Intelligence` |
| **Time Intelligence** | `Revenue YoY Change` | Decimal (Fixed) | `$#,##0.00` | `06 Time Intelligence` |
| **Time Intelligence** | `Revenue YoY %` | Decimal | `0.00%` | `06 Time Intelligence` |
| **Time Intelligence** | `Profit YoY Change` | Decimal (Fixed) | `$#,##0.00` | `06 Time Intelligence` |
| **Time Intelligence** | `Profit YoY %` | Decimal | `0.00%` | `06 Time Intelligence` |
| **Time Intelligence** | `Revenue YTD` | Decimal (Fixed) | `$#,##0.00` | `06 Time Intelligence` |
| **Time Intelligence** | `Profit YTD` | Decimal (Fixed) | `$#,##0.00` | `06 Time Intelligence` |
| **Time Intelligence** | `Revenue Previous Year YTD`| Decimal (Fixed) | `$#,##0.00` | `06 Time Intelligence` |
| **Time Intelligence** | `Profit Previous Year YTD` | Decimal (Fixed) | `$#,##0.00` | `06 Time Intelligence` |
| **Growth** | `Revenue Growth %` | Decimal | `0.00%` | `07 Growth` |
| **Growth** | `Profit Growth %` | Decimal | `0.00%` | `07 Growth` |
| **Growth** | `Units Previous Month` | Int64 | `#,##0` | `07 Growth` |
| **Growth** | `Units MoM %` | Decimal | `0.00%` | `07 Growth` |
| **Growth** | `Units Previous Year` | Int64 | `#,##0` | `07 Growth` |
| **Growth** | `Units YoY %` | Decimal | `0.00%` | `07 Growth` |
| **Growth** | `Units Growth %` | Decimal | `0.00%` | `07 Growth` |
| **Growth** | `Orders Previous Month` | Int64 | `#,##0` | `07 Growth` |
| **Growth** | `Orders MoM %` | Decimal | `0.00%` | `07 Growth` |
| **Growth** | `Orders Previous Year` | Int64 | `#,##0` | `07 Growth` |
| **Growth** | `Orders YoY %` | Decimal | `0.00%` | `07 Growth` |
| **Growth** | `Orders Growth %` | Decimal | `0.00%` | `07 Growth` |
| **Advanced Analytics** | `Revenue Contribution %` | Decimal | `0.00%` | `08 Advanced Analytics` |
| **Advanced Analytics** | `Running Revenue` | Decimal (Fixed) | `$#,##0.00` | `08 Advanced Analytics` |
| **Advanced Analytics** | `Running Profit` | Decimal (Fixed) | `$#,##0.00` | `08 Advanced Analytics` |
| **Advanced Analytics** | `Top Product` | String (Text) | Text | `08 Advanced Analytics` |
| **Advanced Analytics** | `Top Store` | String (Text) | Text | `08 Advanced Analytics` |
| **Advanced Analytics** | `Customer Revenue Rank` | Int64 | `#,##0` | `08 Advanced Analytics` |
| **Advanced Analytics** | `Product Pareto Contribution %`| Decimal | `0.00%` | `08 Advanced Analytics` |
