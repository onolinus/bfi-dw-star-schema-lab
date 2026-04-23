-- =============================================================================
-- FILE   : 04-scd/03-scd-type2-customer.sql
-- PURPOSE: Lab exercise — SCD Type 2 on dim_customer (address change scenario)
-- =============================================================================
-- LEARNING OBJECTIVES:
--   1. Understand that SCD Type 2 PRESERVES history via new rows
--   2. See how effective_from / effective_to / is_current work together
--   3. Query both the OLD and NEW customer address
--   4. Understand how fact rows correctly link to the RIGHT customer version
-- =============================================================================

USE TrainingSQL;
GO

PRINT '=== SCD TYPE 2 LAB — Customer Address Change ===';
PRINT '';

-- -----------------------------------------------------------------------
-- BEFORE: Check CUST-0001 (Budi Santoso) — single current row
-- -----------------------------------------------------------------------
PRINT '--- BEFORE: dim_customer for CUST-0001 ---';
SELECT
    customer_sk,
    customer_bk,
    full_name,
    kota_kabupaten,
    provinsi,
    income_bracket,
    risk_rating,
    effective_from,
    effective_to,
    is_current
FROM dw.dim_customer
WHERE customer_bk = 'CUST-0001'
ORDER BY effective_from;
GO

-- -----------------------------------------------------------------------
-- SCENARIO: Budi Santoso moves from Jakarta Pusat to Tangerang Selatan
--           AND gets upgraded from income bracket MIDDLE → UPPER
--           Extract date: 2024-08-01
-- -----------------------------------------------------------------------
UPDATE stg.customer
SET
    address_line1   = 'Jl. BSD Raya Utama No. 22',
    kelurahan       = 'Lengkong Gudang',
    kecamatan       = 'Serpong',
    kota_kabupaten  = 'Kota Tangerang Selatan',
    provinsi        = 'Banten',
    kode_pos        = '15321',
    income_monthly  = 15000000,
    income_bracket  = 'UPPER',
    extracted_at    = '2024-08-01 00:00:00'
WHERE customer_id = 'CUST-0001';
GO

-- -----------------------------------------------------------------------
-- Run SCD2 ETL for this customer
-- -----------------------------------------------------------------------

-- Step 1: Expire the old current row
UPDATE d
SET
    d.effective_to  = DATEADD(DAY, -1, '2024-08-01'),   -- 2024-07-31
    d.is_current    = 0,
    d.dw_updated_at = SYSUTCDATETIME()
FROM dw.dim_customer d
INNER JOIN stg.customer s ON d.customer_bk = s.customer_id
WHERE d.is_current = 1
  AND d.customer_bk = 'CUST-0001'
  AND (
        ISNULL(d.kota_kabupaten, '') <> ISNULL(s.kota_kabupaten, '')
     OR ISNULL(d.income_bracket, '') <> ISNULL(UPPER(s.income_bracket), '')
  );

PRINT 'Old row expired: ' + CAST(@@ROWCOUNT AS VARCHAR) + ' row(s)';

-- Step 2: Insert the new version row
INSERT INTO dw.dim_customer (
    customer_bk, nik, full_name, date_of_birth, gender, marital_status,
    address_line1, kelurahan, kecamatan, kota_kabupaten, provinsi, kode_pos,
    phone_mobile, email,
    income_monthly, income_bracket, occupation, employer_name,
    risk_rating, is_blacklisted,
    effective_from, effective_to, is_current,
    dw_source_system
)
SELECT
    s.customer_id, s.nik, s.full_name, s.date_of_birth, s.gender,
    UPPER(ISNULL(s.marital_status,'UNKNOWN')),
    s.address_line1, s.kelurahan, s.kecamatan, s.kota_kabupaten, s.provinsi, s.kode_pos,
    s.phone_mobile, s.email,
    s.income_monthly, UPPER(s.income_bracket), s.occupation, s.employer_name,
    UPPER(ISNULL(s.risk_rating,'D')), ISNULL(s.is_blacklisted,0),
    '2024-08-01', '9999-12-31', 1,
    s.source_system
FROM stg.customer s
WHERE s.customer_id = 'CUST-0001'
  AND NOT EXISTS (
    SELECT 1 FROM dw.dim_customer d
    WHERE d.customer_bk = 'CUST-0001' AND d.is_current = 1
  );

PRINT 'New version row inserted: ' + CAST(@@ROWCOUNT AS VARCHAR) + ' row(s)';
GO

-- -----------------------------------------------------------------------
-- AFTER: Two rows exist — the old and the new
-- -----------------------------------------------------------------------
PRINT '';
PRINT '--- AFTER: dim_customer for CUST-0001 (two rows = full history) ---';
SELECT
    customer_sk,
    customer_bk,
    full_name,
    kota_kabupaten,
    income_bracket,
    effective_from,
    effective_to,
    is_current,
    CASE is_current WHEN 1 THEN '← CURRENT' ELSE '← HISTORY' END AS row_type
FROM dw.dim_customer
WHERE customer_bk = 'CUST-0001'
ORDER BY effective_from;
GO

-- -----------------------------------------------------------------------
-- DEMONSTRATION: Point-in-time query
--   "What was Budi's address when he took his loan in January 2023?"
-- -----------------------------------------------------------------------
PRINT '';
PRINT '--- Point-in-Time: What address was active on 2023-01-15? ---';
SELECT
    dc.customer_sk,
    dc.full_name,
    dc.kota_kabupaten           AS address_at_loan_time,
    dc.income_bracket           AS bracket_at_loan_time,
    dc.effective_from,
    dc.effective_to
FROM dw.dim_customer dc
WHERE dc.customer_bk = 'CUST-0001'
  AND '2023-01-15' BETWEEN dc.effective_from AND dc.effective_to;
GO

-- -----------------------------------------------------------------------
-- DEMONSTRATION: How fact_loan links to the correct customer version
-- -----------------------------------------------------------------------
PRINT '';
PRINT '--- Fact join: loan from 2023 links to OLD address (Jakarta Pusat) ---';
SELECT
    fl.loan_bk,
    fl.disbursement_date_sk,
    dc.full_name,
    dc.kota_kabupaten       AS customer_city_at_disbursement,
    dc.effective_from,
    dc.effective_to,
    dc.is_current
FROM dw.fact_loan fl
JOIN dw.dim_customer dc ON dc.customer_sk = fl.customer_sk
WHERE fl.loan_bk = 'LOS-2023-000001';
GO

PRINT '';
PRINT 'KEY INSIGHT: fact_loan.customer_sk was set at load time when the OLD sk was current.';
PRINT 'A new loan for CUST-0001 after 2024-08-01 would link to the NEW sk (Tangerang Selatan).';
GO
