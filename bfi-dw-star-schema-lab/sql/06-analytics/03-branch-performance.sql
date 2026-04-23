-- =============================================================================
-- FILE   : 06-analytics/03-branch-performance.sql
-- PURPOSE: Branch performance scorecard — origination, NPL, collection rate
-- =============================================================================

USE TrainingSQL;
GO

-- ============================================================
-- Q1: Branch Monthly Scorecard
-- ============================================================
SELECT
    dd.year_number                      AS tahun,
    dd.quarter_name                     AS kuartal,
    dd.month_name_id                    AS bulan,
    db.region_name                      AS wilayah,
    db.branch_name                      AS cabang,
    db.branch_tier,
    -- Origination
    COUNT(fl.loan_sk)                   AS jumlah_kontrak_baru,
    SUM(fl.disbursed_amount)            AS nominal_pencairan_idr,
    -- Installment revenue
    SUM(fp.scheduled_amount)            AS total_tagihan_idr,
    SUM(fp.paid_amount)                 AS total_terbayar_idr,
    SUM(fp.penalty_amount)              AS total_denda_idr,
    -- Collection rate
    CAST(
        SUM(fp.paid_amount) * 100.0 /
        NULLIF(SUM(fp.scheduled_amount), 0)
    AS DECIMAL(5,2))                    AS collection_rate_pct,
    -- NPL proxy: contracts with any DPD > 90
    COUNT(DISTINCT CASE WHEN fp.dpd > 90 THEN fl.loan_sk END) AS kontrak_npl,
    CAST(
        COUNT(DISTINCT CASE WHEN fp.dpd > 90 THEN fl.loan_sk END) * 100.0 /
        NULLIF(COUNT(DISTINCT fl.loan_sk), 0)
    AS DECIMAL(5,2))                    AS npl_rate_pct
FROM dw.fact_loan fl
JOIN dw.dim_branch   db ON db.branch_sk = fl.branch_sk AND db.is_current = 1
JOIN dw.dim_date     dd ON dd.date_sk   = fl.disbursement_date_sk
LEFT JOIN dw.fact_payment fp ON fp.loan_sk = fl.loan_sk
WHERE fl.loan_status = 'DISBURSED'
  AND dd.year_number >= 2023
GROUP BY
    dd.year_number, dd.quarter_name, dd.month_number, dd.month_name_id,
    db.region_name, db.branch_name, db.branch_tier
ORDER BY
    dd.year_number, dd.month_number, db.region_name, db.branch_name;
GO

-- ============================================================
-- Q2: Branch Ranking by NPL Rate (Current Period)
-- ============================================================
WITH branch_npl AS (
    SELECT
        db.branch_name,
        db.region_name,
        db.branch_tier,
        COUNT(DISTINCT fl.loan_sk)                              AS total_kontrak,
        COUNT(DISTINCT CASE WHEN fp.dpd > 90 THEN fl.loan_sk END) AS kontrak_npl,
        SUM(fl.disbursed_amount)                                AS outstanding_idr,
        SUM(CASE WHEN fp.dpd > 90 THEN fl.disbursed_amount ELSE 0 END) AS npl_idr
    FROM dw.fact_loan fl
    JOIN dw.dim_branch   db ON db.branch_sk = fl.branch_sk AND db.is_current = 1
    LEFT JOIN dw.fact_payment fp ON fp.loan_sk = fl.loan_sk AND fp.payment_date_sk = 0  -- unpaid
    WHERE fl.loan_status = 'DISBURSED'
    GROUP BY db.branch_name, db.region_name, db.branch_tier
)
SELECT
    RANK() OVER (ORDER BY CAST(npl_idr * 100.0 / NULLIF(outstanding_idr,0) AS DECIMAL(5,2))) AS rank_npl,
    branch_name,
    region_name,
    branch_tier,
    total_kontrak,
    kontrak_npl,
    outstanding_idr,
    npl_idr,
    CAST(npl_idr * 100.0 / NULLIF(outstanding_idr, 0) AS DECIMAL(5,2)) AS npl_rate_pct
FROM branch_npl
ORDER BY npl_rate_pct;
GO

-- ============================================================
-- Q3: Historical vs Current Branch Performance (SCD2 showcase)
--     Compare BR-012 performance BEFORE and AFTER tier upgrade
-- ============================================================
SELECT
    db.branch_name,
    db.branch_tier,
    db.effective_from       AS tier_berlaku_sejak,
    db.effective_to         AS tier_berlaku_hingga,
    COUNT(fl.loan_sk)       AS total_kontrak,
    SUM(fl.disbursed_amount)AS total_nilai_idr
FROM dw.fact_loan fl
JOIN dw.dim_branch db ON db.branch_sk = fl.branch_sk
WHERE db.branch_bk = 'BR-012'
GROUP BY db.branch_name, db.branch_tier, db.effective_from, db.effective_to
ORDER BY db.effective_from;
GO
