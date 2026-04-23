-- =============================================================================
-- FILE   : 02-dimensions/04-dim-branch.sql
-- PURPOSE: Create dim_branch as SCD Type 2 dimension
-- TARGET : SQL Server 2019/2022
-- =============================================================================
-- SCD Type 2 Tracked Changes:
--   - region_code / region_name   (branch gets re-assigned to a different region)
--   - branch_tier                 (tier upgrade/downgrade after performance review)
--   - address                     (branch relocates)
--   - branch_type                 (POS_PELAYANAN upgraded to CABANG)
-- =============================================================================

USE TrainingSQL;
GO

DROP TABLE IF EXISTS dw.dim_branch;
GO

CREATE TABLE dw.dim_branch (
    -- Surrogate key
    branch_sk           INT             NOT NULL IDENTITY(1,1),
    -- Natural / business key
    branch_bk           VARCHAR(20)     NOT NULL,
    -- Branch attributes
    branch_code         VARCHAR(10)     NOT NULL,
    branch_name         NVARCHAR(150)   NOT NULL,
    branch_type         VARCHAR(30)     NULL,       -- CABANG_UTAMA / CABANG / POS_PELAYANAN
    branch_tier         VARCHAR(10)     NULL,       -- TIER1 / TIER2 / TIER3
    -- Geography (SCD2 tracked — regional realignment happens)
    region_code         VARCHAR(10)     NULL,
    region_name         NVARCHAR(100)   NULL,
    area_code           VARCHAR(10)     NULL,
    area_name           NVARCHAR(100)   NULL,
    -- Physical address (SCD2 tracked)
    address             NVARCHAR(250)   NULL,
    kota_kabupaten      NVARCHAR(100)   NULL,
    provinsi            NVARCHAR(100)   NULL,
    phone               VARCHAR(20)     NULL,
    -- Management (SCD1 — just overwrite)
    manager_employee_id VARCHAR(20)     NULL,
    -- Status
    open_date           DATE            NULL,
    is_active           BIT             NOT NULL DEFAULT 1,
    -- SCD2 metadata
    effective_from      DATE            NOT NULL,
    effective_to        DATE            NOT NULL DEFAULT '9999-12-31',
    is_current          BIT             NOT NULL DEFAULT 1,
    -- DW audit
    dw_created_at       DATETIME2       NOT NULL DEFAULT SYSUTCDATETIME(),
    dw_updated_at       DATETIME2       NOT NULL DEFAULT SYSUTCDATETIME(),
    dw_source_system    VARCHAR(50)     NOT NULL DEFAULT 'BRANCH_MGMT',
    dw_batch_id         INT             NULL,
    CONSTRAINT PK_dim_branch PRIMARY KEY CLUSTERED (branch_sk)
);
GO

CREATE NONCLUSTERED INDEX IX_dim_branch_bk_current
    ON dw.dim_branch (branch_bk, is_current)
    INCLUDE (branch_sk);
GO

-- Unknown member
SET IDENTITY_INSERT dw.dim_branch ON;
INSERT INTO dw.dim_branch (
    branch_sk, branch_bk, branch_code, branch_name,
    effective_from, effective_to, is_current
) VALUES (-1, 'UNKNOWN', 'UNK', 'Unknown Branch', '1900-01-01', '9999-12-31', 1);
SET IDENTITY_INSERT dw.dim_branch OFF;
GO

PRINT 'dw.dim_branch created with SCD Type 2 structure.';
GO
