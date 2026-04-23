-- =============================================================================
-- FILE   : 01-staging/02-seed-staging-data.sql
-- PURPOSE: Seed realistic sample data representing BFI Finance source systems
-- TARGET : SQL Server 2019/2022
-- NOTE   : All personal data is synthetic / fictional
-- =============================================================================

USE TrainingSQL;
GO

-- ============================================================
-- TRUNCATE ALL STAGING TABLES
-- ============================================================
TRUNCATE TABLE stg.payment;
TRUNCATE TABLE stg.loan_application;
TRUNCATE TABLE stg.collateral;
TRUNCATE TABLE stg.employee;
TRUNCATE TABLE stg.branch;
TRUNCATE TABLE stg.product;
TRUNCATE TABLE stg.customer;
GO

-- ============================================================
-- 1. PRODUCTS
-- ============================================================
INSERT INTO stg.product
    (product_id, product_code, product_name, product_category, product_subcategory,
     min_loan_amount, max_loan_amount, min_tenor_months, max_tenor_months,
     base_interest_rate, admin_fee_pct, insurance_required, is_active, effective_date)
VALUES
    ('PROD-001', 'MVN-MTR', 'Pembiayaan Motor Baru',          'MOTOR_VEHICLE',   'NEW_MOTOR',        3000000,   50000000,   12, 36, 22.00, 1.50, 1, 1, '2020-01-01'),
    ('PROD-002', 'MVU-MTR', 'Pembiayaan Motor Bekas',         'MOTOR_VEHICLE',   'USED_MOTOR',       2000000,   40000000,   12, 48, 26.00, 2.00, 1, 1, '2020-01-01'),
    ('PROD-003', 'MVN-MOB', 'Pembiayaan Mobil Baru',          'MOTOR_VEHICLE',   'NEW_CAR',          50000000, 500000000,  12, 60, 18.00, 1.00, 1, 1, '2020-01-01'),
    ('PROD-004', 'MVU-MOB', 'Pembiayaan Mobil Bekas',         'MOTOR_VEHICLE',   'USED_CAR',         30000000, 400000000,  12, 60, 21.00, 1.50, 1, 1, '2020-01-01'),
    ('PROD-005', 'HE-KONS', 'Pembiayaan Alat Berat Konstruksi','HEAVY_EQUIPMENT','CONSTRUCTION',    100000000,2000000000,  12, 60, 16.00, 0.75, 1, 1, '2020-01-01'),
    ('PROD-006', 'HE-TAMB', 'Pembiayaan Alat Berat Tambang',  'HEAVY_EQUIPMENT', 'MINING',          200000000,5000000000,  24, 60, 15.00, 0.75, 1, 1, '2020-06-01'),
    ('PROD-007', 'PRF-RMH', 'Refinancing Properti',           'PROPERTY',        'PROPERTY_REFI',   50000000, 500000000,  12, 84, 17.50, 1.25, 1, 1, '2021-01-01'),
    ('PROD-008', 'CG-ELEK', 'Pembiayaan Elektronik',          'CONSUMER',        'ELECTRONICS',       500000,   10000000,   6, 24, 28.00, 2.50, 0, 1, '2022-01-01'),
    ('PROD-009', 'CG-FURM', 'Pembiayaan Furnitur',            'CONSUMER',        'FURNITURE',         500000,    8000000,   6, 24, 28.00, 2.50, 0, 1, '2022-01-01'),
    ('PROD-010', 'MVN-TRK', 'Pembiayaan Truk & Angkutan',     'MOTOR_VEHICLE',   'TRUCK',           100000000, 800000000,  12, 60, 19.00, 1.00, 1, 1, '2021-06-01');
GO

-- ============================================================
-- 2. BRANCHES
-- ============================================================
INSERT INTO stg.branch
    (branch_id, branch_code, branch_name, branch_type, branch_tier,
     region_code, region_name, area_code, area_name,
     address, kota_kabupaten, provinsi, phone, open_date, is_active)
