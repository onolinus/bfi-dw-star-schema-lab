-- =============================================================================
-- FILE   : 04-scd/04-scd-type2-branch.sql
-- PURPOSE: Lab exercise — SCD Type 2 on dim_branch (regional realignment)
-- =============================================================================
-- SCENARIO: BR-012 (Tangerang) is upgraded from POS_PELAYANAN to CABANG
--           and reassigned from TIER3 to TIER2. This is a real BFI event
--           where a service point that grows sufficiently becomes a full branch.
-- =============================================================================

USE TrainingSQL;
GO

PRINT '=== SCD TYPE 2 LAB — Branch Tier Upgrade ===';
PRINT '';

-- BEFORE
PRINT '--- BEFORE: BR-012 ---';
SELECT branch_sk, branch_bk, branch_name, branch_type, branch_tier,
       effective_from, effective_to, is_current
FROM dw.dim_branch
WHERE branch_bk = 'BR-012'
ORDER BY effective_from;
GO

-- Simulate source system update: Tangerang upgraded to full CABANG TIER2
UPDATE stg.branch
SET
    branch_name  = 'BFI Cabang Tangerang',    -- renamed from "Pos Pelayanan"
    branch_type  = 'CABANG',
    branch_tier  = 'TIER2',
    extracted_at = '2024-07-01 00:00:00'
WHERE branch_id = 'BR-012';
GO

-- ETL SCD2 process
-- Step 1: Expire old row
UPDATE d
SET
    d.effective_to  = '2024-06-30',
    d.is_current    = 0,
    d.dw_updated_at = SYSUTCDATETIME()
FROM dw.dim_branch d
INNER JOIN stg.branch s ON d.branch_bk = s.branch_id
WHERE d.is_current = 1
  AND d.branch_bk = 'BR-012'
  AND (ISNULL(d.branch_tier,'') <> ISNULL(s.branch_tier,'')
    OR ISNULL(d.branch_type,'') <> ISNULL(s.branch_type,''));

PRINT 'Old branch row expired: ' + CAST(@@ROWCOUNT AS VARCHAR);

-- Step 2: Insert new version
INSERT INTO dw.dim_branch (
    branch_bk, branch_code, branch_name, branch_type, branch_tier,
    region_code, region_name, area_code, area_name,
    address, kota_kabupaten, provinsi, phone,
    manager_employee_id, open_date, is_active,
    effective_from, effective_to, is_current,
    dw_source_system
)
SELECT
    s.branch_id, s.branch_code, s.branch_name, s.branch_type, s.branch_tier,
    s.region_code, s.region_name, s.area_code, s.area_name,
    s.address, s.kota_kabupaten, s.provinsi, s.phone,
    s.manager_employee_id, s.open_date, ISNULL(s.is_active,1),
    '2024-07-01', '9999-12-31', 1,
    s.source_system
FROM stg.branch s
WHERE s.branch_id = 'BR-012'
  AND NOT EXISTS (
    SELECT 1 FROM dw.dim_branch d
    WHERE d.branch_bk = 'BR-012' AND d.is_current = 1
  );

PRINT 'New branch version inserted: ' + CAST(@@ROWCOUNT AS VARCHAR);
GO

-- AFTER
PRINT '';
PRINT '--- AFTER: BR-012 now has two rows ---';
SELECT branch_sk, branch_bk, branch_name, branch_type, branch_tier,
       effective_from, effective_to, is_current,
       CASE is_current WHEN 1 THEN '← CURRENT' ELSE '← HISTORY' END AS row_type
FROM dw.dim_branch
WHERE branch_bk = 'BR-012'
ORDER BY effective_from;
GO

PRINT '';
PRINT 'Loans originated at BR-012 BEFORE 2024-07-01 will show as POS_PELAYANAN TIER3.';
PRINT 'Loans AFTER will show as CABANG TIER2 — allowing accurate historical analysis.';
GO
