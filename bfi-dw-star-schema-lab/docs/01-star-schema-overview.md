# Star Schema Design — BFI Finance DW Lab

## What is a Star Schema?

A star schema organizes data warehouse tables into two types:

- **Fact tables** — store measurable, numeric events (loan disbursements, payments)
- **Dimension tables** — store descriptive context (who, what, where, when)

The name "star" comes from the diagram shape: fact table at the center, dimension tables branching out like points of a star.

---

## BFI Finance Star Schema

### Fact Tables

| Table | Grain | Key Measures |
|---|---|---|
| `fact_loan` | One row per disbursed loan | `disbursed_amount`, `monthly_installment`, `tenor_months` |
| `fact_payment` | One row per installment schedule line | `scheduled_amount`, `paid_amount`, `dpd` |

### Dimension Tables

| Table | SCD Type | Primary Use |
|---|---|---|
| `dim_date` | None (static) | Time-based filtering and grouping |
| `dim_customer` | **Type 2** | Customer profile at time of loan |
| `dim_product` | **Type 1** | Current product terms |
| `dim_branch` | **Type 2** | Branch at time of transaction |
| `dim_employee` | **Type 1** | Current employee role |
| `dim_collateral` | **Type 1** | Latest appraised value |

---

## Design Decisions

### 1. Surrogate Keys (SK)

Every dimension uses an `INT IDENTITY` surrogate key as its primary key. Natural/business keys from source systems are stored separately as `*_bk` columns.

**Why?**
- Source system keys can change format (VARCHAR → longer VARCHAR)
- SCD Type 2 requires multiple rows per entity — natural key alone cannot be PK
- JOIN performance: INT vs VARCHAR is significantly faster at scale

### 2. Unknown Member (`-1`)

Every dimension has a row with `SK = -1` labelled "Unknown". Fact rows that cannot resolve a dimension FK use `-1` instead of NULL.

**Why?**
- Foreign key constraints work without NULL allowances
- Reports show "Unknown" instead of blank/NULL — easier for business users
- Avoids LEFT JOIN issues in reporting tools

### 3. Date Dimension (dim_date)

Pre-calculated for 2015–2030. Stored as integer `date_sk = YYYYMMDD`.

**Why not just use a DATE column in facts?**
- Avoids repeated `YEAR()`, `MONTH()`, `DATENAME()` calculations at query time
- Enables pre-built fiscal calendar, Indonesian holiday flags, week numbers
- Enables partition elimination on columnstore-indexed warehouses

### 4. Degenerate Dimensions

`loan_bk` and `payment_bk` are stored directly in fact tables without a separate dimension table.

**Why?**
- They are natural keys with no descriptive attributes
- Building a dim table for them adds joins with no analytical benefit
- They serve as "transaction IDs" for drill-through from BI tools

### 5. Persisted Computed Columns

`fact_loan.total_interest_amount` and `fact_loan.approval_days` are `PERSISTED` computed columns.

**Why?**
- Calculated once at INSERT/UPDATE, not on every SELECT
- Can be indexed for fast range scans
- Eliminates the same computation in every report query

---

## Additive vs Non-Additive Measures

| Measure | Additive? | Correct Aggregation |
|---|---|---|
| `disbursed_amount` | Yes | SUM across all dimensions |
| `paid_amount` | Yes | SUM |
| `scheduled_amount` | Yes | SUM |
| `penalty_amount` | Yes | SUM |
| `interest_rate` | No (ratio) | AVG — never SUM |
| `dpd` | No (status) | MAX or AVG |
| `tenor_months` | Semi-additive | AVG (SUM is meaningless) |
| `collectibility_grade` | No | MAX (worst grade in group) |

---

## Grain Definition Examples

### fact_loan
**"One row per approved and disbursed loan"**

This means:
- Rejected applications have a row (with `loan_status = 'REJECTED'`, NULLs for amounts)
- Pending applications also have a row — updated to DISBURSED when approved
- Re-financing the same asset creates a NEW loan row

### fact_payment
**"One row per installment schedule line"**

This means:
- A 24-month loan creates 24 rows at schedule generation time
- Rows start as `OVERDUE` and are updated to `PAID` when payment arrives
- Partial payments update `paid_amount` without creating a new row

---

## Query Patterns and Index Strategy

```sql
-- Pattern 1: Monthly origination (hits disbursement_date_sk + product_sk)
SELECT ... FROM fact_loan
JOIN dim_date ON date_sk = disbursement_date_sk
JOIN dim_product ON product_sk = fact_loan.product_sk
WHERE year_number = 2024

-- Pattern 2: Collection rate by branch (hits branch_sk + due_date_sk)  
SELECT ... FROM fact_payment
JOIN dim_branch ON branch_sk = fact_payment.branch_sk
JOIN dim_date ON date_sk = due_date_sk

-- Pattern 3: Customer 360 (hits customer_sk + loan_sk)
SELECT ... FROM dim_customer
JOIN fact_loan ON customer_sk = dim_customer.customer_sk
JOIN fact_payment ON loan_sk = fact_loan.loan_sk
```

Indexes are created to cover these patterns. See `03-facts/` DDL scripts.