VALUES
    ('BR-001', 'JKT-PST', 'BFI Cabang Jakarta Pusat',   'CABANG_UTAMA', 'TIER1', 'REG-JAB', 'Jabodetabek',    'AREA-JKT', 'Jakarta',   'Jl. Sudirman No. 45',          'Jakarta Pusat',    'DKI Jakarta',        '021-5551001', '2005-01-01', 1),
    ('BR-002', 'JKT-SLT', 'BFI Cabang Jakarta Selatan', 'CABANG',       'TIER1', 'REG-JAB', 'Jabodetabek',    'AREA-JKT', 'Jakarta',   'Jl. TB Simatupang No. 18',     'Jakarta Selatan',  'DKI Jakarta',        '021-5552001', '2006-03-01', 1),
    ('BR-003', 'BGR',     'BFI Cabang Bogor',            'CABANG',       'TIER2', 'REG-JAB', 'Jabodetabek',    'AREA-BOD', 'Bodetabek', 'Jl. Pajajaran No. 77',         'Kota Bogor',       'Jawa Barat',         '0251-321001', '2008-05-01', 1),
    ('BR-004', 'BDG',     'BFI Cabang Bandung',          'CABANG_UTAMA', 'TIER1', 'REG-JAB', 'Jawa Barat',     'AREA-BJB', 'Jabar',     'Jl. Asia Afrika No. 112',      'Kota Bandung',     'Jawa Barat',         '022-4231001', '2005-07-01', 1),
    ('BR-005', 'SBY',     'BFI Cabang Surabaya',         'CABANG_UTAMA', 'TIER1', 'REG-JTM', 'Jawa Timur',     'AREA-SBY', 'Surabaya',  'Jl. Ahmad Yani No. 50',        'Kota Surabaya',    'Jawa Timur',         '031-8991001', '2005-03-01', 1),
    ('BR-006', 'MLG',     'BFI Cabang Malang',           'CABANG',       'TIER2', 'REG-JTM', 'Jawa Timur',     'AREA-MLG', 'Malang',    'Jl. Ijen No. 33',              'Kota Malang',      'Jawa Timur',         '0341-411001', '2009-01-01', 1),
    ('BR-007', 'SMG',     'BFI Cabang Semarang',         'CABANG_UTAMA', 'TIER1', 'REG-JTG', 'Jawa Tengah',    'AREA-SMG', 'Semarang',  'Jl. Pemuda No. 88',            'Kota Semarang',    'Jawa Tengah',        '024-3551001', '2006-09-01', 1),
    ('BR-008', 'MDN',     'BFI Cabang Medan',            'CABANG_UTAMA', 'TIER1', 'REG-SUM', 'Sumatera',       'AREA-MDN', 'Medan',     'Jl. Gatot Subroto No. 200',    'Kota Medan',       'Sumatera Utara',     '061-4551001', '2007-04-01', 1),
    ('BR-009', 'PLG',     'BFI Cabang Palembang',        'CABANG',       'TIER2', 'REG-SUM', 'Sumatera',       'AREA-PLG', 'Palembang', 'Jl. Jenderal Sudirman No. 55', 'Kota Palembang',   'Sumatera Selatan',   '0711-311001', '2010-06-01', 1),
    ('BR-010', 'MKS',     'BFI Cabang Makassar',         'CABANG_UTAMA', 'TIER1', 'REG-KTI', 'KTI',            'AREA-MKS', 'Makassar',  'Jl. Penghibur No. 10',         'Kota Makassar',    'Sulawesi Selatan',   '0411-3311001','2008-02-01', 1),
    ('BR-011', 'BPN',     'BFI Cabang Balikpapan',       'CABANG',       'TIER2', 'REG-KAL', 'Kalimantan',     'AREA-BPN', 'Balikpapan','Jl. Jend. Sudirman No. 150',   'Kota Balikpapan',  'Kalimantan Timur',   '0542-721001', '2011-01-01', 1),
    ('BR-012', 'TNG',     'BFI Pos Pelayanan Tangerang', 'POS_PELAYANAN','TIER3', 'REG-JAB', 'Jabodetabek',    'AREA-BOD', 'Bodetabek', 'Jl. Imam Bonjol No. 40',       'Kota Tangerang',   'Banten',             '021-5572001', '2015-03-01', 1);
GO

-- ============================================================
-- 3. EMPLOYEES
-- ============================================================
INSERT INTO stg.employee
    (employee_id, nip, full_name, job_title, department, branch_id, join_date, is_active)
VALUES
    ('EMP-001', 'BFI-2010-001', 'Hendra Santoso',      'Branch Manager',       'Operations',        'BR-001', '2010-03-01', 1),
    ('EMP-002', 'BFI-2011-002', 'Dewi Kusumawati',     'Senior Loan Officer',  'Credit',            'BR-001', '2011-06-15', 1),
    ('EMP-003', 'BFI-2012-003', 'Rizky Firmansyah',    'Loan Officer',         'Credit',            'BR-001', '2012-09-01', 1),
    ('EMP-004', 'BFI-2013-004', 'Siti Rahayu',         'Loan Officer',         'Credit',            'BR-002', '2013-02-01', 1),
    ('EMP-005', 'BFI-2014-005', 'Ahmad Fauzi',         'Branch Manager',       'Operations',        'BR-002', '2014-07-01', 1),
    ('EMP-006', 'BFI-2015-006', 'Rina Wulandari',      'Loan Officer',         'Credit',            'BR-003', '2015-01-05', 1),
    ('EMP-007', 'BFI-2015-007', 'Budi Prasetyo',       'Senior Loan Officer',  'Credit',            'BR-004', '2015-04-01', 1),
    ('EMP-008', 'BFI-2016-008', 'Indah Permatasari',   'Loan Officer',         'Credit',            'BR-004', '2016-08-01', 1),
    ('EMP-009', 'BFI-2016-009', 'Doni Setiawan',       'Loan Officer',         'Credit',            'BR-005', '2016-11-01', 1),
    ('EMP-010', 'BFI-2017-010', 'Yuni Astuti',         'Branch Manager',       'Operations',        'BR-005', '2017-03-01', 1),
    ('EMP-011', 'BFI-2017-011', 'Wahyu Hidayat',       'Loan Officer',         'Credit',            'BR-006', '2017-07-01', 1),
    ('EMP-012', 'BFI-2018-012', 'Mega Putri',          'Loan Officer',         'Credit',            'BR-007', '2018-01-15', 1),
    ('EMP-013', 'BFI-2018-013', 'Agus Salim',          'Senior Loan Officer',  'Credit',            'BR-008', '2018-05-01', 1),
    ('EMP-014', 'BFI-2019-014', 'Lestari Ningrum',     'Loan Officer',         'Credit',            'BR-008', '2019-02-01', 1),
    ('EMP-015', 'BFI-2019-015', 'Fajar Nugroho',       'Collector',            'Collection',        'BR-001', '2019-08-01', 1),
    ('EMP-016', 'BFI-2020-016', 'Tini Sumarni',        'Collector',            'Collection',        'BR-002', '2020-01-06', 1),
    ('EMP-017', 'BFI-2020-017', 'Hendri Kurniawan',    'Loan Officer',         'Credit',            'BR-009', '2020-06-01', 1),
    ('EMP-018', 'BFI-2021-018', 'Okta Pratama',        'Branch Manager',       'Operations',        'BR-010', '2021-01-04', 1),
    ('EMP-019', 'BFI-2021-019', 'Sri Wahyuni',         'Loan Officer',         'Credit',            'BR-011', '2021-09-01', 1),
    ('EMP-020', 'BFI-2022-020', 'Andi Maulana',        'Loan Officer',         'Credit',            'BR-012', '2022-03-01', 1);
