-- =============================================================================
-- FILE   : 06-analytics/01-loan-portfolio-analysis.sql
-- PURPOSE: Loan portfolio analysis queries for management reporting
-- TARGET : SQL Server 2019/2022 | Power BI / SSRS compatible
-- =============================================================================

USE TrainingSQL;
GO

-- ============================================================
-- Q1: Monthly Loan Origination Summary (Volume & Value)
-- ============================================================
SELECT
    dd.year_number                          AS tahun,
    dd.month_number                         AS bulan,
    dd.month_name_id                        AS nama_bulan,
    dp.product_category                     AS kategori_produk,
    COUNT(fl.loan_sk)                       AS jumlah_pengajuan,
    COUNT(CASE WHEN fl.loan_status = 'DISBURSED' THEN 1 END) AS jumlah_cair,
    SUM(CASE WHEN fl.loan_status = 'DISBURSED' THEN fl.disbursed_amount ELSE 0 END)
                                            AS total_pencairan_idr,
    AVG(CASE WHEN fl.loan_status = 'DISBURSED' THEN fl.disbursed_amount END)
                                            AS rata2_pencairan_idr,
    AVG(CASE WHEN fl.loan_status = 'DISBURSED' THEN fl.interest_rate END)
                                            AS rata2_suku_bunga_pct,
    -- Approval rate
    CAST(
        COUNT(CASE WHEN fl.loan_status IN ('DISBURSED','APPROVED') THEN 1 END) * 100.0
        / NULLIF(COUNT(fl.loan_sk), 0)
    AS DECIMAL(5,2))                        AS approval_rate_pct
FROM dw.fact_loan fl
JOIN dw.dim_date     dd ON dd.date_sk     = fl.application_date_sk
JOIN dw.dim_product  dp ON dp.product_sk  = fl.product_sk
WHERE dd.year_number >= 2023
GROUP BY
    dd.year_number, dd.month_number, dd.month_name_id, dp.product_category
ORDER BY
    dd.year_number, dd.month_number, dp.product_category;
GO

-- ============================================================
-- Q2: Loan Portfolio by Branch — Current Outstanding
-- ============================================================
SELECT
    db.region_name                          AS wilayah,
    db.branch_name                          AS cabang,
    db.branch_tier,
    COUNT(fl.loan_sk)                       AS total_kontrak,
    SUM(fl.disbursed_amount)                AS total_pokok_idr,
    SUM(fl.total_payable)                   AS total_kewajiban_idr,
    AVG(fl.tenor_months)                    AS rata2_tenor_bulan,
    AVG(fl.interest_rate)                   AS rata2_bunga_pct
FROM dw.fact_loan fl
JOIN dw.dim_branch db ON db.branch_sk = fl.branch_sk AND db.is_current = 1
WHERE fl.loan_status = 'DISBURSED'
GROUP BY db.region_name, db.branch_name, db.branch_tier
ORDER BY SUM(fl.disbursed_amount) DESC;
GO

-- ============================================================
-- Q3: Product Mix Analysis (Current Year vs Prior Year)
-- ============================================================
WITH yearly_volume AS (
    SELECT
        dp.product_category,
        dp.product_name,
        dd.year_number,
        COUNT(fl.loan_sk)           AS jumlah_kontrak,
        SUM(fl.disbursed_amount)    AS total_nilai_idr
    FROM dw.fact_loan fl
    JOIN dw.dim_product dp ON dp.product_sk = fl.product_sk
    JOIN dw.dim_date    dd ON dd.date_sk    = fl.disbursement_date_sk
    WHERE fl.loan_status = 'DISBURSED'
      AND dd.year_number IN (2023, 2024)
    GROUP BY dp.product_category, dp.product_name, dd.year_number
)
SELECT
    product_category,
    product_name,
    MAX(CASE WHEN year_number = 2023 THEN jumlah_kontrak END)   AS kontrak_2023,
    MAX(CASE WHEN year_number = 2024 THEN jumlah_kontrak END)   AS kontrak_2024,
    MAX(CASE WHEN year_number = 2023 THEN total_nilai_idr END)  AS nilai_2023_idr,
    MAX(CASE WHEN year_number = 2024 THEN total_nilai_idr END)  AS nilai_2024_idr,
    CAST(
        (MAX(CASE WHEN year_number = 2024 THEN total_nilai_idr END) -
         MAX(CASE WHEN year_number = 2023 THEN total_nilai_idr END)) * 100.0 /
        NULLIF(MAX(CASE WHEN year_number = 2023 THEN total_nilai_idr END), 0)
    AS DECIMAL(8,2))                                             AS growth_pct
FROM yearly_volume
GROUP BY product_category, product_name
ORDER BY nilai_2024_idr DESC;
GO

-- ============================================================
-- Q4: Top 10 Loan Officers by Disbursement Value (2024)
-- ============================================================
SELECT TOP 10
    de.full_name                            AS nama_loan_officer,
    de.job_title,
    db.branch_name                          AS cabang,
    COUNT(fl.loan_sk)                       AS total_kontrak,
    SUM(fl.disbursed_amount)                AS total_pencairan_idr,
    AVG(fl.disbursed_amount)                AS rata2_per_kontrak,
    AVG(fl.interest_rate)                   AS rata2_bunga_pct
FROM dw.fact_loan fl
JOIN dw.dim_employee de ON de.employee_sk = fl.employee_sk
JOIN dw.dim_branch   db ON db.branch_sk   = fl.branch_sk AND db.is_current = 1
JOIN dw.dim_date     dd ON dd.date_sk     = fl.disbursement_date_sk
WHERE fl.loan_status = 'DISBURSED'
  AND dd.year_number = 2024
GROUP BY de.full_name, de.job_title, db.branch_name
ORDER BY total_pencairan_idr DESC;
GO

-- ============================================================
-- Q5: Tenor Distribution (for Asset-Liability Management)
-- ============================================================
SELECT
    dp.product_category,
    CASE
        WHEN fl.tenor_months <= 12  THEN '01 — ≤ 12 bulan'
        WHEN fl.tenor_months <= 24  THEN '02 — 13-24 bulan'
        WHEN fl.tenor_months <= 36  THEN '03 — 25-36 bulan'
        WHEN fl.tenor_months <= 48  THEN '04 — 37-48 bulan'
        WHEN fl.tenor_months <= 60  THEN '05 — 49-60 bulan'
        ELSE                             '06 — > 60 bulan'
    END                                     AS tenor_bucket,
    COUNT(fl.loan_sk)                       AS jumlah_kontrak,
    SUM(fl.disbursed_amount)                AS total_nilai_idr,
    CAST(
        SUM(fl.disbursed_amount) * 100.0 /
        NULLIF(SUM(SUM(fl.disbursed_amount)) OVER (PARTITION BY dp.product_category), 0)
    AS DECIMAL(5,2))                        AS pct_dari_kategori
FROM dw.fact_loan fl
JOIN dw.dim_product dp ON dp.product_sk = fl.product_sk
WHERE fl.loan_status = 'DISBURSED'
GROUP BY dp.product_category, fl.tenor_months
ORDER BY dp.product_category, tenor_bucket;
GO
