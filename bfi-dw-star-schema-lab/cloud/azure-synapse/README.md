# Azure Synapse Analytics — Adaptation Guide

## Key Differences from SQL Server

| Feature | SQL Server | Azure Synapse |
|---|---|---|
| IDENTITY columns | `IDENTITY(1,1)` | Use `SEQUENCE` or `IDENTITY` (dedicated pool) |
| Filegroups | Required | Not applicable |
| Table distribution | N/A | `ROUND_ROBIN`, `HASH`, `REPLICATE` |
| Indexes | Clustered/Nonclustered | Clustered Columnstore (default) |
| MERGE statement | Full support | Not supported — use INSERT/UPDATE pattern |
| `TOP` without ORDER BY | Allowed | Avoid — use window functions |
| `GETDATE()` | Supported | Use `GETDATE()` or `CURRENT_TIMESTAMP` |
| Foreign keys | Enforced | Declared but NOT enforced |

---

## Recommended Distribution Strategy

```sql
-- Fact tables: distribute on the highest-cardinality FK (usually customer_sk or date)
CREATE TABLE dw.fact_loan
WITH (
    DISTRIBUTION = HASH(customer_sk),
    CLUSTERED COLUMNSTORE INDEX
) AS ...

CREATE TABLE dw.fact_payment
WITH (
    DISTRIBUTION = HASH(loan_sk),
    CLUSTERED COLUMNSTORE INDEX
) AS ...

-- Large dimensions: hash distribute
CREATE TABLE dw.dim_customer
WITH (
    DISTRIBUTION = HASH(customer_sk),
    CLUSTERED COLUMNSTORE INDEX
) AS ...

-- Small dimensions (< 2 million rows): replicate across all distributions
CREATE TABLE dw.dim_date
WITH (
    DISTRIBUTION = REPLICATE,
    HEAP    -- date dim is read-only; heap is fine
) AS ...

CREATE TABLE dw.dim_product
WITH (
    DISTRIBUTION = REPLICATE,
    CLUSTERED INDEX (product_sk)
) AS ...
```

---

## Replacing MERGE with INSERT/UPDATE

Synapse Dedicated SQL Pool does not support `MERGE`. Use this pattern instead:

```sql
-- Step 1: Update existing rows
UPDATE tgt
SET
    tgt.base_interest_rate = src.base_interest_rate,
    tgt.dw_updated_at      = GETDATE()
FROM dw.dim_product tgt
INNER JOIN stg.product src ON tgt.product_bk = src.product_id
WHERE tgt.base_interest_rate <> src.base_interest_rate;

-- Step 2: Insert new rows
INSERT INTO dw.dim_product (...)
SELECT ...
FROM stg.product src
WHERE NOT EXISTS (
    SELECT 1 FROM dw.dim_product tgt WHERE tgt.product_bk = src.product_id
);
```

---

## PolyBase / COPY INTO for Staging

Replace manual inserts with bulk loading:

```sql
-- Load from Azure Data Lake Storage Gen2
COPY INTO stg.customer
FROM 'https://<storage>.dfs.core.windows.net/raw/customer/*.parquet'
WITH (
    FILE_TYPE = 'PARQUET',
    CREDENTIAL = (IDENTITY = 'Managed Identity')
);
```

---

## Columnstore Benefits for This Schema

The default clustered columnstore index in Synapse gives:
- 5–10x compression over row stores for fact tables
- Batch-mode execution for aggregations (SUM, COUNT, AVG)
- Segment elimination for date-range scans (no date partitioning needed for < 1B rows)

---

## Serverless Pool (SQL Serverless)

For the analytics queries in `06-analytics/`, you can run them against Parquet files in ADLS without loading into dedicated pool:

```sql
-- Query Parquet directly (Serverless pool)
SELECT
    year(disbursement_date) AS tahun,
    SUM(disbursed_amount)   AS total_idr
FROM OPENROWSET(
    BULK 'https://<storage>.dfs.core.windows.net/gold/fact_loan/*.parquet',
    FORMAT = 'PARQUET'
) AS fact
GROUP BY year(disbursement_date);
```
