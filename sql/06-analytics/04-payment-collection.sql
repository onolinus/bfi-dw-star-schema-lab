-- =============================================================================
-- FILE   : 06-analytics/04-payment-collection.sql
-- PURPOSE: Payment collection analysis — DPD aging, OJK collectibility, NPL
-- =============================================================================

USE TrainingSQL;
GO

-- ============================================================
-- Q1: DPD Aging Bucket Analysis (OJK Collectibility)
-- ============================================================
SELECT
    fp.collectibility_grade                 AS kolektibilitas,
    fp.collectibility_label                 AS keterangan,
    dp.product_category                     AS kategori_produk,
    COUNT(DISTINCT fl.loan_sk)              AS jumlah_kontrak,
    SUM(fp.scheduled_amount)                AS total_tagihan_idr,
    SUM(fp.paid_amount)                     AS total_terbayar_idr,
    SUM(fp.scheduled_amount - fp.paid_amount) AS total_tunggakan_idr,
    CAST(
        SUM(fp.paid_amount) * 100.0 /
        NULLIF(SUM(fp.scheduled_amount), 0)
    AS DECIMAL(5,2))                        AS collection_rate_pct
FROM dw.fact_payment fp
JOIN dw.fact_loan    fl ON fl.loan_sk    = fp.loan_sk
JOIN dw.dim_product  dp ON dp.product_sk = fl.product_sk
GROUP BY fp.collectibility_grade, fp.collectibility_label, dp.product_category
ORDER BY fp.collectibility_grade, dp.product_category;
GO

-- ============================================================
-- Q2: Overdue Aging Report (DPD Buckets) — Current Snapshot
-- ============================================================
SELECT
    CASE
        WHEN fp.dpd IS NULL OR fp.dpd = 0  THEN '00 — Lancar (0 hari)'
        WHEN fp.dpd BETWEEN 1   AND 30     THEN '01 — DPK Ringan (1-30)'
        WHEN fp.dpd BETWEEN 31  AND 60     THEN '02 — DPK Sedang (31-60)'
        WHEN fp.dpd BETWEEN 61  AND 90     THEN '03 — DPK Berat (61-90)'
        WHEN fp.dpd BETWEEN 91  AND 120    THEN '04 — Kurang Lancar (91-120)'
        WHEN fp.dpd BETWEEN 121 AND 180    THEN '05 — Diragukan (121-180)'
        ELSE                                    '06 — Macet (>180)'
    END                                     AS aging_bucket,
    db.region_name,
    COUNT(DISTINCT fl.loan_sk)              AS jumlah_kontrak,
    COUNT(fp.payment_sk)                    AS jumlah_cicilan,
    SUM(fp.scheduled_amount - fp.paid_amount) AS outstanding_tunggakan_idr,
    SUM(fp.penalty_amount)                  AS total_denda_idr
FROM dw.fact_payment fp
JOIN dw.fact_loan    fl ON fl.loan_sk   = fp.loan_sk
JOIN dw.dim_branch   db ON db.branch_sk = fl.branch_sk AND db.is_current = 1
WHERE fp.payment_status IN ('OVERDUE','PARTIAL')
GROUP BY
    CASE
        WHEN fp.dpd IS NULL OR fp.dpd = 0  THEN '00 — Lancar (0 hari)'
        WHEN fp.dpd BETWEEN 1   AND 30     THEN '01 — DPK Ringan (1-30)'
        WHEN fp.dpd BETWEEN 31  AND 60     THEN '02 — DPK Sedang (31-60)'
        WHEN fp.dpd BETWEEN 61  AND 90     THEN '03 — DPK Berat (61-90)'
        WHEN fp.dpd BETWEEN 91  AND 120    THEN '04 — Kurang Lancar (91-120)'
        WHEN fp.dpd BETWEEN 121 AND 180    THEN '05 — Diragukan (121-180)'
        ELSE                                    '06 — Macet (>180)'
    END,
    db.region_name
ORDER BY aging_bucket, db.region_name;
GO

