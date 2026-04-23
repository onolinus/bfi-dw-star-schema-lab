-- =============================================================================
-- FILE   : 05-etl/02-etl-dim-product.sql
-- PURPOSE: ETL: stg.product → dw.dim_product (SCD Type 1 via MERGE)
-- TARGET : SQL Server 2019/2022
-- =============================================================================

USE TrainingSQL;
GO

MERGE dw.dim_product AS tgt
USING (
    SELECT
        product_id          AS product_bk,
        product_code,
        product_name,
        product_category,
        product_subcategory,
        min_loan_amount,
        max_loan_amount,
        min_tenor_months,
        max_tenor_months,
        base_interest_rate,
        admin_fee_pct,
        insurance_required,
        is_active,
        effective_date,
        source_system
    FROM stg.product
) AS src ON tgt.product_bk = src.product_bk

-- SCD Type 1: UPDATE existing row (overwrite all attributes)
WHEN MATCHED AND (
       ISNULL(tgt.product_name, '')         <> ISNULL(src.product_name, '')
    OR ISNULL(tgt.base_interest_rate, 0)    <> ISNULL(src.base_interest_rate, 0)
    OR ISNULL(tgt.admin_fee_pct, 0)         <> ISNULL(src.admin_fee_pct, 0)
    OR ISNULL(tgt.is_active, 1)             <> ISNULL(src.is_active, 1)
    OR ISNULL(tgt.min_loan_amount, 0)       <> ISNULL(src.min_loan_amount, 0)
    OR ISNULL(tgt.max_loan_amount, 0)       <> ISNULL(src.max_loan_amount, 0)
) THEN
    UPDATE SET
        tgt.product_code        = src.product_code,
        tgt.product_name        = src.product_name,
        tgt.product_category    = src.product_category,
        tgt.product_subcategory = src.product_subcategory,
        tgt.min_loan_amount     = src.min_loan_amount,
        tgt.max_loan_amount     = src.max_loan_amount,
        tgt.min_tenor_months    = src.min_tenor_months,
        tgt.max_tenor_months    = src.max_tenor_months,
        tgt.base_interest_rate  = src.base_interest_rate,
        tgt.admin_fee_pct       = src.admin_fee_pct,
        tgt.insurance_required  = src.insurance_required,
        tgt.is_active           = src.is_active,
        tgt.effective_date      = src.effective_date,
        tgt.dw_updated_at       = SYSUTCDATETIME(),
        tgt.dw_source_system    = src.source_system

-- INSERT new products
WHEN NOT MATCHED BY TARGET THEN
    INSERT (
        product_bk, product_code, product_name, product_category, product_subcategory,
        min_loan_amount, max_loan_amount, min_tenor_months, max_tenor_months,
        base_interest_rate, admin_fee_pct, insurance_required, is_active, effective_date,
        dw_source_system
    )
    VALUES (
        src.product_bk, src.product_code, src.product_name, src.product_category, src.product_subcategory,
        src.min_loan_amount, src.max_loan_amount, src.min_tenor_months, src.max_tenor_months,
        src.base_interest_rate, src.admin_fee_pct, src.insurance_required, src.is_active, src.effective_date,
        src.source_system
    );

PRINT 'dim_product MERGE complete. Rows affected: ' + CAST(@@ROWCOUNT AS VARCHAR);
GO
