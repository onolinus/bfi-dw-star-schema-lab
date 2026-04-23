-- =============================================================================
-- FILE   : 02-dimensions/05-dim-employee.sql
-- PURPOSE: Create dim_employee as SCD Type 1 dimension
-- TARGET : SQL Server 2019/2022
-- =============================================================================

USE TrainingSQL;
GO

DROP TABLE IF EXISTS dw.dim_employee;
GO

CREATE TABLE dw.dim_employee (
    employee_sk         INT             NOT NULL IDENTITY(1,1),
    employee_bk         VARCHAR(20)     NOT NULL,
    nip                 VARCHAR(20)     NULL,
    full_name           NVARCHAR(150)   NOT NULL,
    job_title           NVARCHAR(100)   NULL,
    department          NVARCHAR(100)   NULL,
    branch_bk           VARCHAR(20)     NULL,       -- FK to source branch (denormalized)
    branch_name         NVARCHAR(150)   NULL,       -- denormalized for query convenience
    join_date           DATE            NULL,
    is_active           BIT             NOT NULL DEFAULT 1,
    -- DW audit
    dw_created_at       DATETIME2       NOT NULL DEFAULT SYSUTCDATETIME(),
    dw_updated_at       DATETIME2       NOT NULL DEFAULT SYSUTCDATETIME(),
    dw_source_system    VARCHAR(50)     NOT NULL DEFAULT 'HRIS',
    dw_batch_id         INT             NULL,
    CONSTRAINT PK_dim_employee PRIMARY KEY CLUSTERED (employee_sk)
);
GO

CREATE UNIQUE NONCLUSTERED INDEX UQ_dim_employee_bk
    ON dw.dim_employee (employee_bk);
GO

-- Unknown member
SET IDENTITY_INSERT dw.dim_employee ON;
INSERT INTO dw.dim_employee (employee_sk, employee_bk, full_name)
VALUES (-1, 'UNKNOWN', 'Unknown Employee');
SET IDENTITY_INSERT dw.dim_employee OFF;
GO

PRINT 'dw.dim_employee created with SCD Type 1 structure.';
GO