-- ============================================================
-- Q3: Payment Channel Efficiency
-- ============================================================
SELECT
    fp.payment_channel                  AS saluran_pembayaran,
    fp.payment_method                   AS metode_pembayaran,
    COUNT(fp.payment_sk)                AS jumlah_transaksi,
    SUM(fp.paid_amount)                 AS total_nilai_idr,
    AVG(CAST(ISNULL(fp.dpd,0) AS DECIMAL(8,2))) AS avg_dpd,
    SUM(CASE WHEN fp.payment_status = 'PAID' THEN 1 ELSE 0 END) AS bayar_lunas,
    SUM(CASE WHEN fp.payment_status = 'PARTIAL' THEN 1 ELSE 0 END) AS bayar_sebagian
FROM dw.fact_payment fp
WHERE fp.payment_channel IS NOT NULL
GROUP BY fp.payment_channel, fp.payment_method
ORDER BY jumlah_transaksi DESC;
GO

-- ============================================================
-- Q4: Monthly Collection Trend
-- ============================================================
SELECT
    dd.year_number          AS tahun,
    dd.month_number         AS bulan,
    dd.month_name_id        AS nama_bulan,
    SUM(fp.scheduled_amount)AS total_tagihan_idr,
    SUM(fp.paid_amount)     AS total_terbayar_idr,
    SUM(fp.penalty_amount)  AS total_denda_idr,
    SUM(fp.waiver_amount)   AS total_keringanan_idr,
    CAST(
        SUM(fp.paid_amount) * 100.0 /
        NULLIF(SUM(fp.scheduled_amount), 0)
    AS DECIMAL(5,2))        AS collection_rate_pct,
    COUNT(CASE WHEN fp.payment_status = 'OVERDUE' THEN 1 END) AS cicilan_nunggak
FROM dw.fact_payment fp
JOIN dw.dim_date dd ON dd.date_sk = fp.due_date_sk
WHERE dd.year_number >= 2023
GROUP BY dd.year_number, dd.month_number, dd.month_name_id
ORDER BY dd.year_number, dd.month_number;
GO

-- ============================================================
-- Q5: Watch List — Contracts with DPD > 30 (Collection Priority)
-- ============================================================
SELECT
    fl.loan_bk                  AS nomor_kontrak,
    dc.full_name                AS nama_nasabah,
    dc.phone_mobile             AS telepon,
    dc.kota_kabupaten           AS kota,
    dp.product_name             AS produk,
    db.branch_name              AS cabang,
    fl.disbursed_amount         AS pokok_pinjaman_idr,
    fl.monthly_installment      AS cicilan_bulanan_idr,
    MAX(fp.dpd)                 AS dpd_tertinggi,
    MAX(fp.collectibility_grade)AS kolektibilitas,
    MAX(fp.collectibility_label)AS keterangan_kolektibilitas,
    COUNT(CASE WHEN fp.payment_status IN ('OVERDUE','PARTIAL') THEN 1 END) AS jumlah_cicilan_bermasalah,
    SUM(CASE WHEN fp.payment_status IN ('OVERDUE','PARTIAL')
             THEN fp.scheduled_amount - fp.paid_amount
             ELSE 0 END)        AS total_tunggakan_idr
FROM dw.fact_loan fl
JOIN dw.dim_customer dc ON dc.customer_sk = fl.customer_sk AND dc.is_current = 1
JOIN dw.dim_product  dp ON dp.product_sk  = fl.product_sk
JOIN dw.dim_branch   db ON db.branch_sk   = fl.branch_sk   AND db.is_current = 1
JOIN dw.fact_payment fp ON fp.loan_sk     = fl.loan_sk
WHERE fl.loan_status = 'DISBURSED'
GROUP BY
    fl.loan_bk, dc.full_name, dc.phone_mobile, dc.kota_kabupaten,
    dp.product_name, db.branch_name, fl.disbursed_amount, fl.monthly_installment
HAVING MAX(fp.dpd) > 30
ORDER BY MAX(fp.dpd) DESC, total_tunggakan_idr DESC;
GO
