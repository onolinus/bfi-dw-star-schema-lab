-- =============================================================================
-- FILE   : 05-etl/04-etl-fact-loan.sql
-- PURPOSE: ETL: stg.loan_application → dw.fact_loan
-- TARGET : SQL Server 2019/2022
-- =============================================================================
-- Prerequisites: All dimensions must be loaded before running this script.
-- Pattern: MERGE on loan_bk — INSERT new, UPDATE status changes (e.g. PENDING→DISBURSED)
-- =============================================================================

USE TrainingSQL;
GO

-- -----------------------------------------------------------------------
-- Guard: ensure date_sk = 0 ("N/A") exists in dim_date.
-- Loans with NULL approval_date or disbursement_date (e.g. REJECTED status)
-- resolve to date_sk = 0. Without this row the FK constraint will reject them.
-- -----------------------------------------------------------------------
IF NOT EXISTS (SELECT 1 FROM dw.dim_date WHERE date_sk = 0)
BEGIN
    INSERT INTO dw.dim_date (
        date_sk, full_date,
        day_of_month, day_name_en, day_name_id, day_of_week, day_of_year, is_weekday,
        week_of_year, week_of_month, iso_week,
        month_number, month_name_en, month_name_id, month_year,
        quarter_number, quarter_name,
        year_number, fiscal_year, fiscal_quarter, fiscal_month,
        is_last_day_of_month, is_first_day_of_month,
        year_month_int
    ) VALUES (
        0, '1900-01-01',
        0, 'N/A', N'N/A', 0, 0, 0,
        0, 0, 0,
        0, 'N/A', N'N/A', '1900-01',
        0, 'N/A',
        1900, 1900, 0, 0,
        0, 0,
        190001
    );
    PRINT 'dim_date unknown member (date_sk=0) inserted.';
END
GO

MERGE dw.fact_loan AS tgt
USING (
    SELECT
        la.loan_id                                          AS loan_bk,
        ISNULL(dc.customer_sk, -1)                         AS customer_sk,
        ISNULL(dp.product_sk, -1)                          AS product_sk,
        ISNULL(db.branch_sk, -1)                           AS branch_sk,
        ISNULL(de.employee_sk, -1)                         AS employee_sk,
        ISNULL(dcol.collateral_sk, -1)                     AS collateral_sk,
        ISNULL(CONVERT(INT, CONVERT(VARCHAR(8), la.application_date,  112)), 0) AS application_date_sk,
        ISNULL(CONVERT(INT, CONVERT(VARCHAR(8), la.approval_date,     112)), 0) AS approval_date_sk,
        ISNULL(CONVERT(INT, CONVERT(VARCHAR(8), la.disbursement_date, 112)), 0) AS disbursement_date_sk,
        la.loan_status,
        la.requested_amount,
        la.approved_amount,
        la.disbursed_amount,
        la.admin_fee,
        la.insurance_fee,
        la.total_payable,
        la.monthly_installment,
        la.tenor_months,
        la.interest_rate
    FROM stg.loan_application la
    -- Lookup surrogate keys — join to CURRENT dimension row
    LEFT JOIN dw.dim_customer  dc   ON dc.customer_bk  = la.customer_id   AND dc.is_current = 1
    LEFT JOIN dw.dim_product   dp   ON dp.product_bk   = la.product_id
    LEFT JOIN dw.dim_branch    db   ON db.branch_bk    = la.branch_id     AND db.is_current = 1
    LEFT JOIN dw.dim_employee  de   ON de.employee_bk  = la.employee_id
    LEFT JOIN dw.dim_collateral dcol ON dcol.collateral_bk = la.collateral_id
) AS src ON tgt.loan_bk = src.loan_bk

-- UPDATE when loan status changes (e.g., PENDING → DISBURSED after approval)
WHEN MATCHED AND tgt.loan_status <> src.loan_status THEN
    UPDATE SET
        tgt.loan_status             = src.loan_status,
        tgt.approved_amount         = src.approved_amount,
        tgt.disbursed_amount        = src.disbursed_amount,
        tgt.approval_date_sk        = src.approval_date_sk,
        tgt.disbursement_date_sk    = src.disbursement_date_sk,
        tgt.monthly_installment     = src.monthly_installment,
        tgt.total_payable           = src.total_payable,
        tgt.interest_rate           = src.interest_rate,
        tgt.admin_fee               = src.admin_fee,
        tgt.insurance_fee           = src.insurance_fee,
        tgt.dw_updated_at           = SYSUTCDATETIME()

-- INSERT new loans
WHEN NOT MATCHED BY TARGET THEN
    INSERT (
        loan_bk,
        customer_sk, product_sk, branch_sk, employee_sk, collateral_sk,
        application_date_sk, approval_date_sk, disbursement_date_sk,
        loan_status,
        requested_amount, approved_amount, disbursed_amount,
        admin_fee, insurance_fee, total_payable, monthly_installment,
        tenor_months, interest_rate
    )
    VALUES (
        src.loan_bk,
        src.customer_sk, src.product_sk, src.branch_sk, src.employee_sk, src.collateral_sk,
        src.application_date_sk, src.approval_date_sk, src.disbursement_date_sk,
        src.loan_status,
        src.requested_amount, src.approved_amount, src.disbursed_amount,
        src.admin_fee, src.insurance_fee, src.total_payable, src.monthly_installment,
        src.tenor_months, src.interest_rate
    );

PRINT 'fact_loan MERGE complete. Rows affected: ' + CAST(@@ROWCOUNT AS VARCHAR);
GO
