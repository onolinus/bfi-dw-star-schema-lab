# Google BigQuery — Adaptation Guide

## Key Differences from SQL Server

| Feature | SQL Server | BigQuery |
|---|---|---|
| Schemas | `CREATE SCHEMA` | Datasets |
| Identity/auto-increment | `IDENTITY(1,1)` | No native sequence — use `GENERATE_UUID()` or `ROW_NUMBER()` |
| MERGE | Full T-SQL MERGE | Supported with restrictions |
| Clustered indexes | B-Tree index | Clustering on up to 4 columns |
| Partitioning | Filegroups | Date/integer partitioning |
| Stored procedures | Supported | Supported (limited) |
| NULL handling | Standard | Standard |
| String type | `VARCHAR`/`NVARCHAR` | `STRING` |
| Date/time | `DATE`, `DATETIME2` | `DATE`, `DATETIME`, `TIMESTAMP` |
| Boolean | `BIT` | `BOOL` |
| Decimal | `DECIMAL(18,2)` | `NUMERIC` or `BIGNUMERIC` |

---

## Dataset Setup (equivalent of schemas)

```sql
-- In BigQuery, schemas = datasets (created in Console or via bq CLI)
-- bq mk --dataset bfi_dw:stg
-- bq mk --dataset bfi_dw:dw
-- bq mk --dataset bfi_dw:rpt
```

---

## Dimension Table Example

```sql
CREATE OR REPLACE TABLE `bfi_dw.dw.dim_customer` (
    customer_sk     INT64,      -- managed via SEQUENCE object or ETL counter
    customer_bk     STRING      NOT NULL,
    full_name       STRING      NOT NULL,
    marital_status  STRING,
    kota_kabupaten  STRING,
    provinsi        STRING,
    income_bracket  STRING,
    risk_rating     STRING,
    effective_from  DATE        NOT NULL,
    effective_to    DATE        NOT NULL,
    is_current      BOOL        NOT NULL,
    dw_created_at   TIMESTAMP,
    dw_updated_at   TIMESTAMP
)
CLUSTER BY customer_bk, is_current;  -- replaces nonclustered index
```

---

## BigQuery MERGE (SCD Type 1)

```sql
MERGE `bfi_dw.dw.dim_product` AS tgt
USING `bfi_dw.stg.product` AS src
ON tgt.product_bk = src.product_id

WHEN MATCHED AND tgt.base_interest_rate != src.base_interest_rate THEN
  UPDATE SET
    base_interest_rate = src.base_interest_rate,
    dw_updated_at      = CURRENT_TIMESTAMP()

WHEN NOT MATCHED THEN
  INSERT (product_bk, product_name, base_interest_rate, dw_created_at, dw_updated_at)
  VALUES (src.product_id, src.product_name, src.base_interest_rate,
          CURRENT_TIMESTAMP(), CURRENT_TIMESTAMP());
```

**BigQuery MERGE restrictions:**
- Target table must be partitioned by `_PARTITIONTIME` or an ingestion-time partition if you use DML filters
- MERGE is subject to DML quotas (1000 DML statements/day on free tier)
- Consider INSERT OVERWRITE pattern for large batch loads

---

## Partitioning Strategy

```sql
-- Partition fact_loan by disbursement date for cost-efficient queries
CREATE TABLE `bfi_dw.dw.fact_loan`
PARTITION BY DATE(disbursement_date)  -- add a DATE column (not SK)
CLUSTER BY customer_sk, product_sk
AS SELECT * FROM ...;
```

> In BigQuery you typically store the actual `DATE` in fact tables (not integer date_sk) because BigQuery's partition pruning works on DATE/TIMESTAMP columns, not integers.

---

## Analytics Queries Adaptation

Replace SQL Server window functions — BigQuery supports standard SQL:

```sql
-- Monthly loan origination (BigQuery syntax)
SELECT
    EXTRACT(YEAR FROM disbursement_date)    AS tahun,
    EXTRACT(MONTH FROM disbursement_date)   AS bulan,
    product_category,
    COUNT(*)                                AS jumlah_kontrak,
    SUM(disbursed_amount)                   AS total_idr
FROM `bfi_dw.dw.fact_loan`
JOIN `bfi_dw.dw.dim_product` USING (product_sk)
WHERE loan_status = 'DISBURSED'
  AND disbursement_date >= '2023-01-01'
GROUP BY 1, 2, 3
ORDER BY 1, 2, 3;
```

---

## Surrogate Key Strategy in BigQuery

BigQuery has no native IDENTITY column. Options:

**Option 1: ETL-managed counter** (recommended for small tables)
```python
# In your Dataflow / Cloud Composer ETL
max_sk = bq_client.query("SELECT MAX(customer_sk) FROM dw.dim_customer").result()
new_sk = max_sk + 1
```

**Option 2: UUID as SK** (for distributed loads)
```sql
SELECT FARM_FINGERPRINT(customer_bk) AS customer_sk, ...
```

**Option 3: Row hash** (simple, deterministic)
```sql
SELECT ABS(FARM_FINGERPRINT(CONCAT(customer_bk, CAST(effective_from AS STRING)))) AS customer_sk
```
