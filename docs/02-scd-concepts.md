# Slowly Changing Dimensions (SCD) — Concepts & Lab Guide

## What is an SCD?

Dimension data is not static. Customers move, branches get reclassified, products change rates. How you handle these changes determines whether your historical reports are accurate.

**SCD = Slowly Changing Dimension** — a pattern for managing changes to dimension attributes over time.

---

## SCD Type 1 — Overwrite

**"We only care about the current value."**

When an attribute changes, the existing row is simply updated. No history is kept.

```
BEFORE change:
customer_sk | full_name    | income_bracket | dw_updated_at
1           | Budi Santoso | MIDDLE         | 2023-01-15

AFTER income bracket update:
customer_sk | full_name    | income_bracket | dw_updated_at
1           | Budi Santoso | UPPER          | 2024-08-01
```

The row with `MIDDLE` is **gone forever**.

### When to use SCD Type 1

Use SCD1 when the old value is incorrect (data fix) or when historical accuracy of that attribute does not matter for business decisions.

In this lab:
- `dim_product.base_interest_rate` — business wants current rate, not historical
- `dim_employee.job_title` — reports use current title
- `dim_collateral.appraised_value` — always show latest valuation

### ETL Implementation

SQL Server `MERGE` statement:
```sql
MERGE dim_product AS tgt
USING stg.product AS src ON tgt.product_bk = src.product_id
WHEN MATCHED AND tgt.base_interest_rate <> src.base_interest_rate THEN
    UPDATE SET
        tgt.base_interest_rate = src.base_interest_rate,
        tgt.dw_updated_at      = SYSUTCDATETIME()
WHEN NOT MATCHED THEN
    INSERT (...) VALUES (...);
```

---

## SCD Type 2 — Add New Row (Track History)

**"We need to know what the value was at any point in time."**

When an attribute changes, the old row is expired and a new row is inserted with the new values. Both rows remain in the table.

```
BEFORE change (CUST-0001 in Jakarta Pusat):
customer_sk | customer_bk | kota         | effective_from | effective_to | is_current
1           | CUST-0001   | Jakarta Pusat| 2023-01-15     | 9999-12-31   | 1

AFTER move to Tangerang (run on 2024-08-01):
customer_sk | customer_bk | kota             | effective_from | effective_to | is_current
1           | CUST-0001   | Jakarta Pusat    | 2023-01-15     | 2024-07-31   | 0   ← expired
2           | CUST-0001   | Tangerang Selatan| 2024-08-01     | 9999-12-31   | 1   ← current
```

### The Three-Column SCD2 Marker

| Column | Purpose |
|---|---|
| `effective_from` | Date this row version became valid |
| `effective_to` | Date this row version became invalid (`9999-12-31` = still current) |
| `is_current` | Quick filter flag — avoids date range comparison for current state |

### How Fact Tables Link to the Right Version

When the ETL loads `fact_loan`, it looks up the dimension SK at the time of the event:

```sql
-- At load time (2023-01-15), CUST-0001's current SK = 1 (Jakarta Pusat)
INSERT INTO fact_loan (customer_sk, ...)
SELECT dc.customer_sk, ...
FROM stg.loan_application la
JOIN dim_customer dc ON dc.customer_bk = la.customer_id AND dc.is_current = 1
```

When the same customer takes a new loan in 2024-09-01, the ETL finds SK = 2 (Tangerang):

```sql
-- After address change, is_current=1 now points to SK=2
-- New loan automatically links to Tangerang address
```

**This is the magic of SCD2**: old loans show the old address, new loans show the new address — automatically.

### Point-in-Time Query

To find what the customer's address was on a specific date:

```sql
SELECT *
FROM dim_customer
WHERE customer_bk = 'CUST-0001'
  AND '2023-06-01' BETWEEN effective_from AND effective_to;
```

### When to use SCD Type 2

Use SCD2 when the history of an attribute affects analytical results:
- Customer address for geographic analysis
- Branch region for regional performance attribution
- Credit risk rating to analyze how risk changed over customer lifetime

---

## SCD Type 3 — Add New Column

Adds a new column to store the PREVIOUS value alongside the current value. Keeps only one historical snapshot.

```
customer_sk | current_city    | previous_city
1           | Tangerang       | Jakarta Pusat
```

**Not implemented in this lab** — rarely used because it only tracks one change, not a full history.

---

## Comparison Table

| Aspect | SCD Type 1 | SCD Type 2 |
|---|---|---|
| History kept? | No | Yes (unlimited versions) |
| Row count grows? | No | Yes — one new row per change |
| Query complexity | Simple | Requires `is_current` or date filter |
| Storage cost | Low | Grows over time |
| Use case | Corrections, current-only reporting | Historical accuracy required |
| ETL complexity | Low (MERGE) | Medium (expire + insert) |

---

## Common SCD2 Pitfalls

### 1. Forgetting `is_current = 1` in fact ETL
If you forget the `is_current` filter when looking up dimension SK, you may match the wrong (historical) version.

```sql
-- WRONG: may match expired rows
JOIN dim_customer dc ON dc.customer_bk = la.customer_id

-- CORRECT: always filter to current row when loading facts
JOIN dim_customer dc ON dc.customer_bk = la.customer_id AND dc.is_current = 1
```

### 2. Reporting without `is_current`
In BI tools, always add `is_current = 1` to dimension filters or you will double-count customers who have multiple rows.

### 3. SCD2 on very-high-churn attributes
If an attribute changes daily (e.g., account balance), SCD2 is not appropriate — use a snapshot fact table instead.

### 4. Effective date gaps
Ensure `effective_to = effective_from - 1 day` of the next version. Gaps in date ranges cause records to be missed in point-in-time queries.

---

## SCD2 ETL Sequence (for this lab)

```
1. IDENTIFY changed rows
   WHERE is_current = 1
     AND (dim.tracked_attr <> staging.attr)

2. EXPIRE old rows
   UPDATE SET effective_to = YESTERDAY, is_current = 0

3. INSERT new version rows
   INSERT with effective_from = TODAY, effective_to = 9999-12-31, is_current = 1

4. (Optional) SCD1 within SCD2
   UPDATE non-tracked attributes on the current row
   (e.g., phone number — overwrite without creating a new version)
```
