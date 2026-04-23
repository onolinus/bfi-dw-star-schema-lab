-- =============================================================================
-- FILE   : 02-dimensions/06-dim-collateral.sql
-- PURPOSE: Create dim_collateral as SCD Type 1 dimension
-- TARGET : SQL Server 2019/2022
-- =============================================================================

USE TrainingSQL;
GO

DROP TABLE IF EXISTS dw.dim_collateral;
GO

CREATE TABLE dw.dim_collateral (
    collateral_sk       INT             NOT NULL IDENTITY(1,1),
    collateral_bk       VARCHAR(30)     NOT NULL,
    collateral_type     VARCHAR(30)     NULL,       -- MOTOR / MOBIL / ALAT_BERAT / PROPERTI
    brand               NVARCHAR(100)   NULL,
    model               NVARCHAR(150)   NULL,
    manufacture_year    SMALLINT        NULL,
    color               NVARCHAR(50)    NULL,
    plate_number        VARCHAR(20)     NULL,
    chassis_number      VARCHAR(50)     NULL,
    engine_number       VARCHAR(50)     NULL,
    appraised_value     DECIMAL(18,2)   NULL,       -- latest appraisal (SCD1 overwrite)
    condition_rating    VARCHAR(10)     NULL,
    appraised_date      DATE            NULL,
    -- DW audit
    dw_created_at       DATETIME2       NOT NULL DEFAULT SYSUTCDATETIME(),
    dw_updated_at       DATETIME2       NOT NULL DEFAULT SYSUTCDATETIME(),
    dw_source_system    VARCHAR(50)     NOT NULL DEFAULT 'APPRAISAL',
    dw_batch_id         INT             NULL,
    CONSTRAINT PK_dim_collateral PRIMARY KEY CLUSTERED (collateral_sk)
);
GO

CREATE UNIQUE NONCLUSTERED INDEX UQ_dim_collateral_bk
    ON dw.dim_collateral (collateral_bk);
GO

-- Unknown member
SET IDENTITY_INSERT dw.dim_collateral ON;
INSERT INTO dw.dim_collateral (collateral_sk, collateral_bk, collateral_type)
VALUES (-1, 'UNKNOWN', 'UNKNOWN');
SET IDENTITY_INSERT dw.dim_collateral OFF;
GO

PRINT 'dw.dim_collateral created with SCD Type 1 structure.';
GO
