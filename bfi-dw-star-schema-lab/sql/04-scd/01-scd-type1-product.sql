-- =============================================================================
-- FILE   : 04-scd/01-scd-type1-product.sql
-- PURPOSE: Lab exercise — SCD Type 1 on dim_product
-- CONCEPT: Simulate a rate change for Motor Baru and show that HISTORY IS LOST
-- =============================================================================
-- LEARNING OBJECTIVES:
--   1. Understand that SCD Type 1 OVERWRITES the record
--   2. Verify that historical fact rows now reflect the NEW rate (no rollback)
--   3. Compare with SCD Type 2 behavior in 03-scd-type2-customer.sql
-- =============================================================================

USE TrainingSQL;
GO

PRINT '=== SCD TYPE 1 LAB — Product Interest Rate Change ===';
PRINT '';

-- -----------------------------------------------------------------------
-- BEFORE: Check current state of PROD-001
-- -----------------------------------------------------------------------
PRINT '--- BEFORE: dim_product for PROD-001 ---';
SELECT
    product_bk,
    product_name,
    base_interest_rate,
    dw_updated_at
FROM dw.dim_product
WHERE product_bk = 'PROD-001';
GO

-- -----------------------------------------------------------------------
-- SCENARIO: BFI Finance reduces the motor vehicle base rate
--           from 22% to 19% effective July 2024 (OJK rate guidance)
-- -----------------------------------------------------------------------
-- Simulate updated staging data from source system
UPDATE stg.product
SET
    base_interest_rate = 19.00,
    effective_date     = '2024-07-01',
    extracted_at       = SYSUTCDATETIME()
WHERE product_id = 'PROD-001';
GO

-- Re-run ETL (same MERGE as 05-etl/02-etl-dim-product.sql)
MERGE dw.dim_product AS tgt
USING (
    SELECT product_id AS product_bk, product_code, product_name,
           product_category, product_subcategory,
           min_loan_amount, max_loan_amount, min_tenor_months, max_tenor_months,
           base_interest_rate, admin_fee_pct, insurance_required, is_active,
           effective_date, source_system
    FROM stg.product
) AS src ON tgt.product_bk = src.product_bk
WHEN MATCHED AND ISNULL(tgt.base_interest_rate,0) <> ISNULL(src.base_interest_rate,0) THEN
    UPDATE SET
        tgt.base_interest_rate = src.base_interest_rate,
        tgt.effective_date     = src.effective_date,
        tgt.dw_updated_at      = SYSUTCDATETIME()
WHEN NOT MATCHED THEN
    INSERT (product_bk, product_code, product_name, base_interest_rate, dw_source_system)
    VALUES (src.product_bk, src.product_code, src.product_name, src.base_interest_rate, src.source_system);
GO

-- -----------------------------------------------------------------------
-- AFTER: Verify the overwrite
-- -----------------------------------------------------------------------
PRINT '--- AFTER: dim_product for PROD-001 (rate changed 22% → 19%) ---';
SELECT
    product_bk,
    product_name,
    base_interest_rate,
    dw_updated_at
FROM dw.dim_product
WHERE product_bk = 'PROD-001';
GO

-- -----------------------------------------------------------------------
-- KEY OBSERVATION — SCD1 consequence:
--   Loans disbursed at 22% BEFORE the change will now show 19% in reports
--   that JOIN to dim_product. The old rate is GONE from the dimension.
--   This is acceptable when the business rule says:
--     "We always want to see the current product terms, not historical."
-- -----------------------------------------------------------------------
PRINT '';
PRINT '--- NOTE: Loans before July 2024 still have interest_rate=22% in fact_loan ---';
PRINT '--- (because we stored the actual rate at origination in the fact table)     ---';
SELECT
    fl.loan_bk,
    fl.disbursed_amount,
    fl.interest_rate            AS rate_in_fact,    -- accurate historical rate
    dp.base_interest_rate       AS current_dim_rate  -- now shows 19% (overwritten)
FROM dw.fact_loan fl
JOIN dw.dim_product dp ON dp.product_sk = fl.product_sk
WHERE dp.product_bk = 'PROD-001'
ORDER BY fl.loan_bk;
GO

-- -----------------------------------------------------------------------
-- BEST PRACTICE: For rates, store the ACTUAL rate in the fact table
--                (as we do in fact_loan.interest_rate). The dimension
--                rate is just the current default.
-- -----------------------------------------------------------------------

-- Reset for clean lab state
UPDATE stg.product SET base_interest_rate = 22.00 WHERE product_id = 'PROD-001';
PRINT 'Lab reset: PROD-001 rate restored to 22%.';
GO
