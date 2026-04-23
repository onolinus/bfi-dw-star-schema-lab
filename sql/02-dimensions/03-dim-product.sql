-- =============================================================================
-- FILE   : 02-dimensions/03-dim-product.sql
-- PURPOSE: Create dim_product as SCD Type 1 dimension
-- TARGET : SQL Server 2019/2022
-- =============================================================================
-- SCD Type 1 Design:
--   - All changes OVERWRITE the existing record (no history kept)
--   - Suitable for attributes where historical accuracy is not required:
--     interest rates, fees, product descriptions
--   - The ETL MERGE will UPDATE on change, no new rows created
-- =============================================================================

USE TrainingSQL;
GO

DROP TABLE IF EXISTS dw.dim_product;
GO

CREATE TABLE dw.dim_product (
    -- Surrogate key
    product_sk          INT             NOT NULL IDENTITY(1,1),
    -- Natural / business key
    product_bk          VARCHAR(20)     NOT NULL,   -- maps to stg.product.product_id
    -- Product attributes
    product_code        VARCHAR(20)     NOT NULL,
    product_name        NVARCHAR(150)   NOT NULL,
    product_category    VARCHAR(50)     NULL,       -- MOTOR_VEHICLE / HEAVY_EQUIPMENT / PROPERTY / CONSUMER
    product_subcategory VARCHAR(50)     NULL,
    -- Lending parameters (SCD1 — rates change, history not needed in this dim)
    min_loan_amount     DECIMAL(18,2)   NULL,
    max_loan_amount     DECIMAL(18,2)   NULL,
    min_tenor_months    SMALLINT        NULL,
    max_tenor_months    SMALLINT        NULL,
    base_interest_rate  DECIMAL(8,4)    NULL,       -- annual %
    admin_fee_pct       DECIMAL(8,4)    NULL,
    insurance_required  BIT             NULL,
    -- Status
    is_active           BIT             NOT NULL DEFAULT 1,
    effective_date      DATE            NULL,       -- date this product was launched
    -- DW audit
    dw_created_at       DATETIME2       NOT NULL DEFAULT SYSUTCDATETIME(),
    dw_updated_at       DATETIME2       NOT NULL DEFAULT SYSUTCDATETIME(),
    dw_source_system    VARCHAR(50)     NOT NULL DEFAULT 'PRODUCT_MGMT',
    dw_batch_id         INT             NULL,
    CONSTRAINT PK_dim_product PRIMARY KEY CLUSTERED (product_sk)
);
GO

CREATE UNIQUE NONCLUSTERED INDEX UQ_dim_product_bk
    ON dw.dim_product (product_bk);
GO

-- Unknown member
SET IDENTITY_INSERT dw.dim_product ON;
INSERT INTO dw.dim_product (product_sk, product_bk, product_code, product_name)
VALUES (-1, 'UNKNOWN', 'UNK', 'Unknown Product');
SET IDENTITY_INSERT dw.dim_product OFF;
GO

PRINT 'dw.dim_product created with SCD Type 1 structure.';
GO