GO

-- ============================================================
-- 4. CUSTOMERS (30 synthetic records)
-- ============================================================
INSERT INTO stg.customer
    (customer_id, nik, full_name, date_of_birth, gender, marital_status,
     address_line1, kelurahan, kecamatan, kota_kabupaten, provinsi, kode_pos,
     phone_mobile, income_monthly, income_bracket, occupation, employer_name,
     risk_rating, is_blacklisted)
VALUES
    ('CUST-0001','3174011501880001','Budi Santoso',        '1988-01-15','M','MENIKAH',   'Jl. Mawar No. 5',         'Menteng',       'Menteng',         'Jakarta Pusat',    'DKI Jakarta',     '10310','081211110001',  8500000, 'MIDDLE', 'Karyawan Swasta',   'PT Maju Jaya',           'A', 0),
    ('CUST-0002','3271025502850002','Sari Dewi',           '1985-02-15','F','MENIKAH',   'Jl. Melati Blok C3',      'Kebon Jeruk',   'Kebon Jeruk',     'Jakarta Barat',    'DKI Jakarta',     '11530','081311110002', 12000000, 'MIDDLE', 'Wiraswasta',        'UD Sari Makmur',         'B', 0),
    ('CUST-0003','3273030312900003','Andika Putra',        '1990-12-03','M','LAJANG',    'Perum Griya Asri B-12',   'Cisaranteun',   'Cinambo',         'Kota Bandung',     'Jawa Barat',      '40294','082211110003',  5500000, 'MIDDLE', 'Karyawan Swasta',   'PT Tekstil Bandung',     'B', 0),
    ('CUST-0004','3578047807920004','Eko Wahyudi',         '1992-07-08','M','MENIKAH',   'Jl. Kenanga No. 17',      'Sawahan',       'Sawahan',         'Kota Surabaya',    'Jawa Timur',      '60251','083311110004', 15000000, 'UPPER',  'Wiraswasta',        'CV Eko Mandiri',         'A', 0),
    ('CUST-0005','3578052209950005','Fitri Handayani',     '1995-09-22','F','LAJANG',    'Jl. Dahlia No. 8',        'Wonokromo',     'Wonokromo',       'Kota Surabaya',    'Jawa Timur',      '60243','084411110005',  4500000, 'LOW',    'Karyawan Swasta',   'PT Surya Abadi',         'C', 0),
    ('CUST-0006','3374061408870006','Gunawan Hadi',        '1987-08-14','M','MENIKAH',   'Jl. Veteran No. 45',      'Semarang Tengah','Semarang Tengah','Kota Semarang',    'Jawa Tengah',     '50132','085511110006',  9000000, 'MIDDLE', 'PNS',               'Pemkot Semarang',        'A', 0),
    ('CUST-0007','1271072005830007','Harianto',            '1983-05-20','M','MENIKAH',   'Jl. Gajah Mada No. 100',  'Petisah Tengah','Medan Petisah',   'Kota Medan',       'Sumatera Utara',  '20112','086611110007', 11000000, 'MIDDLE', 'Wiraswasta',        'Toko Harianto',          'B', 0),
    ('CUST-0008','1671081711910008','Imelda Simanjuntak',  '1991-11-17','F','MENIKAH',   'Jl. Sudirman No. 33',     'Ilir Barat II', 'Ilir Barat II',   'Kota Palembang',   'Sumatera Selatan','30127','087711110008',  7000000, 'MIDDLE', 'Karyawan Swasta',   'PT Sriwijaya Motor',     'B', 0),
    ('CUST-0009','7371092203860009','Jamaluddin',          '1986-03-22','M','MENIKAH',   'Jl. Penghibur No. 5',     'Losari',        'Ujung Pandang',   'Kota Makassar',    'Sulawesi Selatan','90111','088811110009', 20000000, 'UPPER',  'Wiraswasta',        'CV Borneo Jaya',         'A', 0),
    ('CUST-0010','6471102801940010','Kartini Rahayu',      '1994-01-28','F','LAJANG',    'Jl. MT Haryono No. 22',   'Balikpapan Kota','Balikpapan Kota','Kota Balikpapan', 'Kalimantan Timur','76112','089911110010',  6500000, 'MIDDLE', 'Karyawan Swasta',   'PT Borneo Resources',    'B', 0),
    ('CUST-0011','3174011204960011','Luki Prasetia',       '1996-04-12','M','LAJANG',    'Jl. Cempaka No. 3',       'Cempaka Baru',  'Kemayoran',       'Jakarta Pusat',    'DKI Jakarta',     '10640','081011110011',  4000000, 'LOW',    'Karyawan Swasta',   'PT Media Digital',       'C', 0),
    ('CUST-0012','3273022603980012','Maria Susanti',       '1998-03-26','F','LAJANG',    'Jl. Anggrek No. 11',      'Cideng',        'Gambir',          'Jakarta Pusat',    'DKI Jakarta',     '10150','081112110012',  4500000, 'LOW',    'Karyawan Swasta',   'PT Ritel Nusantara',     'C', 0),
    ('CUST-0013','3578032108800013','Nugroho Adi',         '1980-08-21','M','MENIKAH',   'Jl. Raya Darmo No. 44',   'Dr. Sutomo',    'Tegalsari',       'Kota Surabaya',    'Jawa Timur',      '60264','081213110013', 25000000, 'UPPER',  'Direktur',          'PT Sumber Energi',       'A', 0),
    ('CUST-0014','3372031509830014','Oktavia Wulandari',   '1983-09-15','F','MENIKAH',   'Jl. Pemuda No. 66',       'Pekunden',      'Semarang Tengah', 'Kota Semarang',    'Jawa Tengah',     '50139','081214110014',  8000000, 'MIDDLE', 'Dosen',             'Universitas Diponegoro', 'A', 0),
    ('CUST-0015','3175042906850015','Prayoga Santana',     '1985-06-29','M','MENIKAH',   'Jl. Flamboyan No. 7',     'Cilandak',      'Cilandak',        'Jakarta Selatan',  'DKI Jakarta',     '12430','081215110015', 18000000, 'UPPER',  'Konsultan',         'Self-employed',          'A', 0),
    ('CUST-0016','3274050105910016','Qistina Azahra',      '1991-05-01','F','MENIKAH',   'Jl. Bukit Indah No. 15',  'Antapani Kidul','Antapani',        'Kota Bandung',     'Jawa Barat',      '40291','081216110016',  7500000, 'MIDDLE', 'Bidan',             'RSUD Kota Bandung',      'B', 0),
    ('CUST-0017','3571020302930017','Rudi Hartono',        '1993-02-03','M','LAJANG',    'Jl. Kertajaya No. 10',    'Airlangga',     'Gubeng',          'Kota Surabaya',    'Jawa Timur',      '60286','081217110017',  5000000, 'MIDDLE', 'Karyawan Swasta',   'PT Surabaya Tekstil',    'B', 0),
    ('CUST-0018','1271031201890018','Sinaga Parlindungan', '1989-01-12','M','MENIKAH',   'Jl. Imam Bonjol No. 8',   'Petisah Hulu',  'Medan Baru',      'Kota Medan',       'Sumatera Utara',  '20153','081218110018', 13500000, 'MIDDLE', 'Kontraktor',        'CV Sinaga Konstruksi',   'B', 0),
    ('CUST-0019','3276062807970019','Tika Lestari',        '1997-07-28','F','LAJANG',    'Jl. Anyer No. 3',         'Neglasari',     'Neglasari',       'Kota Tangerang',   'Banten',          '15129','081219110019',  3500000, 'LOW',    'Karyawan Swasta',   'PT Garmen Tangerang',    'C', 0),
    ('CUST-0020','3578071106960020','Umar Bakri',          '1996-06-11','M','MENIKAH',   'Jl. Kapas No. 5',         'Kapas Krampung','Tambaksari',      'Kota Surabaya',    'Jawa Timur',      '60133','081220110020',  6000000, 'MIDDLE', 'Karyawan Swasta',   'PT Jasa Marga',          'B', 0),
    -- Additional customers for SCD scenarios
    ('CUST-0021','3174021507840021','Vina Melinda',        '1984-07-15','F','CERAI',     'Jl. Cikini No. 20',       'Cikini',        'Menteng',         'Jakarta Pusat',    'DKI Jakarta',     '10330','081221110021', 10000000, 'MIDDLE', 'Pegawai BUMN',      'PT Pertamina',           'A', 0),
    ('CUST-0022','3175012808920022','Wibowo Tanoto',       '1992-08-28','M','MENIKAH',   'Jl. Fatmawati No. 18',    'Cilandak Barat','Cilandak',        'Jakarta Selatan',  'DKI Jakarta',     '12440','081222110022', 16000000, 'UPPER',  'Manajer',           'PT Bank Mandiri',        'A', 0),
    ('CUST-0023','3273031403810023','Xenia Halim',         '1981-03-14','F','MENIKAH',   'Jl. Braga No. 40',        'Braga',         'Sumur Bandung',   'Kota Bandung',     'Jawa Barat',      '40111','081223110023', 22000000, 'UPPER',  'Dokter',            'RS Hasan Sadikin',       'A', 0),
    ('CUST-0024','3578081602900024','Yusuf Hakim',         '1990-02-16','M','MENIKAH',   'Jl. Diponegoro No. 55',   'Darmo',         'Wonokromo',       'Kota Surabaya',    'Jawa Timur',      '60241','081224110024', 14000000, 'MIDDLE', 'Dosen',             'ITS Surabaya',           'A', 0),
    ('CUST-0025','1271082504930025','Zulfahmi Nasution',   '1993-04-25','M','MENIKAH',   'Jl. Gatot Subroto No. 7', 'Sei Sikambing B','Medan Sunggal',  'Kota Medan',       'Sumatera Utara',  '20122','081225110025',  9500000, 'MIDDLE', 'Wiraswasta',        'Toko Zul Elektronik',    'B', 0);
