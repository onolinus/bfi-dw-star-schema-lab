# BFI DW Star Schema Lab

**Hands-on Data Warehouse Lab — BFI Finance Indonesia**

A complete, production-grade reference implementation of a dimensional data warehouse covering:

- Star Schema design for a multi-finance company
- Slowly Changing Dimensions (SCD) Type 1 and Type 2
- ETL pipelines using T-SQL MERGE statements
- Analytics queries for loan portfolio, collections, and branch performance
- Cloud portability notes for Azure Synapse, Snowflake, and BigQuery

---

## Business Context

BFI Finance Indonesia is a multi-finance company offering:

| Product Category | Description |
|---|---|
| Motor Vehicle Financing | New & used motorcycles and cars |
| Heavy Equipment Financing | Construction and mining equipment |
| Property Refinancing | Asset-backed refinancing |
| Consumer Goods | Electronics, appliances |

Key KPIs tracked in this warehouse:
- **Loan Origination** — volume, value, approval rate by product/branch
- **NPL (Non-Performing Loan)** — % of portfolio with DPD > 90 days
- **DPD (Days Past Due)** — collectibility grading per OJK regulation
- **Collection Rate** — payment success rate by collector / branch
- **Customer Lifetime Value** — repeat borrower analysis

---

## Repository Structure

```
bfi-dw-star-schema-lab/
├── README.md
├── docs/
│   ├── 01-star-schema-overview.md     # Schema diagrams & design decisions
│   ├── 02-scd-concepts.md             # SCD Type 1 vs Type 2 explained
│   └── 03-data-dictionary.md          # Full column-level data dictionary
├── sql/
│   ├── 00-setup/
│   │   ├── 01-create-database.sql     # Database + filegroup setup
│   │   └── 02-create-schemas.sql      # STG, DW, RPT schema creation
│   ├── 01-staging/
│   │   ├── 01-create-staging-tables.sql
│   │   └── 02-seed-staging-data.sql   # 500+ rows of realistic sample data
│   ├── 02-dimensions/
│   │   ├── 01-dim-date.sql            # Fully populated date dimension
│   │   ├── 02-dim-customer.sql        # SCD Type 2 customer dimension
│   │   ├── 03-dim-product.sql         # SCD Type 1 product dimension
│   │   ├── 04-dim-branch.sql          # SCD Type 2 branch dimension
│   │   ├── 05-dim-employee.sql        # SCD Type 1 employee dimension
│   │   └── 06-dim-collateral.sql      # SCD Type 1 collateral dimension
│   ├── 03-facts/
│   │   ├── 01-fact-loan.sql           # Loan origination fact table
│   │   └── 02-fact-payment.sql        # Payment transaction fact table
│   ├── 04-scd/
│   │   ├── 01-scd-type1-product.sql   # SCD1: overwrite product attributes
│   │   ├── 02-scd-type1-employee.sql  # SCD1: overwrite employee attributes
│   │   ├── 03-scd-type2-customer.sql  # SCD2: track customer address changes
│   │   └── 04-scd-type2-branch.sql    # SCD2: track branch region changes
│   ├── 05-etl/
│   │   ├── 01-etl-dim-customer.sql    # Full ETL: staging → dim_customer
│   │   ├── 02-etl-dim-product.sql     # Full ETL: staging → dim_product
│   │   ├── 03-etl-dim-branch.sql      # Full ETL: staging → dim_branch
│   │   ├── 04-etl-fact-loan.sql       # Full ETL: staging → fact_loan
│   │   └── 05-etl-fact-payment.sql    # Full ETL: staging → fact_payment
│   └── 06-analytics/
│       ├── 01-loan-portfolio-analysis.sql
│       ├── 02-customer-360.sql
│       ├── 03-branch-performance.sql
│       └── 04-payment-collection.sql
├── diagrams/
│   └── star-schema.dbml               # DBML source (dbdiagram.io compatible)
└── cloud/
    ├── azure-synapse/README.md        # Azure Synapse Analytics notes
    ├── snowflake/README.md            # Snowflake adaptation notes
    └── bigquery/README.md            # BigQuery adaptation notes
```

---

## Star Schema Overview

