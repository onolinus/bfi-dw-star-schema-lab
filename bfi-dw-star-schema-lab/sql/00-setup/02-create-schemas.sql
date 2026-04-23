-- =============================================================================
-- FILE   : 00-setup/02-create-schemas.sql
-- PURPOSE: Create logical schemas separating staging, warehouse, and reporting
-- TARGET : SQL Server 2019/2022
-- =============================================================================
-- Schema Layers:
--   STG  - Staging: raw data landed from source systems (transient)
--   DW   - Data Warehouse: cleansed dimensions and fact tables (persistent)
--   RPT  - Reporting: views and aggregates for BI tools (virtual layer)
-- =============================================================================

USE TrainingSQL;
GO

-- Staging layer: mirrors source system tables, no transformations
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'stg')
    EXEC sp_executesql N'CREATE SCHEMA stg AUTHORIZATION da_core;';
GO

-- Data Warehouse layer: conformed dimensions and fact tables
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'dw')
    EXEC sp_executesql N'CREATE SCHEMA dw AUTHORIZATION da_core;';
GO

-- Reporting layer: views, flattened tables for BI/Tableau/Power BI
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'rpt')
    EXEC sp_executesql N'CREATE SCHEMA rpt AUTHORIZATION da_core;';
GO

PRINT 'Schemas STG, DW, RPT created successfully.';
GO
