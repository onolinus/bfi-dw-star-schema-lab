# Data Dictionary — BFI DW Star Schema Lab

## Naming Conventions

| Element | Convention | Example |
|---|---|---|
| Schema | lowercase 3-letter code | `stg`, `dw`, `rpt` |
| Tables | `schema.type_entity` | `dw.fact_loan`, `dw.dim_customer` |
| Surrogate keys | `entity_sk` | `customer_sk`, `loan_sk` |
| Business keys | `entity_bk` | `customer_bk`, `branch_bk` |
| Date foreign keys | `event_date_sk` | `disbursement_date_sk` |
| Boolean | `is_*` | `is_current`, `is_active` |
| Amounts | `*_amount` or `*_idr` | `disbursed_amount` |
| Percentages | `*_rate` or `*_pct` | `interest_rate`, `collection_rate_pct` |
| Audit columns | `dw_*` | `dw_created_at`, `dw_batch_id` |

---

## dw.dim_date

| Column | Type | Description |
|---|---|---|
| `date_sk` | INT PK | YYYYMMDD integer (e.g. 20240115) |
| `full_date` | DATE | Actual date value |
| `day_of_month` | TINYINT | 1–31 |
| `day_name_en` | VARCHAR(10) | Monday, Tuesday… |
| `day_name_id` | NVARCHAR(10) | Senin, Selasa… |
| `day_of_week` | TINYINT | 1=Sunday, 7=Saturday |
| `is_weekday` | BIT | 1 = Mon–Fri |
| `month_number` | TINYINT | 1–12 |
| `month_name_id` | NVARCHAR(12) | Januari, Februari… |
| `month_year` | CHAR(7) | '2024-01' |
| `quarter_number` | TINYINT | 1–4 |
| `year_number` | SMALLINT | e.g. 2024 |
| `fiscal_year` | SMALLINT | Same as calendar year for BFI |
| `is_last_day_of_month` | BIT | 1 if last day |
| `is_holiday` | BIT | 1 if Indonesian national holiday |
| `holiday_name` | NVARCHAR(100) | Name of holiday if applicable |
| `year_month_int` | INT | YYYYMM for fast grouping |

---

## dw.dim_customer (SCD Type 2)

| Column | Type | SCD | Description |
|---|---|---|---|
| `customer_sk` | INT PK | — | Surrogate key |
| `customer_bk` | VARCHAR(20) | — | Source CRM customer ID |
| `nik` | CHAR(16) | — | NIK (16-digit national ID) |
| `full_name` | NVARCHAR(150) | — | Full legal name |
| `date_of_birth` | DATE | — | |
| `gender` | CHAR(1) | — | M / F |
| `marital_status` | VARCHAR(20) | **SCD2** | LAJANG / MENIKAH / CERAI |
| `address_line1` | NVARCHAR(200) | **SCD2** | Street address |
| `kelurahan` | NVARCHAR(100) | **SCD2** | Sub-district |
| `kecamatan` | NVARCHAR(100) | **SCD2** | District |
| `kota_kabupaten` | NVARCHAR(100) | **SCD2** | City or regency |
| `provinsi` | NVARCHAR(100) | **SCD2** | Province |
| `kode_pos` | VARCHAR(10) | **SCD2** | Postal code |
| `phone_mobile` | VARCHAR(20) | SCD1 | Overwritten, not tracked |
| `email` | VARCHAR(150) | SCD1 | Overwritten, not tracked |
| `income_monthly` | DECIMAL(18,2) | **SCD2** | Monthly income in IDR |
| `income_bracket` | VARCHAR(20) | **SCD2** | LOW / MIDDLE / UPPER |
| `occupation` | NVARCHAR(100) | **SCD2** | |
| `employer_name` | NVARCHAR(150) | **SCD2** | |
| `risk_rating` | VARCHAR(10) | **SCD2** | A / B / C / D |
| `is_blacklisted` | BIT | SCD1 | Blacklist flag |
| `effective_from` | DATE | — | Row valid from |
| `effective_to` | DATE | — | Row valid until (9999-12-31 = current) |
| `is_current` | BIT | — | 1 = active row |
| `dw_created_at` | DATETIME2 | — | When row was first loaded |
| `dw_updated_at` | DATETIME2 | — | When row was last modified |

---

## dw.dim_product (SCD Type 1)

| Column | Type | Description |
|---|---|---|
| `product_sk` | INT PK | Surrogate key |
| `product_bk` | VARCHAR(20) | Source product ID |
| `product_code` | VARCHAR(20) | Short code (e.g. MVN-MTR) |
| `product_name` | NVARCHAR(150) | Full product name (Bahasa) |
| `product_category` | VARCHAR(50) | MOTOR_VEHICLE / HEAVY_EQUIPMENT / PROPERTY / CONSUMER |
| `product_subcategory` | VARCHAR(50) | NEW_MOTOR / USED_CAR / MINING / etc. |
| `min_loan_amount` | DECIMAL(18,2) | Minimum loan in IDR |
| `max_loan_amount` | DECIMAL(18,2) | Maximum loan in IDR |
| `min_tenor_months` | SMALLINT | Minimum tenor |
| `max_tenor_months` | SMALLINT | Maximum tenor |
| `base_interest_rate` | DECIMAL(8,4) | Annual base rate % |
| `admin_fee_pct` | DECIMAL(8,4) | Admin fee as % of loan |
| `insurance_required` | BIT | 1 = insurance mandatory |
| `is_active` | BIT | 1 = product currently offered |

---

## dw.dim_branch (SCD Type 2)

