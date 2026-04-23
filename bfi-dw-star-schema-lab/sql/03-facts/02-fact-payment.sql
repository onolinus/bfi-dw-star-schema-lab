-- =============================================================================
-- FILE   : 03-facts/02-fact-payment.sql
-- PURPOSE: Create fact_payment — one row per installment payment event
-- TARGET : SQL Server 2019/2022
-- =============================================================================
-- Grain: One row per installment schedule line (whether paid or overdue)
-- Additive measures: scheduled_amount, paid_amount, penalty_amount, waiver_amount
-- Non-additive: dpd (use MAX/AVG), collectibility_grade
-- =============================================================================

USE TrainingSQL;
GO

DROP TABLE IF EXISTS dw.fact_payment;
GO

CREATE TABLE dw.fact_payment (
    -- Surrogate key
    payment_sk              BIGINT          NOT NULL IDENTITY(1,1),
    -- Degenerate dimension
    payment_bk              VARCHAR(30)     NOT NULL,
    -- Foreign keys
    loan_sk                 BIGINT          NOT NULL,
    customer_sk             INT             NOT NULL,
    branch_sk               INT             NOT NULL,
    due_date_sk             INT             NOT NULL,
    payment_date_sk         INT             NOT NULL,   -- 0 if not yet paid
    -- Payment attributes (degenerate / low-cardinality — no separate dim needed)
    installment_number      SMALLINT        NOT NULL,
    payment_status          VARCHAR(20)     NOT NULL,   -- PAID / PARTIAL / OVERDUE / WAIVED
    payment_method          VARCHAR(30)     NULL,
    payment_channel         VARCHAR(50)     NULL,
    -- Additive measures (IDR)
    scheduled_amount        DECIMAL(18,2)   NOT NULL,
    paid_amount             DECIMAL(18,2)   NOT NULL DEFAULT 0,
    penalty_amount          DECIMAL(18,2)   NOT NULL DEFAULT 0,
    waiver_amount           DECIMAL(18,2)   NOT NULL DEFAULT 0,
    -- Derived
    shortfall_amount        AS (scheduled_amount - paid_amount) PERSISTED,
    -- Non-additive: DPD at time of payment (or current DPD if unpaid)
    dpd                     SMALLINT        NULL,
    -- OJK Collectibility grade (derived from DPD at payment date)
    --   1 = Lancar, 2 = DPK, 3 = Kurang Lancar, 4 = Diragukan, 5 = Macet
    collectibility_grade    TINYINT         NOT NULL DEFAULT 1,
    collectibility_label    NVARCHAR(50)    NULL,
    -- Collector (optional — who collected this payment)
    collector_employee_id   VARCHAR(20)     NULL,
    -- DW audit
    dw_created_at           DATETIME2       NOT NULL DEFAULT SYSUTCDATETIME(),
    dw_updated_at           DATETIME2       NOT NULL DEFAULT SYSUTCDATETIME(),
    dw_batch_id             INT             NULL,
    CONSTRAINT PK_fact_payment PRIMARY KEY CLUSTERED (payment_sk),
    CONSTRAINT FK_fact_payment_loan         FOREIGN KEY (loan_sk)           REFERENCES dw.fact_loan (loan_sk),
    CONSTRAINT FK_fact_payment_customer     FOREIGN KEY (customer_sk)       REFERENCES dw.dim_customer (customer_sk),
    CONSTRAINT FK_fact_payment_branch       FOREIGN KEY (branch_sk)         REFERENCES dw.dim_branch (branch_sk),
    CONSTRAINT FK_fact_payment_due_date     FOREIGN KEY (due_date_sk)       REFERENCES dw.dim_date (date_sk),
    CONSTRAINT FK_fact_payment_pay_date     FOREIGN KEY (payment_date_sk)   REFERENCES dw.dim_date (date_sk)
);
GO

-- Indexes for collection analysis queries
CREATE NONCLUSTERED INDEX IX_fact_payment_loan
    ON dw.fact_payment (loan_sk, installment_number)
    INCLUDE (paid_amount, dpd, collectibility_grade);

CREATE NONCLUSTERED INDEX IX_fact_payment_due_date
    ON dw.fact_payment (due_date_sk, payment_status)
    INCLUDE (scheduled_amount, paid_amount, dpd);

CREATE NONCLUSTERED INDEX IX_fact_payment_customer
    ON dw.fact_payment (customer_sk, due_date_sk)
    INCLUDE (payment_status, dpd, paid_amount);

CREATE UNIQUE NONCLUSTERED INDEX UQ_fact_payment_bk
    ON dw.fact_payment (payment_bk);
GO

PRINT 'dw.fact_payment created.';
GO
