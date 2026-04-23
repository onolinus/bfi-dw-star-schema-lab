-- =============================================================================
-- FILE   : 01-staging/01-create-staging-tables.sql
-- PURPOSE: Create staging tables that mirror source system structures
-- TARGET : SQL Server 2019/2022
-- =============================================================================
-- Staging tables are intentionally loose (VARCHAR, nullable) to accept raw
-- data from source systems without transformation errors. Transformations and
-- business rules are applied when loading into the DW layer.
-- =============================================================================

USE TrainingSQL;
GO

-- ---------------------------------------------------------------------------
-- STG.CUSTOMER — Source: CRM / Aplikasi Kredit (Loan Application System)
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS stg.customer;
GO

CREATE TABLE stg.customer (
    customer_id         VARCHAR(20)     NOT NULL,   -- source natural key e.g. 'CUST-00001'
    nik                 CHAR(16)        NULL,        -- Nomor Induk Kependudukan (National ID)
    full_name           NVARCHAR(150)   NOT NULL,
    date_of_birth       DATE            NULL,
    gender              CHAR(1)         NULL,        -- 'M' / 'F'
    marital_status      VARCHAR(20)     NULL,        -- LAJANG / MENIKAH / CERAI
    address_line1       NVARCHAR(200)   NULL,
    address_line2       NVARCHAR(200)   NULL,
    kelurahan           NVARCHAR(100)   NULL,        -- sub-district
    kecamatan           NVARCHAR(100)   NULL,        -- district
    kota_kabupaten      NVARCHAR(100)   NULL,        -- city / regency
    provinsi            NVARCHAR(100)   NULL,
    kode_pos            VARCHAR(10)     NULL,
    phone_mobile        VARCHAR(20)     NULL,
    email               VARCHAR(150)    NULL,
    income_monthly      DECIMAL(18,2)   NULL,        -- IDR
    income_bracket      VARCHAR(20)     NULL,        -- LOW / MIDDLE / UPPER
    occupation          NVARCHAR(100)   NULL,
    employer_name       NVARCHAR(150)   NULL,
    risk_rating         VARCHAR(10)     NULL,        -- A / B / C / D
    is_blacklisted      BIT             NULL,
    -- ETL metadata
    source_system       VARCHAR(50)     NOT NULL DEFAULT 'CRM',
    extracted_at        DATETIME2       NOT NULL DEFAULT SYSUTCDATETIME(),
    batch_id            INT             NULL
);
GO

-- ---------------------------------------------------------------------------
-- STG.PRODUCT — Source: Product Management System
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS stg.product;
GO

CREATE TABLE stg.product (
    product_id          VARCHAR(20)     NOT NULL,   -- e.g. 'PROD-MVN-001'
    product_code        VARCHAR(20)     NOT NULL,
    product_name        NVARCHAR(150)   NOT NULL,
    product_category    VARCHAR(50)     NULL,        -- MOTOR_VEHICLE / HEAVY_EQUIPMENT / PROPERTY / CONSUMER
    product_subcategory VARCHAR(50)     NULL,        -- NEW_MOTOR / USED_MOTOR / HEAVY_MINING / etc.
    min_loan_amount     DECIMAL(18,2)   NULL,
    max_loan_amount     DECIMAL(18,2)   NULL,
    min_tenor_months    SMALLINT        NULL,
    max_tenor_months    SMALLINT        NULL,
    base_interest_rate  DECIMAL(8,4)    NULL,        -- annual %
    admin_fee_pct       DECIMAL(8,4)    NULL,
    insurance_required  BIT             NULL,
    is_active           BIT             NULL,
    effective_date      DATE            NULL,
    -- ETL metadata
    source_system       VARCHAR(50)     NOT NULL DEFAULT 'PRODUCT_MGMT',
    extracted_at        DATETIME2       NOT NULL DEFAULT SYSUTCDATETIME(),
    batch_id            INT             NULL
);
GO

-- ---------------------------------------------------------------------------
-- STG.BRANCH — Source: HO Branch Management System
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS stg.branch;
GO

CREATE TABLE stg.branch (
    branch_id           VARCHAR(20)     NOT NULL,   -- e.g. 'BR-JKT-001'
    branch_code         VARCHAR(10)     NOT NULL,
    branch_name         NVARCHAR(150)   NOT NULL,
    branch_type         VARCHAR(30)     NULL,        -- CABANG_UTAMA / CABANG / POS_PELAYANAN
    branch_tier         VARCHAR(10)     NULL,        -- TIER1 / TIER2 / TIER3
    region_code         VARCHAR(10)     NULL,        -- REG-JAB / REG-SUM / etc.
    region_name         NVARCHAR(100)   NULL,
    area_code           VARCHAR(10)     NULL,
    area_name           NVARCHAR(100)   NULL,
    address             NVARCHAR(250)   NULL,
    kota_kabupaten      NVARCHAR(100)   NULL,
    provinsi            NVARCHAR(100)   NULL,
    phone               VARCHAR(20)     NULL,
    manager_employee_id VARCHAR(20)     NULL,
    open_date           DATE            NULL,
    is_active           BIT             NULL,
    -- ETL metadata
    source_system       VARCHAR(50)     NOT NULL DEFAULT 'BRANCH_MGMT',
    extracted_at        DATETIME2       NOT NULL DEFAULT SYSUTCDATETIME(),
    batch_id            INT             NULL
);
GO

-- ---------------------------------------------------------------------------
-- STG.EMPLOYEE — Source: HRIS (Human Resource Information System)
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS stg.employee;
GO