| Column | Type | SCD | Description |
|---|---|---|---|
| `branch_sk` | INT PK | — | Surrogate key |
| `branch_bk` | VARCHAR(20) | — | Source branch ID |
| `branch_code` | VARCHAR(10) | — | Short code (e.g. JKT-PST) |
| `branch_name` | NVARCHAR(150) | **SCD2** | Full branch name |
| `branch_type` | VARCHAR(30) | **SCD2** | CABANG_UTAMA / CABANG / POS_PELAYANAN |
| `branch_tier` | VARCHAR(10) | **SCD2** | TIER1 / TIER2 / TIER3 |
| `region_code` | VARCHAR(10) | **SCD2** | Regional grouping code |
| `region_name` | NVARCHAR(100) | **SCD2** | e.g. Jabodetabek, Sumatera |
| `area_code` | VARCHAR(10) | **SCD2** | Area sub-grouping |
| `address` | NVARCHAR(250) | **SCD2** | Physical address |
| `kota_kabupaten` | NVARCHAR(100) | **SCD2** | City |
| `provinsi` | NVARCHAR(100) | — | Province |
| `manager_employee_id` | VARCHAR(20) | SCD1 | Current branch manager (source key) |
| `open_date` | DATE | — | Date branch opened |
| `is_active` | BIT | — | 1 = open |
| `effective_from` | DATE | — | Row valid from |
| `effective_to` | DATE | — | Row valid until |
| `is_current` | BIT | — | 1 = active row |

---

## dw.fact_loan

| Column | Type | Description |
|---|---|---|
| `loan_sk` | BIGINT PK | Surrogate key |
| `loan_bk` | VARCHAR(30) | Source LOS loan ID (degenerate dim) |
| `customer_sk` | INT FK | → dim_customer.customer_sk |
| `product_sk` | INT FK | → dim_product.product_sk |
| `branch_sk` | INT FK | → dim_branch.branch_sk |
| `employee_sk` | INT FK | → dim_employee.employee_sk (loan officer) |
| `collateral_sk` | INT FK | → dim_collateral.collateral_sk (-1 if none) |
| `application_date_sk` | INT FK | → dim_date.date_sk |
| `approval_date_sk` | INT FK | → dim_date.date_sk |
| `disbursement_date_sk` | INT FK | → dim_date.date_sk |
| `loan_status` | VARCHAR(20) | PENDING / APPROVED / REJECTED / DISBURSED / CLOSED |
| `requested_amount` | DECIMAL(18,2) | Amount customer applied for (IDR) |
| `approved_amount` | DECIMAL(18,2) | Amount BFI approved (IDR) |
| `disbursed_amount` | DECIMAL(18,2) | Amount actually disbursed (IDR) |
| `admin_fee` | DECIMAL(18,2) | Administration fee (IDR) |
| `insurance_fee` | DECIMAL(18,2) | Insurance premium (IDR) |
| `total_payable` | DECIMAL(18,2) | Total principal + interest (IDR) |
| `monthly_installment` | DECIMAL(18,2) | Per-installment amount (IDR) |
| `tenor_months` | SMALLINT | Loan term in months |
| `interest_rate` | DECIMAL(8,4) | Actual annual rate applied (%) |
| `total_interest_amount` | DECIMAL(18,2) | Computed: total_payable − disbursed_amount |
| `approval_days` | INT | Computed: days from application to approval |

---

## dw.fact_payment

| Column | Type | Description |
|---|---|---|
| `payment_sk` | BIGINT PK | Surrogate key |
| `payment_bk` | VARCHAR(30) | Source payment ID (degenerate dim) |
| `loan_sk` | BIGINT FK | → fact_loan.loan_sk |
| `customer_sk` | INT FK | → dim_customer.customer_sk |
| `branch_sk` | INT FK | → dim_branch.branch_sk |
| `due_date_sk` | INT FK | → dim_date.date_sk (scheduled due date) |
| `payment_date_sk` | INT FK | → dim_date.date_sk (0 if not paid) |
| `installment_number` | SMALLINT | 1, 2, 3… up to tenor_months |
| `payment_status` | VARCHAR(20) | PAID / PARTIAL / OVERDUE / WAIVED |
| `payment_method` | VARCHAR(30) | TUNAI / TRANSFER / AUTODEBET / KANTOR_POS |
| `payment_channel` | VARCHAR(50) | TELLER / ATM / MOBILE_BANKING / AGEN |
| `scheduled_amount` | DECIMAL(18,2) | Expected installment amount (IDR) |
| `paid_amount` | DECIMAL(18,2) | Actual amount received (IDR) |
| `penalty_amount` | DECIMAL(18,2) | Late penalty charged (IDR) |
| `waiver_amount` | DECIMAL(18,2) | Penalty waived by branch (IDR) |
| `shortfall_amount` | DECIMAL(18,2) | Computed: scheduled − paid |
| `dpd` | SMALLINT | Days Past Due at payment date |
| `collectibility_grade` | TINYINT | 1–5 per OJK classification |
| `collectibility_label` | NVARCHAR(50) | Lancar / DPK / Kurang Lancar / Diragukan / Macet |
| `collector_employee_id` | VARCHAR(20) | Source employee ID of collector |

---

## OJK Collectibility Reference

| Grade | Label | DPD | Provisioning Requirement |
|---|---|---|---|
| 1 | Lancar | 0 | 1% |
| 2 | Dalam Perhatian Khusus (DPK) | 1–90 | 5% |
| 3 | Kurang Lancar | 91–120 | 15% |
| 4 | Diragukan | 121–180 | 50% |
| 5 | Macet | > 180 | 100% |

*Source: OJK Regulation POJK No. 40/POJK.03/2019*
