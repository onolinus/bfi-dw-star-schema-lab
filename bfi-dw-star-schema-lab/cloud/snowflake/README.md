# Snowflake — Adaptation Guide

## Key Differences from SQL Server

| Feature | SQL Server | Snowflake |
|---|---|---|
| Identity/sequences | `IDENTITY(1,1)` | `AUTOINCREMENT` or `SEQUENCE` |
| Schema creation | `CREATE SCHEMA` | Same syntax |
| Data types | `NVARCHAR`, `DATETIME2` | `VARCHAR`, `TIMESTAMP_NTZ` |
| `BIT` type | `BIT` | `BOOLEAN` |
| `DECIMAL(18,2)` | Supported | Use `NUMBER(18,2)` |
| MERGE | Full T-SQL MERGE | Snowflake MERGE (slight syntax diff) |
| Clustered indexes | Row-store index | No indexes — use clustering keys |
| Foreign keys | Enforced | Defined but not enforced |
| Case sensitivity | Case-insensitive (default) | Case-insensitive (default, unquoted) |

---

## Database and Schema Setup

```sql
-- Snowflake equivalent of 00-setup scripts
CREATE DATABASE BFI_DW;
USE DATABASE BFI_DW;

CREATE SCHEMA stg;
CREATE SCHEMA dw;
CREATE SCHEMA rpt;
```

---

## Data Type Mapping

| SQL Server | Snowflake |
|---|---|
| `NVARCHAR(150)` | `VARCHAR(150)` |
| `DATETIME2` | `TIMESTAMP_NTZ` |
| `BIT` | `BOOLEAN` |
| `SMALLINT` | `SMALLINT` |
| `DECIMAL(18,2)` | `NUMBER(18,2)` |
| `CHAR(16)` | `CHAR(16)` |
| `IDENTITY(1,1)` | `NUMBER AUTOINCREMENT` |

---

## Dimension Table Example

```sql
CREATE OR REPLACE TABLE dw.dim_customer (
    customer_sk         NUMBER          AUTOINCREMENT PRIMARY KEY,
    customer_bk         VARCHAR(20)     NOT NULL,
    full_name           VARCHAR(150)    NOT NULL,
    marital_status      VARCHAR(20),
    kota_kabupaten      VARCHAR(100),
    provinsi            VARCHAR(100),
    income_bracket      VARCHAR(20),
    risk_rating         VARCHAR(10),
    effective_from      DATE            NOT NULL,
    effective_to        DATE            NOT NULL DEFAULT '9999-12-31',
    is_current          BOOLEAN         NOT NULL DEFAULT TRUE,
    dw_created_at       TIMESTAMP_NTZ   DEFAULT CURRENT_TIMESTAMP(),
    dw_updated_at       TIMESTAMP_NTZ   DEFAULT CURRENT_TIMESTAMP()
);
```

---

## Snowflake MERGE (SCD Type 1)

```sql
MERGE INTO dw.dim_product AS tgt
USING stg.product AS src
ON tgt.product_bk = src.product_id

WHEN MATCHED AND tgt.base_interest_rate <> src.base_interest_rate THEN
    UPDATE SET
        base_interest_rate = src.base_interest_rate,
        dw_updated_at      = CURRENT_TIMESTAMP()

WHEN NOT MATCHED THEN
    INSERT (product_bk, product_name, base_interest_rate, dw_created_at)
    VALUES (src.product_id, src.product_name, src.base_interest_rate, CURRENT_TIMESTAMP());
```

---

## Clustering Keys (replaces indexes)

```sql
-- Cluster fact_loan on disbursement date for time-based queries
ALTER TABLE dw.fact_loan CLUSTER BY (disbursement_date_sk);

-- Cluster fact_payment on due_date for collection analysis
ALTER TABLE dw.fact_payment CLUSTER BY (due_date_sk, collectibility_grade);
```

---

## Time Travel for Historical Queries

Snowflake's Time Travel can replace some SCD2 use cases for short retention windows:

```sql
-- View dim_customer as it was 30 days ago
SELECT * FROM dw.dim_customer AT (OFFSET => -30*24*60*60);
```

However, SCD2 is still preferred for:
- Retention beyond Snowflake's Time Travel limit (max 90 days on Enterprise)
- Portable history that works in any cloud or on-prem system
- Row-level control over which attributes trigger new versions

---

## Loading from External Stages (S3 / Azure / GCS)

```sql
-- Create external stage pointing to S3
CREATE STAGE stg_bfi_raw
    URL = 's3://bfi-data-lake/raw/'
    CREDENTIALS = (AWS_KEY_ID = '...' AWS_SECRET_KEY = '...');

-- Copy staged Parquet files to staging table
COPY INTO stg.customer
FROM @stg_bfi_raw/customer/
FILE_FORMAT = (TYPE = PARQUET);
```