CREATE TABLE stg.employee (
    employee_id         VARCHAR(20)     NOT NULL,   -- e.g. 'EMP-00001'
    nip                 VARCHAR(20)     NULL,        -- Nomor Induk Pegawai
    full_name           NVARCHAR(150)   NOT NULL,
    job_title           NVARCHAR(100)   NULL,        -- Loan Officer / Branch Manager / etc.
    department          NVARCHAR(100)   NULL,
    branch_id           VARCHAR(20)     NULL,
    join_date           DATE            NULL,
    is_active           BIT             NULL,
    -- ETL metadata
    source_system       VARCHAR(50)     NOT NULL DEFAULT 'HRIS',
    extracted_at        DATETIME2       NOT NULL DEFAULT SYSUTCDATETIME(),
    batch_id            INT             NULL
);
GO

-- ---------------------------------------------------------------------------
-- STG.COLLATERAL — Source: Appraisal / Asset Management System
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS stg.collateral;
GO

CREATE TABLE stg.collateral (
    collateral_id           VARCHAR(30)     NOT NULL,
    collateral_type         VARCHAR(30)     NULL,    -- MOTOR / MOBIL / ALAT_BERAT / PROPERTI
    brand                   NVARCHAR(100)   NULL,
    model                   NVARCHAR(150)   NULL,
    manufacture_year        SMALLINT        NULL,
    color                   NVARCHAR(50)    NULL,
    plate_number            VARCHAR(20)     NULL,
    chassis_number          VARCHAR(50)     NULL,
    engine_number           VARCHAR(50)     NULL,
    appraised_value         DECIMAL(18,2)   NULL,
    condition_rating        VARCHAR(10)     NULL,    -- BARU / SANGAT_BAIK / BAIK / CUKUP
    appraised_date          DATE            NULL,
    -- ETL metadata
    source_system           VARCHAR(50)     NOT NULL DEFAULT 'APPRAISAL',
    extracted_at            DATETIME2       NOT NULL DEFAULT SYSUTCDATETIME(),
    batch_id                INT             NULL
);
GO

-- ---------------------------------------------------------------------------
-- STG.LOAN_APPLICATION — Source: Loan Origination System (LOS)
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS stg.loan_application;
GO

CREATE TABLE stg.loan_application (
    loan_id                 VARCHAR(30)     NOT NULL,   -- e.g. 'LOS-2024-000001'
    customer_id             VARCHAR(20)     NOT NULL,
    product_id              VARCHAR(20)     NOT NULL,
    branch_id               VARCHAR(20)     NOT NULL,
    employee_id             VARCHAR(20)     NOT NULL,   -- loan officer
    collateral_id           VARCHAR(30)     NULL,
    application_date        DATE            NOT NULL,
    approval_date           DATE            NULL,
    disbursement_date       DATE            NULL,
    loan_status             VARCHAR(20)     NOT NULL,   -- PENDING / APPROVED / REJECTED / DISBURSED / CLOSED
    requested_amount        DECIMAL(18,2)   NOT NULL,
    approved_amount         DECIMAL(18,2)   NULL,
    disbursed_amount        DECIMAL(18,2)   NULL,
    tenor_months            SMALLINT        NOT NULL,
    interest_rate           DECIMAL(8,4)    NULL,       -- actual rate applied (annual %)
    monthly_installment     DECIMAL(18,2)   NULL,
    total_payable           DECIMAL(18,2)   NULL,
    admin_fee               DECIMAL(18,2)   NULL,
    insurance_fee           DECIMAL(18,2)   NULL,
    rejection_reason        NVARCHAR(200)   NULL,
    -- ETL metadata
    source_system           VARCHAR(50)     NOT NULL DEFAULT 'LOS',
    extracted_at            DATETIME2       NOT NULL DEFAULT SYSUTCDATETIME(),
    batch_id                INT             NULL
);
GO

-- ---------------------------------------------------------------------------
-- STG.PAYMENT — Source: Core Banking / Payment Collection System
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS stg.payment;
GO

CREATE TABLE stg.payment (
    payment_id              VARCHAR(30)     NOT NULL,   -- e.g. 'PAY-2024-000001'
    loan_id                 VARCHAR(30)     NOT NULL,
    customer_id             VARCHAR(20)     NOT NULL,
    branch_id               VARCHAR(20)     NOT NULL,
    installment_number      SMALLINT        NOT NULL,
    due_date                DATE            NOT NULL,
    payment_date            DATE            NULL,
    scheduled_amount        DECIMAL(18,2)   NOT NULL,
    paid_amount             DECIMAL(18,2)   NULL,
    payment_method          VARCHAR(30)     NULL,   -- TUNAI / TRANSFER / AUTODEBET / KANTOR_POS
    payment_channel         VARCHAR(50)     NULL,   -- TELLER / ATM / MOBILE_BANKING / AGEN
    payment_status          VARCHAR(20)     NOT NULL,   -- PAID / PARTIAL / OVERDUE / WAIVED
    dpd                     SMALLINT        NULL,       -- Days Past Due at payment date
    penalty_amount          DECIMAL(18,2)   NULL,
    waiver_amount           DECIMAL(18,2)   NULL,
    collector_employee_id   VARCHAR(20)     NULL,
    -- ETL metadata
    source_system           VARCHAR(50)     NOT NULL DEFAULT 'CORE_BANKING',
    extracted_at            DATETIME2       NOT NULL DEFAULT SYSUTCDATETIME(),
    batch_id                INT             NULL
);
GO

PRINT 'All staging tables created successfully.';
GO
