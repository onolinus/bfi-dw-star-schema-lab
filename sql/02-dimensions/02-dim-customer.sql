-- =============================================================================
-- FILE   : 02-dimensions/02-dim-customer.sql
-- PURPOSE: Create dim_customer as SCD Type 2 dimension
-- TARGET : SQL Server 2019/2022
-- =============================================================================
-- SCD Type 2 Design:
--   - Surrogate key (customer_sk) is the PK — never changes
--   - Natural key (customer_bk) links back to the source system
--   - Effective/expiry dates track the validity window of each version
--   - is_current flag = 1 for the active record (for simpler queries)
--   - Tracked attributes (changes create a new row):
--       address_*, income_monthly, income_bracket, marital_status, risk_rating
-- =============================================================================

USE TrainingSQL;
GO

DROP TABLE IF EXISTS dw.dim_customer;
GO

CREATE TABLE dw.dim_customer (
    -- Surrogate key
    customer_sk         INT             NOT NULL IDENTITY(1,1),
    -- Natural / business key
    customer_bk         VARCHAR(20)     NOT NULL,   -- maps to stg.customer.customer_id
    -- Customer attributes
    nik                 CHAR(16)        NULL,
    full_name           NVARCHAR(150)   NOT NULL,
    date_of_birth       DATE            NULL,
    gender              CHAR(1)         NULL,
    marital_status      VARCHAR(20)     NULL,       -- LAJANG / MENIKAH / CERAI
    -- Address (SCD2 tracked — home address changes are common)
    address_line1       NVARCHAR(200)   NULL,
    address_line2       NVARCHAR(200)   NULL,
    kelurahan           NVARCHAR(100)   NULL,
    kecamatan           NVARCHAR(100)   NULL,
    kota_kabupaten      NVARCHAR(100)   NULL,
    provinsi            NVARCHAR(100)   NULL,
    kode_pos            VARCHAR(10)     NULL,
    -- Contact (SCD1 — overwrite, not tracked historically)
    phone_mobile        VARCHAR(20)     NULL,
    email               VARCHAR(150)    NULL,
    -- Financial profile (SCD2 tracked)
    income_monthly      DECIMAL(18,2)   NULL,
    income_bracket      VARCHAR(20)     NULL,       -- LOW / MIDDLE / UPPER
    occupation          NVARCHAR(100)   NULL,
    employer_name       NVARCHAR(150)   NULL,
    -- Risk (SCD2 tracked)
    risk_rating         VARCHAR(10)     NULL,       -- A / B / C / D
    is_blacklisted      BIT             NOT NULL DEFAULT 0,
    -- SCD2 metadata
    effective_from      DATE            NOT NULL,
    effective_to        DATE            NOT NULL DEFAULT '9999-12-31',
    is_current          BIT             NOT NULL DEFAULT 1,
    -- DW audit
    dw_created_at       DATETIME2       NOT NULL DEFAULT SYSUTCDATETIME(),
    dw_updated_at       DATETIME2       NOT NULL DEFAULT SYSUTCDATETIME(),
    dw_source_system    VARCHAR(50)     NOT NULL DEFAULT 'CRM',
    dw_batch_id         INT             NULL,
    CONSTRAINT PK_dim_customer PRIMARY KEY CLUSTERED (customer_sk)
);
GO

-- Index on natural key for ETL lookups
CREATE NONCLUSTERED INDEX IX_dim_customer_bk_current
    ON dw.dim_customer (customer_bk, is_current)
    INCLUDE (customer_sk);
GO

-- Index for historical queries
CREATE NONCLUSTERED INDEX IX_dim_customer_eff_dates
    ON dw.dim_customer (customer_bk, effective_from, effective_to);
GO

-- Unknown member for FK resolution
SET IDENTITY_INSERT dw.dim_customer ON;
INSERT INTO dw.dim_customer (
    customer_sk, customer_bk, full_name, marital_status,
    effective_from, effective_to, is_current
) VALUES (
    -1, 'UNKNOWN', 'Unknown Customer', 'UNKNOWN',
    '1900-01-01', '9999-12-31', 1
);
SET IDENTITY_INSERT dw.dim_customer OFF;
GO

PRINT 'dw.dim_customer created with SCD Type 2 structure.';
GO
