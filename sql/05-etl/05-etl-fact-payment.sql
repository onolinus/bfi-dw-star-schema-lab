-- =============================================================================
-- FILE   : 05-etl/05-etl-fact-payment.sql
-- PURPOSE: ETL: stg.payment → dw.fact_payment
-- TARGET : SQL Server 2019/2022
-- =============================================================================

USE TrainingSQL;
GO

-- Guard: ensure date_sk = 0 ("N/A") exists for unpaid installments (payment_date = NULL)
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

MERGE dw.fact_payment AS tgt
USING (
    SELECT
        p.payment_id                                            AS payment_bk,
        ISNULL(fl.loan_sk, -1)                                  AS loan_sk,
        ISNULL(dc.customer_sk, -1)                              AS customer_sk,
        ISNULL(db.branch_sk, -1)                                AS branch_sk,
        ISNULL(CONVERT(INT, CONVERT(VARCHAR(8), p.due_date,     112)), 0) AS due_date_sk,
        ISNULL(CONVERT(INT, CONVERT(VARCHAR(8), p.payment_date, 112)), 0) AS payment_date_sk,
        p.installment_number,
        p.payment_status,
        p.payment_method,
        p.payment_channel,
        p.scheduled_amount,
        ISNULL(p.paid_amount, 0)                                AS paid_amount,
        ISNULL(p.penalty_amount, 0)                             AS penalty_amount,
        ISNULL(p.waiver_amount, 0)                              AS waiver_amount,
        p.dpd,
        -- OJK Collectibility grade derived from DPD
        CASE
            WHEN p.dpd IS NULL OR p.dpd = 0      THEN 1
            WHEN p.dpd BETWEEN 1  AND 90         THEN 2
            WHEN p.dpd BETWEEN 91 AND 120        THEN 3
            WHEN p.dpd BETWEEN 121 AND 180       THEN 4
            ELSE 5
        END                                                     AS collectibility_grade,
        CASE
            WHEN p.dpd IS NULL OR p.dpd = 0      THEN N'Lancar'
            WHEN p.dpd BETWEEN 1  AND 90         THEN N'Dalam Perhatian Khusus'
            WHEN p.dpd BETWEEN 91 AND 120        THEN N'Kurang Lancar'
            WHEN p.dpd BETWEEN 121 AND 180       THEN N'Diragukan'
            ELSE N'Macet'
        END                                                     AS collectibility_label,
        p.collector_employee_id
    FROM stg.payment p
    LEFT JOIN dw.fact_loan      fl ON fl.loan_bk    = p.loan_id
    LEFT JOIN dw.dim_customer   dc ON dc.customer_bk = p.customer_id AND dc.is_current = 1
    LEFT JOIN dw.dim_branch     db ON db.branch_bk   = p.branch_id  AND db.is_current = 1
) AS src ON tgt.payment_bk = src.payment_bk

-- UPDATE when payment status changes (OVERDUE → PAID after late payment arrives)
WHEN MATCHED AND (
       tgt.payment_status  <> src.payment_status
    OR tgt.paid_amount     <> src.paid_amount
    OR tgt.penalty_amount  <> src.penalty_amount
) THEN
    UPDATE SET
        tgt.payment_status          = src.payment_status,
        tgt.payment_date_sk         = src.payment_date_sk,
        tgt.paid_amount             = src.paid_amount,
        tgt.penalty_amount          = src.penalty_amount,
        tgt.waiver_amount           = src.waiver_amount,
        tgt.dpd                     = src.dpd,
        tgt.collectibility_grade    = src.collectibility_grade,
        tgt.collectibility_label    = src.collectibility_label,
        tgt.dw_updated_at           = SYSUTCDATETIME()

WHEN NOT MATCHED BY TARGET THEN
    INSERT (
        payment_bk, loan_sk, customer_sk, branch_sk,
        due_date_sk, payment_date_sk,
        installment_number, payment_status, payment_method, payment_channel,
        scheduled_amount, paid_amount, penalty_amount, waiver_amount,
        dpd, collectibility_grade, collectibility_label,
        collector_employee_id
    )
    VALUES (
        src.payment_bk, src.loan_sk, src.customer_sk, src.branch_sk,
        src.due_date_sk, src.payment_date_sk,
        src.installment_number, src.payment_status, src.payment_method, src.payment_channel,
        src.scheduled_amount, src.paid_amount, src.penalty_amount, src.waiver_amount,
        src.dpd, src.collectibility_grade, src.collectibility_label,
        src.collector_employee_id
    );

PRINT 'fact_payment MERGE complete. Rows affected: ' + CAST(@@ROWCOUNT AS VARCHAR);
GO