GO

-- ============================================================
-- 5. COLLATERALS (25 records)
-- ============================================================
INSERT INTO stg.collateral
    (collateral_id, collateral_type, brand, model, manufacture_year,
     color, plate_number, chassis_number, engine_number,
     appraised_value, condition_rating, appraised_date)
VALUES
    ('COL-0001', 'MOTOR',      'Honda',      'Vario 150',        2022, 'Putih',    'B 3421 ABC', 'MH1KF7230NK000001', 'KF72E3000001', 17500000,  'SANGAT_BAIK', '2024-01-10'),
    ('COL-0002', 'MOTOR',      'Yamaha',     'NMAX 155',         2021, 'Hitam',    'B 7654 DEF', 'MH3SG3224MJ000002', 'G3B4E1000002', 19000000,  'SANGAT_BAIK', '2024-01-11'),
    ('COL-0003', 'MOBIL',      'Toyota',     'Avanza',           2020, 'Silver',   'D 1234 ABC', 'MHFM8FH30LJ000003', 'W04ETGE00003', 175000000, 'BAIK',        '2024-01-12'),
    ('COL-0004', 'MOBIL',      'Honda',      'HR-V',             2022, 'Merah',    'L 5678 GHI', 'MHRRU3850NJ000004', 'L15B00000004', 285000000, 'SANGAT_BAIK', '2024-01-13'),
    ('COL-0005', 'MOBIL',      'Mitsubishi', 'Xpander',          2019, 'Putih',    'B 9012 JKL', 'MMBSUNK49KJ000005', '4A91000005',  175000000, 'BAIK',        '2024-01-14'),
    ('COL-0006', 'ALAT_BERAT', 'Komatsu',   'PC200-8',          2018, 'Kuning',   NULL,         'KMTPC200XXXX00006', 'S6D107000006',1500000000,'BAIK',        '2024-01-15'),
    ('COL-0007', 'ALAT_BERAT', 'CAT',       '320D',             2020, 'Kuning',   NULL,         'CATC320DXXX000007', 'C6.4000007',  2200000000,'SANGAT_BAIK', '2024-01-16'),
    ('COL-0008', 'MOTOR',      'Honda',      'Beat',             2023, 'Biru',     'B 2345 MNO', 'MH1JFP214PK000008', 'JFP2E000008', 16000000,  'BARU',        '2024-02-01'),
    ('COL-0009', 'MOTOR',      'Yamaha',     'Mio M3',           2022, 'Merah',    'F 4567 PQR', 'MH3SE8617NJ000009', 'E3G1E000009', 13500000,  'SANGAT_BAIK', '2024-02-02'),
    ('COL-0010', 'MOBIL',      'Daihatsu',  'Xenia',            2021, 'Hitam',    'K 8901 STU', 'MHKV1BA1XMJ000010', '3SZ000010',   135000000, 'BAIK',        '2024-02-03'),
    ('COL-0011', 'MOBIL',      'Toyota',     'Fortuner',         2022, 'Putih',    'B 1234 VWX', 'MHFJW8FK1NJ000011', '1GD000011',   455000000, 'SANGAT_BAIK', '2024-02-04'),
    ('COL-0012', 'MOTOR',      'Suzuki',     'Address',          2021, 'Hijau',    'AG 5678 YZ', 'MH8CF4PA2MJ000012', 'F3SB000012',  12000000,  'BAIK',        '2024-02-05'),
    ('COL-0013', 'MOBIL',      'Toyota',     'Innova',           2020, 'Silver',   'W 9012 AAA', 'MHFXW8FK0LJ000013', '2GD000013',   275000000, 'BAIK',        '2024-02-10'),
    ('COL-0014', 'ALAT_BERAT', 'Hino',      'FM260JD (Truk)',   2019, 'Merah',    'BK 3456 BBB','MJEFM26039K000014', 'J08E000014',  450000000, 'BAIK',        '2024-02-11'),
    ('COL-0015', 'MOTOR',      'Honda',      'CBR 150R',         2022, 'Merah Hitam','B 7890 CCC','MH1KC1310NJ000015','KC13E000015', 27500000,  'SANGAT_BAIK', '2024-03-01'),
    ('COL-0016', 'MOBIL',      'Suzuki',     'Ertiga',           2021, 'Biru',     'H 4567 DDD', 'MHYKZE81S1MJ000016','K15B000016',  185000000, 'BAIK',        '2024-03-02'),
    ('COL-0017', 'MOTOR',      'Yamaha',     'Aerox 155',        2023, 'Putih',    'N 2345 EEE', 'MH3SB0210PJ000017', 'SB02E000017', 21000000,  'BARU',        '2024-03-05'),
    ('COL-0018', 'MOBIL',      'Toyota',     'Agya',             2022, 'Merah',    'D 9012 FFF', 'MHFB2BA30NJ000018', 'K3VE000018',  115000000, 'SANGAT_BAIK', '2024-03-06'),
    ('COL-0019', 'ALAT_BERAT', 'Komatsu',   'WA200-8',          2021, 'Kuning',   NULL,         'KMTWH200XXXX00019', 'SAA6D107000019',1800000000,'SANGAT_BAIK','2024-03-07'),
    ('COL-0020', 'MOBIL',      'Honda',      'Brio',             2023, 'Putih',    'B 5678 GGG', 'MHRGK3860PJ000020', 'L12B000020',  135000000, 'BARU',        '2024-03-10'),
    ('COL-0021', 'MOTOR',      'Honda',      'PCX 160',          2022, 'Hitam',    'B 1357 HHH', 'MH1KF7218NK000021', 'KF71E000021', 28500000,  'SANGAT_BAIK', '2024-04-01'),
    ('COL-0022', 'MOBIL',      'Daihatsu',  'Terios',            2020, 'Silver',   'L 2468 III', 'MHKJ3CB30LJ000022', '3SZ000022',   155000000, 'BAIK',        '2024-04-02'),
    ('COL-0023', 'MOTOR',      'Yamaha',     'R15',              2023, 'Biru',     'W 3579 JJJ', 'MH3RH0210PJ000023', 'RH02E000023', 35000000,  'BARU',        '2024-04-03'),
    ('COL-0024', 'MOBIL',      'Mitsubishi', 'Pajero Sport',     2021, 'Hitam',    'D 4680 KKK', 'MMBGZYK49MJ000024', '4N14000024',  490000000, 'BAIK',        '2024-04-04'),
    ('COL-0025', 'MOTOR',      'Kawasaki',   'Ninja 250',        2022, 'Hijau',    'B 5791 LLL', 'JKAEX250AANA000025','EX250AE000025',35000000, 'SANGAT_BAIK', '2024-04-05');
