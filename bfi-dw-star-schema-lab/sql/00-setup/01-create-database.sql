-- =============================================================================
-- FILE   : 00-setup/01-create-database.sql
-- PURPOSE: Create the BFI Data Warehouse database with proper filegroups
-- TARGET : SQL Server 2019/2022 | Azure SQL Database | Azure Synapse
-- AUTHOR : BFI Data Core Team
-- DATE   : 2026-04-23
-- =============================================================================
-- CLOUD NOTE: On Azure SQL Database / Azure Synapse, skip the filegroup /
--             file size sections — storage is managed automatically.
--             Remove everything from ON [PRIMARY] ... LOG ON { ... }.
-- =============================================================================

USE master;
GO

-- Drop database if it exists (dev/lab use only — never in production)
IF EXISTS (SELECT 1 FROM sys.databases WHERE name = N'TrainingSQL')
BEGIN
    ALTER DATABASE TrainingSQL SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE TrainingSQL;
    PRINT 'Existing TrainingSQL database dropped.';
END
GO

CREATE DATABASE TrainingSQL
ON PRIMARY
(
    NAME    = N'TrainingSQL_Data',
    FILENAME = N'C:\SQLData\TrainingSQL.mdf',   -- adjust path for your environment
    SIZE    = 256MB,
    MAXSIZE = UNLIMITED,
    FILEGROWTH = 64MB
)
LOG ON
(
    NAME    = N'TrainingSQL_Log',
    FILENAME = N'C:\SQLData\TrainingSQL.ldf',   -- adjust path for your environment
    SIZE    = 64MB,
    MAXSIZE = 4GB,
    FILEGROWTH = 32MB
);
GO

-- Set recommended options for a data warehouse database
ALTER DATABASE TrainingSQL SET RECOVERY SIMPLE;          -- DW typically uses simple recovery
ALTER DATABASE TrainingSQL SET READ_COMMITTED_SNAPSHOT ON; -- Optimistic concurrency
ALTER DATABASE TrainingSQL SET AUTO_UPDATE_STATISTICS ON;
ALTER DATABASE TrainingSQL SET AUTO_CREATE_STATISTICS ON;
ALTER DATABASE TrainingSQL SET COMPATIBILITY_LEVEL = 150; -- SQL Server 2019
GO

PRINT 'Database TrainingSQL created successfully.';
GO
