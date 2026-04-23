-- =============================================================================
-- FILE   : 03-facts/01-fact-loan.sql
-- PURPOSE: Create fact_loan — one row per loan disbursement
-- TARGET : SQL Server 2019/2022
-- =============================================================================
-- Grain: One row per approved & disbursed loan
-- Additive measures: all monetary amounts, tenor
-- Non-additive: interest_rate (use AVG), dpd (use MAX/AVG)
-- =============================================================================

USE TrainingSQL;
GO

DROP TABLE IF EXISTS dw.fact_loan;
GO

CREATE TABLE dw.fact_loan (
    -- Surrogate key
    loan_sk                 BIGINT          NOT NULL IDENTITY(1,1),
    -- Degenerate dimension (source natural key — no dim table needed)
    loan_bk                 VARCHAR(30)     NOT NULL,
    -- Foreign keys to dimensions
    customer_sk             INT             NOT NULL,
    product_sk              INT             NOT NULL,
    branch_sk               INT             NOT NULL,
    employee_sk             INT             NOT NULL,   -- loan officer
    collateral_sk           INT             NOT NULL,   -- -1 if no collateral
    application_date_sk     INT             NOT NULL,
    approval_date_sk        INT             NOT NULL,
    disbursement_date_sk    INT             NOT NULL,
    -- Loan status (degenerate / mini-dimension for filtering)
    loan_status             VARCHAR(20)     NOT NULL,
    -- Additive measures (IDR)
    requested_amount        DECIMAL(18,2)   NOT NULL,
    approved_amount         DECIMAL(18,2)   NULL,
    disbursed_amount        DECIMAL(18,2)   NULL,
    admin_fee               DECIMAL(18,2)   NULL,
    insurance_fee           DECIMAL(18,2)   NULL,
    total_payable           DECIMAL(18,2)   NULL,
    monthly_installment     DECIMAL(18,2)   NULL,
    -- Semi-additive / non-additive measures
    tenor_months            SMALLINT        NOT NULL,
    interest_rate           DECIMAL(8,4)    NULL,       -- annual %; use AVG not SUM
    -- Derived measures (calculated at load time for performance)
    total_interest_amount   AS (
        CASE WHEN total_payable IS NOT NULL AND disbursed_amount IS NOT NULL
             THEN total_payable - disbursed_amount
             ELSE NULL
        END
    ) PERSISTED,
    approval_days           AS (
        CASE WHEN approval_date_sk > 0 AND application_date_sk > 0
             THEN DATEDIFF(DAY,
                    DATEFROMPARTS(application_date_sk / 10000, (application_date_sk / 100) % 100, application_date_sk % 100),
                    DATEFROMPARTS(approval_date_sk    / 10000, (approval_date_sk    / 100) % 100, approval_date_sk    % 100))
             ELSE NULL
        END
    ) PERSISTED,
    -- DW audit
    dw_created_at           DATETIME2       NOT NULL DEFAULT SYSUTCDATETIME(),
    dw_updated_at           DATETIME2       NOT NULL DEFAULT SYSUTCDATETIME(),
    dw_batch_id             INT             NULL,
    CONSTRAINT PK_fact_loan PRIMARY KEY CLUSTERED (loan_sk),
    CONSTRAINT FK_fact_loan_customer    FOREIGN KEY (customer_sk)          REFERENCES dw.dim_customer (customer_sk),
    CONSTRAINT FK_fact_loan_product     FOREIGN KEY (product_sk)            REFERENCES dw.dim_product (product_sk),
    CONSTRAINT FK_fact_loan_branch      FOREIGN KEY (branch_sk)             REFERENCES dw.dim_branch (branch_sk),
    CONSTRAINT FK_fact_loan_employee    FOREIGN KEY (employee_sk)           REFERENCES dw.dim_employee (employee_sk),
    CONSTRAINT FK_fact_loan_collateral  FOREIGN KEY (collateral_sk)         REFERENCES dw.dim_collateral (collateral_sk),
    CONSTRAINT FK_fact_loan_app_date    FOREIGN KEY (application_date_sk)   REFERENCES dw.dim_date (date_sk),
    CONSTRAINT FK_fact_loan_appr_date   FOREIGN KEY (approval_date_sk)      REFERENCES dw.dim_date (date_sk),
    CONSTRAINT FK_fact_loan_disb_date   FOREIGN KEY (disbursement_date_sk)  REFERENCES dw.dim_date (date_sk)
);
GO

-- Covering indexes for common query patterns
CREATE NONCLUSTERED INDEX IX_fact_loan_customer
    ON dw.fact_loan (customer_sk, disbursement_date_sk)
    INCLUDE (disbursed_amount, loan_status);

CREATE NONCLUSTERED INDEX IX_fact_loan_product_branch
    ON dw.fact_loan (product_sk, branch_sk, disbursement_date_sk)
    INCLUDE (disbursed_amount, monthly_installment);

CREATE NONCLUSTERED INDEX IX_fact_loan_date
    ON dw.fact_loan (disbursement_date_sk)
    INCLUDE (disbursed_amount, loan_status, product_sk, branch_sk);

CREATE UNIQUE NONCLUSTERED INDEX UQ_fact_loan_bk
    ON dw.fact_loan (loan_bk);
GO

PRINT 'dw.fact_loan created.';
GO