GO

-- ============================================================
-- 6. LOAN APPLICATIONS (30 records spanning 2023-2024)
-- ============================================================
INSERT INTO stg.loan_application
    (loan_id, customer_id, product_id, branch_id, employee_id, collateral_id,
     application_date, approval_date, disbursement_date, loan_status,
     requested_amount, approved_amount, disbursed_amount,
     tenor_months, interest_rate, monthly_installment, total_payable,
     admin_fee, insurance_fee)
VALUES
    ('LOS-2023-000001','CUST-0001','PROD-001','BR-001','EMP-002','COL-0001','2023-01-10','2023-01-13','2023-01-15','DISBURSED', 17000000, 17000000, 17000000, 24, 22.00,  902917,  21670000,  255000,  510000),
    ('LOS-2023-000002','CUST-0003','PROD-002','BR-004','EMP-007','COL-0002','2023-01-20','2023-01-24','2023-01-26','DISBURSED', 19000000, 18000000, 18000000, 24, 26.00, 1015000,  24360000,  360000,  540000),
    ('LOS-2023-000003','CUST-0004','PROD-003','BR-005','EMP-009','COL-0003','2023-02-05','2023-02-09','2023-02-12','DISBURSED',175000000,170000000,170000000, 48, 18.00, 4979167, 238840000, 1700000, 3400000),
    ('LOS-2023-000004','CUST-0006','PROD-006','BR-007','EMP-012','COL-0006','2023-02-15','2023-02-20','2023-02-25','DISBURSED',1500000000,1500000000,1500000000,60,15.00,35700000,2142000000,11250000,22500000),
    ('LOS-2023-000005','CUST-0007','PROD-003','BR-008','EMP-013','COL-0005','2023-03-01','2023-03-05','2023-03-08','DISBURSED',175000000,160000000,160000000, 48, 18.00, 4686667, 224960000, 1600000, 3200000),
    ('LOS-2023-000006','CUST-0009','PROD-007','BR-010','EMP-018','COL-0011','2023-03-15','2023-03-20','2023-03-25','DISBURSED',450000000,430000000,430000000, 60, 17.50,10183333, 611000000, 3225000, 6450000),
    ('LOS-2023-000007','CUST-0010','PROD-001','BR-011','EMP-019','COL-0008','2023-04-01','2023-04-04','2023-04-06','DISBURSED', 15000000, 14500000, 14500000, 24, 22.00,  769375,  18465000,  217500,  435000),
    ('LOS-2023-000008','CUST-0012','PROD-002','BR-001','EMP-002','COL-0009','2023-04-15','2023-04-18','2023-04-20','DISBURSED', 13000000, 12000000, 12000000, 36, 26.00,  476000,  17136000,  240000,  360000),
    ('LOS-2023-000009','CUST-0013','PROD-004','BR-005','EMP-009','COL-0010','2023-05-02','2023-05-07','2023-05-10','DISBURSED',135000000,125000000,125000000, 48, 21.00, 3697917, 177500000, 1875000, 2500000),
    ('LOS-2023-000010','CUST-0014','PROD-008','BR-007','EMP-012',NULL,       '2023-05-20','2023-05-22','2023-05-24','DISBURSED',   8000000,  8000000,  8000000, 18, 28.00,  590000,  10620000,  200000,        0),
    ('LOS-2023-000011','CUST-0015','PROD-003','BR-002','EMP-004','COL-0013','2023-06-01','2023-06-06','2023-06-10','DISBURSED',275000000,260000000,260000000, 60, 18.00, 6093333, 365600000, 2600000, 5200000),
    ('LOS-2023-000012','CUST-0016','PROD-001','BR-004','EMP-007','COL-0012','2023-06-15','2023-06-18','2023-06-20','DISBURSED', 12000000, 11500000, 11500000, 24, 22.00,  610208,  14645000,  172500,  345000),
    ('LOS-2023-000013','CUST-0017','PROD-002','BR-005','EMP-009','COL-0009','2023-07-01','2023-07-04','2023-07-06','DISBURSED', 13000000, 12500000, 12500000, 36, 26.00,  495833,  17850000,  250000,  375000),
    ('LOS-2023-000014','CUST-0019','PROD-008','BR-012','EMP-020',NULL,       '2023-07-15','2023-07-17','2023-07-18','DISBURSED',   5000000,  5000000,  5000000, 12, 28.00,  477000,   5724000,  125000,        0),
    ('LOS-2023-000015','CUST-0020','PROD-001','BR-005','EMP-009','COL-0015','2023-08-01','2023-08-04','2023-08-06','DISBURSED', 27000000, 25000000, 25000000, 36, 22.00, 1054167,  37950000,  375000,  750000),
    ('LOS-2023-000016','CUST-0005','PROD-002','BR-005','EMP-009','COL-0017','2023-09-01',NULL,         NULL,        'REJECTED',  20000000,       NULL,      NULL, 24, NULL,       NULL,      NULL,       NULL,     NULL),
    ('LOS-2023-000017','CUST-0021','PROD-004','BR-001','EMP-003','COL-0016','2023-09-15','2023-09-20','2023-09-25','DISBURSED',185000000,175000000,175000000, 48, 21.00, 5177083, 248500000, 2625000, 4375000),
    ('LOS-2023-000018','CUST-0022','PROD-005','BR-002','EMP-004','COL-0014','2023-10-01','2023-10-06','2023-10-10','DISBURSED',450000000,420000000,420000000, 60, 16.00, 9240000, 554400000, 3150000, 6300000),
    ('LOS-2023-000019','CUST-0023','PROD-007','BR-004','EMP-007','COL-0024','2023-10-15','2023-10-20','2023-10-25','DISBURSED',490000000,480000000,480000000, 84, 17.50,10480000, 880320000, 6000000, 9600000),
    ('LOS-2023-000020','CUST-0024','PROD-003','BR-005','EMP-009','COL-0011','2023-11-01','2023-11-05','2023-11-08','DISBURSED',455000000,440000000,440000000, 60, 18.00,10306667, 618400000, 4400000, 8800000),
    -- 2024 loans
    ('LOS-2024-000001','CUST-0002','PROD-004','BR-001','EMP-003','COL-0004','2024-01-05','2024-01-09','2024-01-12','DISBURSED',285000000,270000000,270000000, 48, 21.00, 7987500, 383400000, 4050000, 6750000),
    ('LOS-2024-000002','CUST-0008','PROD-001','BR-009','EMP-017','COL-0008','2024-01-20','2024-01-23','2024-01-25','DISBURSED', 16000000, 15000000, 15000000, 24, 22.00,  796250,  19110000,  225000,  450000),
    ('LOS-2024-000003','CUST-0011','PROD-002','BR-001','EMP-002','COL-0009','2024-02-10','2024-02-13','2024-02-15','DISBURSED', 13000000, 11000000, 11000000, 24, 26.00,  620583,  14894000,  220000,  330000),
    ('LOS-2024-000004','CUST-0018','PROD-010','BR-008','EMP-013','COL-0014','2024-02-20','2024-02-25','2024-03-01','DISBURSED',450000000,430000000,430000000, 60, 19.00, 10920833, 655250000, 4300000, 8600000),
    ('LOS-2024-000005','CUST-0025','PROD-002','BR-008','EMP-013','COL-0017','2024-03-05','2024-03-08','2024-03-10','DISBURSED', 21000000, 20000000, 20000000, 36, 26.00,  793333,  28560000,  400000,  600000),
    ('LOS-2024-000006','CUST-0001','PROD-003','BR-001','EMP-002','COL-0003','2024-04-01','2024-04-05','2024-04-08','DISBURSED',175000000,170000000,170000000, 48, 18.00, 4979167, 238840000, 1700000, 3400000),
    ('LOS-2024-000007','CUST-0006','PROD-007','BR-007','EMP-012','COL-0022','2024-04-15','2024-04-20','2024-04-25','DISBURSED',155000000,150000000,150000000, 60, 17.50, 3562500, 213750000, 1875000, 3750000),
    ('LOS-2024-000008','CUST-0015','PROD-004','BR-002','EMP-004','COL-0013','2024-05-01','2024-05-06','2024-05-10','DISBURSED',275000000,260000000,260000000, 48, 21.00, 7696667, 369440000, 3900000, 6500000),
    ('LOS-2024-000009','CUST-0019','PROD-001','BR-012','EMP-020','COL-0021','2024-06-01','2024-06-04','2024-06-06','DISBURSED', 28000000, 26000000, 26000000, 36, 22.00, 1096333,  39468000,  390000,  780000),
    ('LOS-2024-000010','CUST-0005','PROD-009','BR-005','EMP-009',NULL,       '2024-06-15','2024-06-17','2024-06-18','DISBURSED',   7000000,  7000000,  7000000, 24, 28.00,  515833,  12380000,  175000,        0);
