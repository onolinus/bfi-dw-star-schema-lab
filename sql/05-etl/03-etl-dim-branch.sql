-- =============================================================================
-- FILE   : 05-etl/03-etl-dim-branch.sql
-- PURPOSE: ETL: stg.branch → dw.dim_branch (SCD Type 2)
-- TARGET : SQL Server 2019/2022
-- =============================================================================

USE TrainingSQL;
GO

-- Step 1: Insert brand new branches
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
    s.manager_employee_id, s.open_date, ISNULL(s.is_active, 1),
    CAST(s.extracted_at AS DATE), '9999-12-31', 1,
    s.source_system
FROM stg.branch s
WHERE NOT EXISTS (
    SELECT 1 FROM dw.dim_branch d WHERE d.branch_bk = s.branch_id
);

PRINT 'New branches inserted: ' + CAST(@@ROWCOUNT AS VARCHAR);

-- Step 2: Expire old rows where SCD2 attributes changed
UPDATE d
SET
    d.effective_to  = CAST(DATEADD(DAY, -1, s.extracted_at) AS DATE),
    d.is_current    = 0,
    d.dw_updated_at = SYSUTCDATETIME()
FROM dw.dim_branch d
INNER JOIN stg.branch s ON d.branch_bk = s.branch_id
WHERE d.is_current = 1
  AND (
        ISNULL(d.region_code, '')    <> ISNULL(s.region_code, '')
     OR ISNULL(d.branch_tier, '')    <> ISNULL(s.branch_tier, '')
     OR ISNULL(d.address, '')        <> ISNULL(s.address, '')
     OR ISNULL(d.branch_type, '')    <> ISNULL(s.branch_type, '')
     OR ISNULL(d.kota_kabupaten, '') <> ISNULL(s.kota_kabupaten, '')
  );

PRINT 'Old branch rows expired: ' + CAST(@@ROWCOUNT AS VARCHAR);

-- Step 3: Insert new version rows for changed branches
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
    s.manager_employee_id, s.open_date, ISNULL(s.is_active, 1),
    CAST(s.extracted_at AS DATE), '9999-12-31', 1,
    s.source_system
FROM stg.branch s
WHERE EXISTS (
    SELECT 1 FROM dw.dim_branch d
    WHERE d.branch_bk = s.branch_id
      AND d.is_current = 0
      AND d.effective_to = CAST(DATEADD(DAY, -1, s.extracted_at) AS DATE)
)
AND NOT EXISTS (
    SELECT 1 FROM dw.dim_branch d
    WHERE d.branch_bk = s.branch_id AND d.is_current = 1
);

PRINT 'New branch version rows inserted: ' + CAST(@@ROWCOUNT AS VARCHAR);

-- Step 4: SCD1 update (manager assignment — no history needed)
UPDATE d
SET
    d.manager_employee_id = s.manager_employee_id,
    d.phone               = s.phone,
    d.is_active           = ISNULL(s.is_active, 1),
    d.dw_updated_at       = SYSUTCDATETIME()
FROM dw.dim_branch d
INNER JOIN stg.branch s ON d.branch_bk = s.branch_id
WHERE d.is_current = 1
  AND (
        ISNULL(d.manager_employee_id, '') <> ISNULL(s.manager_employee_id, '')
     OR ISNULL(d.phone, '')               <> ISNULL(s.phone, '')
  );

PRINT 'Branch SCD1 updates: ' + CAST(@@ROWCOUNT AS VARCHAR);
GO
