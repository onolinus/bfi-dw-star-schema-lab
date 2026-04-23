-- =============================================================================
-- FILE   : 06-analytics/02-customer-360.sql
-- PURPOSE: Customer 360 — lifetime value, risk, and repeat borrower analysis
-- =============================================================================

USE TrainingSQL;
GO

-- ============================================================
-- Q1: Customer Lifetime Value (CLV) Summary
-- ============================================================
SELECT
    dc.customer_bk,
    dc.full_name,
    dc.risk_rating,
    dc.income_bracket,
    dc.kota_kabupaten,
    dc.provinsi,
    COUNT(DISTINCT fl.loan_sk)          AS total_pinjaman,
    SUM(fl.disbursed_amount)            AS total_pokok_dipinjam,
    SUM(fl.total_payable)               AS total_kewajiban,
    SUM(fl.total_payable - fl.disbursed_amount) AS total_bunga_dibayar,
    MIN(dd.full_date)                   AS tanggal_pinjaman_pertama,
    MAX(dd.full_date)                   AS tanggal_pinjaman_terakhir,
    DATEDIFF(MONTH,
        MIN(dd.full_date),
        MAX(dd.full_date))              AS lama_menjadi_nasabah_bulan,
    -- Repeat borrower flag
    CASE WHEN COUNT(DISTINCT fl.loan_sk) > 1 THEN 'Ya' ELSE 'Tidak' END
                                        AS nasabah_berulang
FROM dw.dim_customer dc
JOIN dw.fact_loan fl ON fl.customer_sk = dc.customer_sk
JOIN dw.dim_date  dd ON dd.date_sk     = fl.disbursement_date_sk
WHERE fl.loan_status = 'DISBURSED'
  AND dc.is_current = 1
GROUP BY
    dc.customer_bk, dc.full_name, dc.risk_rating,
    dc.income_bracket, dc.kota_kabupaten, dc.provinsi
ORDER BY total_pokok_dipinjam DESC;
GO

-- ============================================================
-- Q2: Customer Payment Behavior Score
--     (based on DPD history from fact_payment)
-- ============================================================
SELECT
    dc.customer_bk,
    dc.full_name,
    dc.risk_rating                  AS risk_rating_crm,
    COUNT(fp.payment_sk)            AS total_cicilan,
    SUM(CASE WHEN fp.payment_status = 'PAID'     THEN 1 ELSE 0 END) AS cicilan_tepat_waktu,
    SUM(CASE WHEN fp.payment_status = 'OVERDUE'  THEN 1 ELSE 0 END) AS cicilan_nunggak,
    SUM(CASE WHEN fp.payment_status = 'PARTIAL'  THEN 1 ELSE 0 END) AS cicilan_sebagian,
    MAX(ISNULL(fp.dpd, 0))          AS max_dpd_sepanjang_masa,
    AVG(CAST(ISNULL(fp.dpd, 0) AS DECIMAL(8,2))) AS avg_dpd,
    -- Behavior score (simplified — higher = worse)
    CASE
        WHEN MAX(ISNULL(fp.dpd, 0)) = 0            THEN 'EXCELLENT'
        WHEN MAX(ISNULL(fp.dpd, 0)) BETWEEN 1 AND 10 THEN 'GOOD'
        WHEN MAX(ISNULL(fp.dpd, 0)) BETWEEN 11 AND 30 THEN 'FAIR'
        WHEN MAX(ISNULL(fp.dpd, 0)) BETWEEN 31 AND 90 THEN 'POOR'
        ELSE 'BAD'
    END                             AS payment_behavior_score,
    SUM(fp.penalty_amount)          AS total_denda_idr,
    SUM(fp.paid_amount)             AS total_dibayar_idr,
    SUM(fp.scheduled_amount)        AS total_tagihan_idr,
    CAST(
        SUM(fp.paid_amount) * 100.0 /
        NULLIF(SUM(fp.scheduled_amount), 0)
    AS DECIMAL(5,2))                AS collection_rate_pct
FROM dw.dim_customer dc
JOIN dw.fact_loan    fl ON fl.customer_sk = dc.customer_sk
JOIN dw.fact_payment fp ON fp.loan_sk     = fl.loan_sk
WHERE dc.is_current = 1
GROUP BY dc.customer_bk, dc.full_name, dc.risk_rating
ORDER BY max_dpd_sepanjang_masa DESC, collection_rate_pct ASC;
GO

-- ============================================================
-- Q3: Address Change History (SCD2 showcase)
--     Show customers who moved provinces
-- ============================================================
SELECT
    a.customer_bk,
    a.full_name,
    a.provinsi          AS provinsi_lama,
    a.kota_kabupaten    AS kota_lama,
    a.effective_from    AS pindah_dari,
    a.effective_to      AS pindah_hingga,
    b.provinsi          AS provinsi_baru,
    b.kota_kabupaten    AS kota_baru,
    b.effective_from    AS tanggal_pindah
FROM dw.dim_customer a
JOIN dw.dim_customer b ON b.customer_bk = a.customer_bk
    AND b.effective_from = DATEADD(DAY, 1, a.effective_to)
WHERE a.is_current = 0          -- only expired rows; prevents DATEADD overflow on 9999-12-31
  AND a.provinsi <> b.provinsi
ORDER BY b.effective_from DESC;
GO

-- ============================================================
-- Q4: High-Value Customer Segment (UPPER income, low DPD)
-- ============================================================
SELECT
    dc.customer_bk,
    dc.full_name,
    dc.income_bracket,
    dc.occupation,
    dc.kota_kabupaten,
    SUM(fl.disbursed_amount)    AS total_portfolio_idr,
    MAX(ISNULL(fp.dpd,0))       AS max_dpd,
    COUNT(DISTINCT fl.loan_sk)  AS jumlah_pinjaman_aktif
FROM dw.dim_customer dc
JOIN dw.fact_loan     fl ON fl.customer_sk = dc.customer_sk AND fl.loan_status = 'DISBURSED'
LEFT JOIN dw.fact_payment fp ON fp.loan_sk = fl.loan_sk
WHERE dc.is_current = 1
  AND dc.income_bracket = 'UPPER'
GROUP BY dc.customer_bk, dc.full_name, dc.income_bracket, dc.occupation, dc.kota_kabupaten
HAVING MAX(ISNULL(fp.dpd,0)) = 0
ORDER BY total_portfolio_idr DESC;
GO
