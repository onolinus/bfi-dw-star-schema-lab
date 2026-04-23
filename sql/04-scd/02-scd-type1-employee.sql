-- =============================================================================
-- FILE   : 04-scd/02-scd-type1-employee.sql
-- PURPOSE: Lab exercise — SCD Type 1 on dim_employee (promotion scenario)
-- =============================================================================

USE TrainingSQL;
GO

PRINT '=== SCD TYPE 1 LAB — Employee Promotion ===';
PRINT '';

-- BEFORE
PRINT '--- BEFORE: EMP-003 ---';
SELECT employee_bk, full_name, job_title, department, branch_bk
FROM dw.dim_employee
WHERE employee_bk = 'EMP-003';
GO

-- Simulate: EMP-003 (Rizky Firmansyah) promoted to Senior Loan Officer
UPDATE stg.employee
SET
    job_title    = 'Senior Loan Officer',
    extracted_at = SYSUTCDATETIME()
WHERE employee_id = 'EMP-003';
GO

-- Re-run ETL MERGE (SCD1)
MERGE dw.dim_employee AS tgt
USING (
    SELECT employee_id AS employee_bk, nip, full_name, job_title,
           department, branch_id AS branch_bk, join_date, is_active
    FROM stg.employee
) AS src ON tgt.employee_bk = src.employee_bk
WHEN MATCHED AND ISNULL(tgt.job_title,'') <> ISNULL(src.job_title,'') THEN
    UPDATE SET
        tgt.job_title    = src.job_title,
        tgt.dw_updated_at = SYSUTCDATETIME()
WHEN NOT MATCHED THEN
    INSERT (employee_bk, nip, full_name, job_title, department, branch_bk, join_date, is_active)
    VALUES (src.employee_bk, src.nip, src.full_name, src.job_title,
            src.department, src.branch_bk, src.join_date, src.is_active);
GO

-- AFTER
PRINT '--- AFTER: EMP-003 promoted to Senior Loan Officer ---';
SELECT employee_bk, full_name, job_title, department, dw_updated_at
FROM dw.dim_employee
WHERE employee_bk = 'EMP-003';
GO

PRINT 'Result: Previous title "Loan Officer" is GONE — SCD1 overwrites in place.';
GO
