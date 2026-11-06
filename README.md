# H&M Customer Analytics: RFM Segmentation and Churn Dashboard

A portfolio case study that treats H&M as the business context for a customer retention analysis. Raw transaction sheets are cleaned and combined in SQL Server, customers are segmented with RFM in Python, and the results are presented in a Power BI dashboard.

> **Data disclaimer.** This is an independent case study and is not affiliated with H&M. H&M is used only as the business scenario. The data is the public Online Retail II dataset from a UK online gift retailer, not H&M data, so none of the findings describe H&M's actual customers or performance.

## Business problem

In this scenario, H&M's CRM team wants to know who its best customers are and which of them are slipping away. Most retail revenue comes from a small group of repeat customers, but transaction-level data does not show who they are. The project answers three questions:

1. Who are the highest-value customers, and how much revenue do they generate?
2. Which previously active customers are at risk of lapsing?
3. How do revenue, order volume and customer mix change over time and by country?

## Dataset

Transactional data for 2009-2010 and 2010-2011 (invoice, stock code, description, quantity, invoice date, unit price, customer ID, country). It matches the public **Online Retail II** dataset (UCI Machine Learning Repository), used here as a stand-in for retail transaction data.

The data is not included in this repository because of file size. See [`data/README.md`](data/README.md) for download instructions.

## Architecture

```
Raw sheets (2009_2010, 2010_2011)
        |
        v
SQL Server: combine, type-convert, validate, deduplicate  -->  dbo.RetailCleaned (~1.03M rows)
        |
        v
Python (pandas): filter, RFM scoring, segmentation, churn flag  -->  transaction-level export
        |
        v
Power BI: KPIs, segment analysis, trends, country view
```

## Repository structure

```
hm-customer-analytics/
├── sql/
│   └── 01_clean_and_combine.sql
├── notebooks/
│   └── rfm_segmentation.ipynb
├── docs/
│   └── Business_Requirements_Document.docx
├── dashboard/
│   ├── Retail_Dashboard.pbix
│   └── screenshots/
├── data/
│   └── README.md
└── README.md
```

## Methodology

### 1. Cleaning and combining in SQL

The two yearly tables are stacked with `UNION ALL`, and a `SourceSheet` column keeps track of the origin of each row.

- **Safe type conversion.** `InvoiceDate` arrives as text in more than one format, so it is parsed with `TRY_CONVERT` using style 120, falling back to style 105. `Price` is converted to `decimal(10,2)`. Failed conversions return NULL instead of aborting the load, and counts of failed dates and prices are checked after the load.
- **Data quality checks.** Rows are counted for missing `Customer_ID`, zero or negative `Quantity`, and missing `Description`.
- **Deduplication.** Exact duplicates across all eight business columns are identified with `GROUP BY ... HAVING COUNT(*) > 1`, then removed using `ROW_NUMBER()` and keeping the first row per group.

The cleaned result is stored as `dbo.RetailCleaned`.

Rows with negative quantities (returns and cancellations) and rows without a customer ID are deliberately **kept** at this stage. They are valid transactions for revenue reconciliation, and are only excluded from the customer-level analysis in Python.

### 2. RFM segmentation in Python

Analysis population: rows with a non-null `Customer_ID` and `Quantity > 0`.

| Metric | Definition |
|---|---|
| Recency | Days between the customer's last purchase and the snapshot date (2011-12-10) |
| Frequency | Number of distinct invoices |
| Monetary | Sum of `Quantity x Price` |

Each metric is scored 1 to 5 using quintiles (`pd.qcut`). Recency is reversed so that 5 means most recent. Frequency is ranked first (`method='first'`) because many customers share the same invoice count and plain quintile cut-offs would not be unique.

Segment rules, applied in order:

| Segment | Rule |
|---|---|
| Champions | R >= 4, F >= 4, M >= 4 |
| Loyal | R >= 3, F >= 3 |
| At Risk | R <= 2, F >= 3 |
| New | R >= 4, F <= 2 |
| Needs Attention | R = 3, F <= 2 |
| Lost | Everything else |

**Churn flag:** `IsChurned = Recency > 90 days`.

The scores, segments and churn flag are merged back onto the transaction rows, with `InvoiceMonth` and `Revenue` added, and exported as the dashboard's source table.

### 3. Power BI dashboard

The dashboard is built on the exported transaction-level table.

> Add screenshots here once the report pages are final.
>
> ```
> ![Overview](dashboard/screenshots/01_overview.png)
> ![Customer segments](dashboard/screenshots/02_segments.png)
> ```

Pages and visuals (update to match the final report):

- Executive overview: total revenue, orders, active customers, average order value
- Segment analysis: customers and revenue by RFM segment
- Churn view: churned vs active customers, revenue at risk
- Trend and geography: monthly revenue, top countries

## Key findings

> Fill in from the final dashboard. Use real numbers only.

- X% of revenue comes from Champions, who make up Y% of customers.
- X customers in the At Risk segment represent R of historical revenue.
- Revenue peaks in [month], consistent with seasonal gift demand.
- [Country] is the largest market after the UK, with X% of revenue.

## Assumptions and limitations

- **Scenario vs data.** The business context is H&M, but the data comes from a small UK gift retailer with a large wholesale customer base. Segment sizes, seasonality and country mix will not resemble H&M's fashion retail business, and the findings should be read as a demonstration of method only.
- **Snapshot date.** Recency is measured from 2011-12-10, just after the last transaction in the data, so it is not relative to today's date.
- **Churn threshold.** The 90-day cut-off is a simple business rule, not derived from the data. A better version would base it on each customer's typical gap between orders, since a wholesale buyer ordering quarterly is not churned at 91 days.
- **Returns.** Monetary value uses positive-quantity rows only, so it is gross purchase value and does not net out returns.
- **Anonymous transactions.** Rows with no customer ID (roughly a fifth of the cleaned data) are excluded from segmentation, so segment revenue does not add up to total company revenue.
- **Wholesale customers.** The retailer sells to many wholesale buyers, so a few very high-value customers can dominate the Monetary score. Quintile scoring reduces this, but does not remove it.

## How to reproduce

1. Download the dataset and load both yearly sheets into SQL Server as `dbo.[2009_2010]` and `dbo.[2010_2011]` in a database of your choice.
2. Run `sql/01_clean_and_combine.sql` to produce `dbo.RetailCleaned`, and export it to `RetailCleaned.csv` (the notebook reads it without a header row).
3. Run `notebooks/rfm_segmentation.ipynb`. It writes `EcommerceDashboardData.xlsx`.
4. Open `dashboard/Retail_Dashboard.pbix` and point the data source at the exported file.

## Tools

SQL Server (T-SQL), Python (pandas), Power BI, Jupyter.

## Documentation

The business requirements, KPI definitions and scope are in [`docs/Business_Requirements_Document.docx`](docs/Business_Requirements_Document.docx).

## Author

Charles Bruno G, Data Analyst (SQL, Power BI, Python)
[LinkedIn](https://www.linkedin.com/in/charles-brunog/) 