GO

-- ============================================================
-- 7. PAYMENTS (sample installments for first 6 months of 2023 loans)
-- ============================================================
-- Generate payments for LOS-2023-000001 (24-month, first 6 installments)
INSERT INTO stg.payment
    (payment_id, loan_id, customer_id, branch_id, installment_number,
     due_date, payment_date, scheduled_amount, paid_amount,
     payment_method, payment_channel, payment_status, dpd, penalty_amount, waiver_amount)
VALUES
    ('PAY-2023-0000001','LOS-2023-000001','CUST-0001','BR-001',1,'2023-02-15','2023-02-14',  902917,  902917,'TRANSFER',     'MOBILE_BANKING','PAID',      0, 0,       0),
    ('PAY-2023-0000002','LOS-2023-000001','CUST-0001','BR-001',2,'2023-03-15','2023-03-16',  902917,  902917,'TRANSFER',     'MOBILE_BANKING','PAID',      1, 0,       0),
    ('PAY-2023-0000003','LOS-2023-000001','CUST-0001','BR-001',3,'2023-04-15','2023-04-15',  902917,  902917,'AUTODEBET',    'ATM',           'PAID',      0, 0,       0),
    ('PAY-2023-0000004','LOS-2023-000001','CUST-0001','BR-001',4,'2023-05-15','2023-05-15',  902917,  902917,'AUTODEBET',    'ATM',           'PAID',      0, 0,       0),
    ('PAY-2023-0000005','LOS-2023-000001','CUST-0001','BR-001',5,'2023-06-15','2023-06-15',  902917,  902917,'AUTODEBET',    'ATM',           'PAID',      0, 0,       0),
    ('PAY-2023-0000006','LOS-2023-000001','CUST-0001','BR-001',6,'2023-07-15','2023-07-15',  902917,  902917,'AUTODEBET',    'ATM',           'PAID',      0, 0,       0),
    -- LOS-2023-000002 (24-month) — slightly late payer
    ('PAY-2023-0000007','LOS-2023-000002','CUST-0003','BR-004',1,'2023-02-26','2023-02-26',1015000, 1015000,'TUNAI',        'TELLER',        'PAID',      0, 0,       0),
    ('PAY-2023-0000008','LOS-2023-000002','CUST-0003','BR-004',2,'2023-03-26','2023-04-05',1015000, 1015000,'TUNAI',        'TELLER',        'PAID',     10, 10150,    0),
    ('PAY-2023-0000009','LOS-2023-000002','CUST-0003','BR-004',3,'2023-04-26','2023-04-26',1015000, 1015000,'TUNAI',        'TELLER',        'PAID',      0, 0,       0),
    ('PAY-2023-0000010','LOS-2023-000002','CUST-0003','BR-004',4,'2023-05-26','2023-06-15',1015000, 1015000,'TUNAI',        'TELLER',        'PAID',     20, 20300,    0),
    ('PAY-2023-0000011','LOS-2023-000002','CUST-0003','BR-004',5,'2023-06-26','2023-06-26',1015000, 1015000,'TUNAI',        'TELLER',        'PAID',      0, 0,       0),
    ('PAY-2023-0000012','LOS-2023-000002','CUST-0003','BR-004',6,'2023-07-26','2023-07-30',1015000, 1015000,'TUNAI',        'TELLER',        'PAID',      4, 4060,     0),
    -- LOS-2023-000003 (48-month motor vehicle) — good payer
    ('PAY-2023-0000013','LOS-2023-000003','CUST-0004','BR-005',1,'2023-03-12','2023-03-12',4979167, 4979167,'TRANSFER',     'INTERNET_BANKING','PAID',    0, 0,       0),
    ('PAY-2023-0000014','LOS-2023-000003','CUST-0004','BR-005',2,'2023-04-12','2023-04-12',4979167, 4979167,'TRANSFER',     'INTERNET_BANKING','PAID',    0, 0,       0),
    ('PAY-2023-0000015','LOS-2023-000003','CUST-0004','BR-005',3,'2023-05-12','2023-05-12',4979167, 4979167,'TRANSFER',     'INTERNET_BANKING','PAID',    0, 0,       0),
    ('PAY-2023-0000016','LOS-2023-000003','CUST-0004','BR-005',4,'2023-06-12','2023-06-12',4979167, 4979167,'TRANSFER',     'INTERNET_BANKING','PAID',    0, 0,       0),
    ('PAY-2023-0000017','LOS-2023-000003','CUST-0004','BR-005',5,'2023-07-12','2023-07-12',4979167, 4979167,'AUTODEBET',    'ATM',           'PAID',      0, 0,       0),
    ('PAY-2023-0000018','LOS-2023-000003','CUST-0004','BR-005',6,'2023-08-12','2023-08-12',4979167, 4979167,'AUTODEBET',    'ATM',           'PAID',      0, 0,       0),
    -- LOS-2023-000008 (problem payer — high DPD)
    ('PAY-2023-0000019','LOS-2023-000008','CUST-0012','BR-001',1,'2023-05-20','2023-05-20',  476000,  476000,'TUNAI',       'TELLER',        'PAID',      0, 0,       0),
    ('PAY-2023-0000020','LOS-2023-000008','CUST-0012','BR-001',2,'2023-06-20','2023-07-25',  476000,  238000,'TUNAI',       'TELLER',        'PARTIAL',  35, 16660,    0),
    ('PAY-2023-0000021','LOS-2023-000008','CUST-0012','BR-001',3,'2023-07-20',NULL,           476000,       0,NULL,          NULL,            'OVERDUE',  NULL, 0,      0),
    ('PAY-2023-0000022','LOS-2023-000008','CUST-0012','BR-001',4,'2023-08-20',NULL,           476000,       0,NULL,          NULL,            'OVERDUE',  NULL, 0,      0),
    -- LOS-2023-000011 good payer
    ('PAY-2023-0000023','LOS-2023-000011','CUST-0015','BR-002',1,'2023-07-10','2023-07-10',6093333, 6093333,'TRANSFER',    'MOBILE_BANKING','PAID',      0, 0,       0),
    ('PAY-2023-0000024','LOS-2023-000011','CUST-0015','BR-002',2,'2023-08-10','2023-08-10',6093333, 6093333,'TRANSFER',    'MOBILE_BANKING','PAID',      0, 0,       0),
    ('PAY-2023-0000025','LOS-2023-000011','CUST-0015','BR-002',3,'2023-09-10','2023-09-10',6093333, 6093333,'TRANSFER',    'MOBILE_BANKING','PAID',      0, 0,       0),
    ('PAY-2023-0000026','LOS-2023-000011','CUST-0015','BR-002',4,'2023-10-10','2023-10-10',6093333, 6093333,'TRANSFER',    'MOBILE_BANKING','PAID',      0, 0,       0),
    ('PAY-2023-0000027','LOS-2023-000011','CUST-0015','BR-002',5,'2023-11-10','2023-11-10',6093333, 6093333,'AUTODEBET',   'ATM',           'PAID',      0, 0,       0),
    ('PAY-2023-0000028','LOS-2023-000011','CUST-0015','BR-002',6,'2023-12-10','2023-12-10',6093333, 6093333,'AUTODEBET',   'ATM',           'PAID',      0, 0,       0),
    -- 2024 payments for LOS-2024-000001
    ('PAY-2024-0000001','LOS-2024-000001','CUST-0002','BR-001',1,'2024-02-12','2024-02-12',7987500, 7987500,'TRANSFER',    'INTERNET_BANKING','PAID',    0, 0,       0),
    ('PAY-2024-0000002','LOS-2024-000001','CUST-0002','BR-001',2,'2024-03-12','2024-03-12',7987500, 7987500,'TRANSFER',    'INTERNET_BANKING','PAID',    0, 0,       0),
    ('PAY-2024-0000003','LOS-2024-000001','CUST-0002','BR-001',3,'2024-04-12','2024-04-12',7987500, 7987500,'TRANSFER',    'INTERNET_BANKING','PAID',    0, 0,       0),
    ('PAY-2024-0000004','LOS-2024-000002','CUST-0008','BR-009',1,'2024-02-25','2024-02-25',  796250,  796250,'TUNAI',      'TELLER',        'PAID',      0, 0,       0),
    ('PAY-2024-0000005','LOS-2024-000002','CUST-0008','BR-009',2,'2024-03-25','2024-03-25',  796250,  796250,'TUNAI',      'TELLER',        'PAID',      0, 0,       0),
    ('PAY-2024-0000006','LOS-2024-000005','CUST-0025','BR-008',1,'2024-04-10','2024-04-10',  793333,  793333,'TRANSFER',   'MOBILE_BANKING','PAID',      0, 0,       0),
    ('PAY-2024-0000007','LOS-2024-000005','CUST-0025','BR-008',2,'2024-05-10','2024-05-10',  793333,  793333,'TRANSFER',   'MOBILE_BANKING','PAID',      0, 0,       0),
    ('PAY-2024-0000008','LOS-2024-000006','CUST-0001','BR-001',1,'2024-05-08','2024-05-08',4979167, 4979167,'AUTODEBET',   'ATM',           'PAID',      0, 0,       0),
    ('PAY-2024-0000009','LOS-2024-000006','CUST-0001','BR-001',2,'2024-06-08','2024-06-08',4979167, 4979167,'AUTODEBET',   'ATM',           'PAID',      0, 0,       0);
GO

PRINT 'All staging data seeded successfully.';
GO
