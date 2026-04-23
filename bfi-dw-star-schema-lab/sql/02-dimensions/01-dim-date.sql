-- =============================================================================
-- FILE   : 02-dimensions/01-dim-date.sql
-- PURPOSE: Create and fully populate the date dimension (2015–2030)
-- TARGET : SQL Server 2019/2022
-- NOTE   : Run this FIRST before any other dimension. Fact tables FK to this.
-- =============================================================================

USE TrainingSQL;
GO

-- Drop and recreate
DROP TABLE IF EXISTS dw.dim_date;
GO

CREATE TABLE dw.dim_date (
    date_sk             INT             NOT NULL,   -- surrogate key: YYYYMMDD
    full_date           DATE            NOT NULL,
    -- Calendar attributes
    day_of_month        TINYINT         NOT NULL,
    day_name_en         VARCHAR(10)     NOT NULL,   -- Monday, Tuesday...
    day_name_id         NVARCHAR(10)    NOT NULL,   -- Senin, Selasa...
    day_of_week         TINYINT         NOT NULL,   -- 1=Sunday, 7=Saturday (SQL default)
    day_of_year         SMALLINT        NOT NULL,
    is_weekday          BIT             NOT NULL,
    -- Week attributes
    week_of_year        TINYINT         NOT NULL,
    week_of_month       TINYINT         NOT NULL,
    iso_week            TINYINT         NOT NULL,
    -- Month attributes
    month_number        TINYINT         NOT NULL,
    month_name_en       VARCHAR(12)     NOT NULL,
    month_name_id       NVARCHAR(12)    NOT NULL,
    month_year          CHAR(7)         NOT NULL,   -- '2024-01'
    -- Quarter attributes
    quarter_number      TINYINT         NOT NULL,
    quarter_name        VARCHAR(8)      NOT NULL,   -- 'Q1 2024'
    -- Year attributes
    year_number         SMALLINT        NOT NULL,
    -- Fiscal year (BFI fiscal = calendar year Jan–Dec)
    fiscal_year         SMALLINT        NOT NULL,
    fiscal_quarter      TINYINT         NOT NULL,
    fiscal_month        TINYINT         NOT NULL,
    -- Relative flags
    is_last_day_of_month BIT            NOT NULL,
    is_first_day_of_month BIT           NOT NULL,
    is_holiday          BIT             NOT NULL DEFAULT 0,
    holiday_name        NVARCHAR(100)   NULL,
    -- Grouping helpers
    year_month_int      INT             NOT NULL,   -- YYYYMM
    CONSTRAINT PK_dim_date PRIMARY KEY CLUSTERED (date_sk)
);
GO

-- -----------------------------------------------------------------------
-- Populate dim_date for 2015-01-01 to 2030-12-31
-- -----------------------------------------------------------------------
DECLARE @start DATE = '2015-01-01';
DECLARE @end   DATE = '2030-12-31';
DECLARE @d     DATE = @start;

