-- =============================================================================
-- FILE   : 05-etl/01-etl-dim-customer.sql
-- PURPOSE: ETL: stg.customer → dw.dim_customer (SCD Type 2)
-- TARGET : SQL Server 2019/2022
-- =============================================================================
-- ETL Pattern for SCD Type 2:
--   1. NEW records     → INSERT new row (is_current=1)
--   2. CHANGED records → expire old row + INSERT new row with new values
--   3. UNCHANGED       → no action
-- =============================================================================

USE TrainingSQL;
GO

-- ============================================================
-- STEP 1: INSERT brand new customers (never seen before)
-- ============================================================
INSERT INTO dw.dim_customer (
    customer_bk, nik, full_name, date_of_birth, gender, marital_status,
    address_line1, address_line2, kelurahan, kecamatan, kota_kabupaten,
    provinsi, kode_pos, phone_mobile, email,
    income_monthly, income_bracket, occupation, employer_name,
    risk_rating, is_blacklisted,
    effective_from, effective_to, is_current,
    dw_source_system
)
SELECT
    s.customer_id,
    s.nik,
    s.full_name,
    s.date_of_birth,
    s.gender,
    UPPER(ISNULL(s.marital_status, 'UNKNOWN')),
    s.address_line1, s.address_line2,
    s.kelurahan, s.kecamatan, s.kota_kabupaten, s.provinsi, s.kode_pos,
    s.phone_mobile, s.email,
    s.income_monthly, UPPER(ISNULL(s.income_bracket, 'UNKNOWN')),
    s.occupation, s.employer_name,
    UPPER(ISNULL(s.risk_rating, 'D')),
    ISNULL(s.is_blacklisted, 0),
    CAST(s.extracted_at AS DATE),   -- effective from today's extract
    '9999-12-31',
    1,
    s.source_system
FROM stg.customer s
WHERE NOT EXISTS (
    SELECT 1 FROM dw.dim_customer d WHERE d.customer_bk = s.customer_id
);

PRINT 'New customers inserted: ' + CAST(@@ROWCOUNT AS VARCHAR);

-- ============================================================
-- STEP 2: Expire OLD rows where SCD2 attributes have changed
-- ============================================================
-- Attributes we track historically:
--   marital_status, address (kelurahan+kota+provinsi), income_bracket, risk_rating
UPDATE d
SET
    d.effective_to  = CAST(DATEADD(DAY, -1, s.extracted_at) AS DATE),
    d.is_current    = 0,
    d.dw_updated_at = SYSUTCDATETIME()
FROM dw.dim_customer d
INNER JOIN stg.customer s ON d.customer_bk = s.customer_id
WHERE d.is_current = 1
  AND (
        ISNULL(d.marital_status, '')   <> ISNULL(UPPER(s.marital_status), '')
     OR ISNULL(d.kelurahan, '')        <> ISNULL(s.kelurahan, '')
     OR ISNULL(d.kota_kabupaten, '')   <> ISNULL(s.kota_kabupaten, '')
     OR ISNULL(d.provinsi, '')         <> ISNULL(s.provinsi, '')
     OR ISNULL(d.income_bracket, '')   <> ISNULL(UPPER(s.income_bracket), '')
     OR ISNULL(d.risk_rating, '')      <> ISNULL(UPPER(s.risk_rating), '')
  );

PRINT 'Old customer rows expired: ' + CAST(@@ROWCOUNT AS VARCHAR);

-- ============================================================
-- STEP 3: INSERT new version rows for changed customers
-- ============================================================
INSERT INTO dw.dim_customer (
    customer_bk, nik, full_name, date_of_birth, gender, marital_status,
    address_line1, address_line2, kelurahan, kecamatan, kota_kabupaten,
    provinsi, kode_pos, phone_mobile, email,
    income_monthly, income_bracket, occupation, employer_name,
    risk_rating, is_blacklisted,
    effective_from, effective_to, is_current,
    dw_source_system
)
SELECT
    s.customer_id,
    s.nik,
    s.full_name,
    s.date_of_birth,
    s.gender,
    UPPER(ISNULL(s.marital_status, 'UNKNOWN')),
    s.address_line1, s.address_line2,
    s.kelurahan, s.kecamatan, s.kota_kabupaten, s.provinsi, s.kode_pos,
    s.phone_mobile, s.email,
    s.income_monthly, UPPER(ISNULL(s.income_bracket, 'UNKNOWN')),
    s.occupation, s.employer_name,
    UPPER(ISNULL(s.risk_rating, 'D')),
    ISNULL(s.is_blacklisted, 0),
    CAST(s.extracted_at AS DATE),
    '9999-12-31',
    1,
    s.source_system
FROM stg.customer s
-- Only for customers that were just expired (is_current = 0 and expired today)
WHERE EXISTS (
    SELECT 1 FROM dw.dim_customer d
    WHERE d.customer_bk = s.customer_id
      AND d.is_current = 0
      AND d.effective_to = CAST(DATEADD(DAY, -1, s.extracted_at) AS DATE)
)
-- And no current row already exists (avoid duplicates on re-runs)
AND NOT EXISTS (
    SELECT 1 FROM dw.dim_customer d
    WHERE d.customer_bk = s.customer_id
      AND d.is_current = 1
);

PRINT 'New customer version rows inserted: ' + CAST(@@ROWCOUNT AS VARCHAR);

-- ============================================================
-- STEP 4 (SCD1 within SCD2): Update non-tracked attributes
--         on the CURRENT row without creating a new version
-- ============================================================
UPDATE d
SET
    d.phone_mobile   = s.phone_mobile,
    d.email          = s.email,
    d.is_blacklisted = ISNULL(s.is_blacklisted, 0),
    d.dw_updated_at  = SYSUTCDATETIME()
FROM dw.dim_customer d
INNER JOIN stg.customer s ON d.customer_bk = s.customer_id
WHERE d.is_current = 1
  AND (
        ISNULL(d.phone_mobile, '')   <> ISNULL(s.phone_mobile, '')
     OR ISNULL(d.email, '')          <> ISNULL(s.email, '')
     OR ISNULL(d.is_blacklisted, 0)  <> ISNULL(s.is_blacklisted, 0)
  );

PRINT 'Customer SCD1 (phone/email) updates: ' + CAST(@@ROWCOUNT AS VARCHAR);
GO