```
                          ┌─────────────┐
                          │  dim_date   │
                          └──────┬──────┘
                                 │
┌──────────────┐    ┌────────────▼──────────┐    ┌───────────────┐
│ dim_customer │◄───┤      fact_loan        ├───►│  dim_product  │
└──────────────┘    │  ─────────────────    │    └───────────────┘
                    │  loan_sk (PK)         │
┌──────────────┐    │  customer_sk (FK)     │    ┌───────────────┐
│  dim_branch  │◄───┤  product_sk (FK)      ├───►│ dim_employee  │
└──────────────┘    │  branch_sk (FK)       │    └───────────────┘
                    │  employee_sk (FK)     │
┌──────────────┐    │  collateral_sk (FK)   │
│dim_collateral│◄───┤  application_date_sk  │
└──────────────┘    │  disbursement_date_sk │
                    │  ─────────────────    │
                    │  loan_amount          │
                    │  approved_amount      │
                    │  tenor_months         │
                    │  interest_rate        │
                    │  monthly_installment  │
                    └───────────┬───────────┘
                                │ (1:N)
                    ┌───────────▼───────────┐
                    │     fact_payment      │
                    │  ─────────────────    │
                    │  payment_sk (PK)      │
                    │  loan_sk (FK)         │
                    │  payment_date_sk (FK) │
                    │  customer_sk (FK)     │
                    │  branch_sk (FK)       │
                    │  ─────────────────    │
                    │  installment_number   │
                    │  scheduled_amount     │
                    │  paid_amount          │
                    │  dpd_at_payment       │
                    │  collectibility_grade │
                    └───────────────────────┘
```

---

## Quick Start

### Prerequisites

- SQL Server 2019+ (or SQL Server 2022) — Developer/Express/Standard edition
- SQL Server Management Studio (SSMS) 19+ or Azure Data Studio
- Minimum 512 MB disk space for sample data

### Run Order

Execute scripts in this exact order:

```sql
-- Step 1: Setup
00-setup/01-create-database.sql
00-setup/02-create-schemas.sql

-- Step 2: Staging layer
01-staging/01-create-staging-tables.sql
01-staging/02-seed-staging-data.sql

-- Step 3: Dimension tables (order matters — dim_date first)
02-dimensions/01-dim-date.sql
02-dimensions/02-dim-customer.sql
02-dimensions/03-dim-product.sql
02-dimensions/04-dim-branch.sql
02-dimensions/05-dim-employee.sql
02-dimensions/06-dim-collateral.sql

-- Step 4: Fact tables
03-facts/01-fact-loan.sql
03-facts/02-fact-payment.sql

-- Step 5: Load initial data via ETL
05-etl/01-etl-dim-customer.sql
05-etl/02-etl-dim-product.sql
05-etl/03-etl-dim-branch.sql
05-etl/04-etl-fact-loan.sql
05-etl/05-etl-fact-payment.sql

-- Step 6: Practice SCD scenarios
04-scd/01-scd-type1-product.sql
04-scd/02-scd-type1-employee.sql
04-scd/03-scd-type2-customer.sql
04-scd/04-scd-type2-branch.sql

-- Step 7: Run analytics
06-analytics/01-loan-portfolio-analysis.sql
06-analytics/02-customer-360.sql
06-analytics/03-branch-performance.sql
06-analytics/04-payment-collection.sql
```

---

## SCD Summary

| Dimension | SCD Type | Tracked Changes |
|---|---|---|
| `dim_customer` | **Type 2** | Address, income bracket, marital status, risk rating |
| `dim_product` | **Type 1** | Interest rate adjustments, fee changes |
| `dim_branch` | **Type 2** | Regional reclassification, tier changes, address |
| `dim_employee` | **Type 1** | Job title, department, branch assignment |
| `dim_collateral` | **Type 1** | Appraised value updates, condition rating |

---

## Cloud Compatibility

| Platform | Compatibility | Notes |
|---|---|---|
| SQL Server 2019/2022 | Native | Reference implementation |
| Azure SQL Database | Full | No filegroup changes needed |
| Azure Synapse Analytics | High | Replace IDENTITY with SEQUENCE; see `/cloud/azure-synapse/` |
| Snowflake | High | Replace MERGE with Snowflake MERGE; see `/cloud/snowflake/` |
| Google BigQuery | Medium | No MERGE on non-partitioned tables; see `/cloud/bigquery/` |
| Amazon Redshift | Medium | Use UPSERT pattern; no FK enforcement |

---

## OJK Collectibility Grades (Regulatory Reference)

Per OJK Regulation No. 40/POJK.03/2019:

| Grade | Label | DPD Range |
|---|---|---|
| 1 | Lancar (Current) | 0 days |
| 2 | Dalam Perhatian Khusus (Special Mention) | 1–90 days |
| 3 | Kurang Lancar (Substandard) | 91–120 days |
| 4 | Diragukan (Doubtful) | 121–180 days |
| 5 | Macet (Loss) | > 180 days |

---

## Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/add-dim-insurance`
3. Follow naming conventions in `docs/03-data-dictionary.md`
4. Submit a pull request with schema diagram updates

---

## License

MIT License — free for educational and internal use at BFI Finance Indonesia.