WHILE @d <= @end
BEGIN
    INSERT INTO dw.dim_date (
        date_sk, full_date,
        day_of_month, day_name_en, day_name_id, day_of_week, day_of_year, is_weekday,
        week_of_year, week_of_month, iso_week,
        month_number, month_name_en, month_name_id, month_year,
        quarter_number, quarter_name,
        year_number,
        fiscal_year, fiscal_quarter, fiscal_month,
        is_last_day_of_month, is_first_day_of_month,
        year_month_int
    )
    VALUES (
        CAST(FORMAT(@d, 'yyyyMMdd') AS INT),
        @d,
        DAY(@d),
        DATENAME(WEEKDAY, @d),
        CASE DATENAME(WEEKDAY, @d)
            WHEN 'Sunday'    THEN N'Minggu'
            WHEN 'Monday'    THEN N'Senin'
            WHEN 'Tuesday'   THEN N'Selasa'
            WHEN 'Wednesday' THEN N'Rabu'
            WHEN 'Thursday'  THEN N'Kamis'
            WHEN 'Friday'    THEN N'Jumat'
            WHEN 'Saturday'  THEN N'Sabtu'
        END,
        DATEPART(WEEKDAY, @d),
        DATEPART(DAYOFYEAR, @d),
        CASE WHEN DATEPART(WEEKDAY, @d) IN (1,7) THEN 0 ELSE 1 END,
        DATEPART(WEEK, @d),
        CEILING(DAY(@d) / 7.0),
        DATEPART(ISO_WEEK, @d),
        MONTH(@d),
        DATENAME(MONTH, @d),
        CASE MONTH(@d)
            WHEN 1  THEN N'Januari'   WHEN 2  THEN N'Februari'
            WHEN 3  THEN N'Maret'     WHEN 4  THEN N'April'
            WHEN 5  THEN N'Mei'       WHEN 6  THEN N'Juni'
            WHEN 7  THEN N'Juli'      WHEN 8  THEN N'Agustus'
            WHEN 9  THEN N'September' WHEN 10 THEN N'Oktober'
            WHEN 11 THEN N'November'  WHEN 12 THEN N'Desember'
        END,
        FORMAT(@d, 'yyyy-MM'),
        DATEPART(QUARTER, @d),
        'Q' + CAST(DATEPART(QUARTER, @d) AS CHAR(1)) + ' ' + CAST(YEAR(@d) AS CHAR(4)),
        YEAR(@d),
        YEAR(@d),                           -- fiscal year = calendar year
        DATEPART(QUARTER, @d),
        MONTH(@d),
        CASE WHEN @d = EOMONTH(@d) THEN 1 ELSE 0 END,
        CASE WHEN DAY(@d) = 1 THEN 1 ELSE 0 END,
        CAST(FORMAT(@d, 'yyyyMM') AS INT)
    );
    SET @d = DATEADD(DAY, 1, @d);
END
GO

-- -----------------------------------------------------------------------
-- Mark Indonesian national holidays (major ones — expand as needed)
-- Source: Peraturan Pemerintah / Surat Keputusan Bersama
-- -----------------------------------------------------------------------
UPDATE dw.dim_date SET is_holiday = 1, holiday_name = N'Tahun Baru'           WHERE month_number = 1  AND day_of_month = 1;
UPDATE dw.dim_date SET is_holiday = 1, holiday_name = N'Hari Buruh'           WHERE month_number = 5  AND day_of_month = 1;
UPDATE dw.dim_date SET is_holiday = 1, holiday_name = N'Hari Kemerdekaan RI'  WHERE month_number = 8  AND day_of_month = 17;
UPDATE dw.dim_date SET is_holiday = 1, holiday_name = N'Hari Natal'           WHERE month_number = 12 AND day_of_month = 25;
UPDATE dw.dim_date SET is_holiday = 1, holiday_name = N'Hari Natal (Cuti)'    WHERE month_number = 12 AND day_of_month = 26;
-- Specific fixed date holidays (Tahun Baru Masehi cuti, etc.)
UPDATE dw.dim_date SET is_holiday = 1, holiday_name = N'Hari Pancasila'       WHERE month_number = 6  AND day_of_month = 1;
UPDATE dw.dim_date SET is_holiday = 1, holiday_name = N'Hari Ibu'             WHERE month_number = 12 AND day_of_month = 22;
GO

-- Add special "unknown" date row for FK resolution
INSERT INTO dw.dim_date (
    date_sk, full_date, day_of_month, day_name_en, day_name_id,
    day_of_week, day_of_year, is_weekday,
    week_of_year, week_of_month, iso_week,
    month_number, month_name_en, month_name_id, month_year,
    quarter_number, quarter_name,
    year_number, fiscal_year, fiscal_quarter, fiscal_month,
    is_last_day_of_month, is_first_day_of_month,
    year_month_int
) VALUES (
    0, '1900-01-01', 1, 'Unknown', N'Tidak Diketahui',
    0, 0, 0,
    0, 0, 0,
    0, 'Unknown', N'Tidak Diketahui', '1900-01',
    0, 'Q0 1900',
    1900, 1900, 0, 0,
    0, 0,
    190001
);
GO

PRINT 'dim_date populated: ' + CAST((SELECT COUNT(*) FROM dw.dim_date) AS VARCHAR) + ' rows';
GO
