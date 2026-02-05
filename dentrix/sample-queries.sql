-- ============================================================================
-- DENTRIX ADAPTER SQL QUERIES
-- ============================================================================
-- Epic: Enhancing Compliance Monitoring and Audit Capabilities
-- Ticket: T2.4 - Dentrix Schema Research & Mapping
-- Database: Microsoft SQL Server 2016+
-- ============================================================================

-- ────────────────────────────────────────────────────────────────────────────
-- SECTION 1: SCHEMA DISCOVERY QUERIES
-- ────────────────────────────────────────────────────────────────────────────
-- Run these queries to validate/discover the actual Dentrix schema

-- 1.1 List all databases (find DXHistory, DXSecurity, DentalData)
SELECT name, database_id, create_date
FROM sys.databases
WHERE name LIKE 'DX%' OR name LIKE 'Dental%'
ORDER BY name;

-- 1.2 List tables in DXHistory (audit tables)
USE DXHistory;
GO
SELECT 
    TABLE_SCHEMA,
    TABLE_NAME,
    TABLE_TYPE
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_TYPE = 'BASE TABLE'
ORDER BY TABLE_NAME;

-- 1.3 Get SecurityLog column definitions
USE DXHistory;
GO
SELECT 
    COLUMN_NAME,
    DATA_TYPE,
    IS_NULLABLE,
    CHARACTER_MAXIMUM_LENGTH,
    NUMERIC_PRECISION,
    COLUMN_DEFAULT
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'SecurityLog'
ORDER BY ORDINAL_POSITION;

-- 1.4 Discover unique EventType values (critical for permission mapping)
USE DXHistory;
GO
SELECT 
    EventType,
    COUNT(*) AS EventCount,
    MIN(LogDateTime) AS FirstSeen,
    MAX(LogDateTime) AS LastSeen
FROM SecurityLog
WHERE LogDateTime > DATEADD(DAY, -90, GETDATE())
GROUP BY EventType
ORDER BY EventCount DESC;

-- 1.5 Sample SecurityLog data (for schema validation)
USE DXHistory;
GO
SELECT TOP 100
    SecurityLogID,
    LogDateTime,
    PatientID,
    UserID,
    EventType,
    WorkstationID,
    Description,
    SourceModule,
    OldValue,
    NewValue,
    FieldName,
    IPAddress,
    SessionID
FROM SecurityLog
ORDER BY LogDateTime DESC;


-- ────────────────────────────────────────────────────────────────────────────
-- SECTION 2: PRIMARY AUDIT POLLING QUERY
-- ────────────────────────────────────────────────────────────────────────────
-- Equivalent to Open Dental's AUDIT_QUERY in poller.ts

-- 2.1 Main audit log query with user/provider context
-- Parameters:
--   @LastCursorTime: datetime2 - Last processed event timestamp
--   @BatchSize: int - Number of records to fetch (default 1000)

DECLARE @LastCursorTime datetime2 = '2024-01-01 00:00:00';
DECLARE @BatchSize int = 1000;
DECLARE @OverlapMinutes int = 2;

SELECT
    sl.SecurityLogID,
    sl.LogDateTime,
    sl.PatientID,
    sl.UserID,
    u.UserName,
    u.ProviderID,
    sl.EventType,
    sl.WorkstationID,
    sl.Description,
    sl.SourceModule,
    sl.OldValue,
    sl.NewValue,
    sl.FieldName,
    sl.IPAddress,
    sl.SessionID,
    p.FirstName AS ProviderFirstName,
    p.LastName AS ProviderLastName,
    p.Suffix AS ProviderSuffix
FROM [DXHistory].[dbo].[SecurityLog] sl
LEFT JOIN [DXSecurity].[dbo].[Users] u 
    ON sl.UserID = u.UserID
LEFT JOIN [DentalData].[dbo].[Providers] p 
    ON u.ProviderID = p.ProviderID
WHERE sl.LogDateTime > DATEADD(MINUTE, -@OverlapMinutes, @LastCursorTime)
ORDER BY sl.LogDateTime ASC, sl.SecurityLogID ASC
OFFSET 0 ROWS FETCH NEXT @BatchSize ROWS ONLY;


-- ────────────────────────────────────────────────────────────────────────────
-- SECTION 3: PATIENT ACCESS LOG QUERY
-- ────────────────────────────────────────────────────────────────────────────
-- Secondary audit source for detailed PHI access tracking

-- 3.1 Patient access log with user context
DECLARE @AccessCursorTime datetime2 = '2024-01-01 00:00:00';
DECLARE @AccessBatchSize int = 1000;

SELECT
    pal.AccessLogID,
    pal.PatientID,
    pal.UserID,
    u.UserName,
    pal.AccessDateTime,
    pal.AccessType,
    pal.ModuleAccessed,
    pal.WorkstationID,
    u.ProviderID,
    p.FirstName AS ProviderFirstName,
    p.LastName AS ProviderLastName
FROM [DXHistory].[dbo].[PatientAccessLog] pal
LEFT JOIN [DXSecurity].[dbo].[Users] u 
    ON pal.UserID = u.UserID
LEFT JOIN [DentalData].[dbo].[Providers] p 
    ON u.ProviderID = p.ProviderID
WHERE pal.AccessDateTime > @AccessCursorTime
ORDER BY pal.AccessDateTime ASC, pal.AccessLogID ASC
OFFSET 0 ROWS FETCH NEXT @AccessBatchSize ROWS ONLY;


-- ────────────────────────────────────────────────────────────────────────────
-- SECTION 4: AUTHENTICATION EVENT QUERIES
-- ────────────────────────────────────────────────────────────────────────────
-- For login/logout tracking (HIPAA §164.312(d))

-- 4.1 Login events with details
SELECT
    sl.SecurityLogID,
    sl.LogDateTime,
    sl.UserID,
    u.UserName,
    u.FirstName,
    u.LastName,
    sl.EventType,
    CASE sl.EventType
        WHEN 100 THEN 'Login'
        WHEN 101 THEN 'Logout'
        WHEN 102 THEN 'Failed Login'
        WHEN 103 THEN 'Password Changed'
        WHEN 104 THEN 'Session Timeout'
        WHEN 105 THEN 'Force Logout'
    END AS EventName,
    sl.WorkstationID,
    sl.IPAddress,
    sl.SessionID,
    sl.Description
FROM [DXHistory].[dbo].[SecurityLog] sl
LEFT JOIN [DXSecurity].[dbo].[Users] u 
    ON sl.UserID = u.UserID
WHERE sl.EventType BETWEEN 100 AND 199
    AND sl.LogDateTime > DATEADD(DAY, -7, GETDATE())
ORDER BY sl.LogDateTime DESC;

-- 4.2 Failed login attempts (security monitoring)
SELECT
    sl.LogDateTime,
    sl.WorkstationID,
    sl.IPAddress,
    sl.Description,
    COUNT(*) OVER (
        PARTITION BY sl.IPAddress 
        ORDER BY sl.LogDateTime 
        ROWS BETWEEN 9 PRECEDING AND CURRENT ROW
    ) AS RecentFailedAttempts
FROM [DXHistory].[dbo].[SecurityLog] sl
WHERE sl.EventType = 102  -- LoginFailed
    AND sl.LogDateTime > DATEADD(HOUR, -24, GETDATE())
ORDER BY sl.LogDateTime DESC;


-- ────────────────────────────────────────────────────────────────────────────
-- SECTION 5: SECURITY/ADMIN EVENT QUERIES
-- ────────────────────────────────────────────────────────────────────────────
-- For permission changes (HIPAA §164.308(a)(4))

-- 5.1 User and permission changes
SELECT
    sl.SecurityLogID,
    sl.LogDateTime,
    sl.UserID AS ActorUserID,
    u.UserName AS ActorUserName,
    sl.EventType,
    CASE sl.EventType
        WHEN 400 THEN 'User Created'
        WHEN 401 THEN 'User Modified'
        WHEN 402 THEN 'User Deleted'
        WHEN 403 THEN 'Role Assigned'
        WHEN 404 THEN 'Role Revoked'
        WHEN 405 THEN 'Permission Granted'
        WHEN 406 THEN 'Permission Revoked'
        WHEN 410 THEN 'Security Setting Changed'
    END AS EventName,
    sl.Description,
    sl.OldValue,
    sl.NewValue,
    sl.FieldName
FROM [DXHistory].[dbo].[SecurityLog] sl
LEFT JOIN [DXSecurity].[dbo].[Users] u 
    ON sl.UserID = u.UserID
WHERE sl.EventType BETWEEN 400 AND 499
    AND sl.LogDateTime > DATEADD(DAY, -30, GETDATE())
ORDER BY sl.LogDateTime DESC;


-- ────────────────────────────────────────────────────────────────────────────
-- SECTION 6: DATA EXPORT EVENT QUERIES
-- ────────────────────────────────────────────────────────────────────────────
-- For transmission security (HIPAA §164.312(e))

-- 6.1 Data export events (potential PHI disclosure)
SELECT
    sl.SecurityLogID,
    sl.LogDateTime,
    sl.PatientID,
    sl.UserID,
    u.UserName,
    sl.EventType,
    CASE sl.EventType
        WHEN 500 THEN 'Report Generated'
        WHEN 501 THEN 'Report Exported'
        WHEN 502 THEN 'Data Exported'
        WHEN 503 THEN 'Email Sent'
        WHEN 510 THEN 'Patient List Exported'
    END AS EventName,
    sl.Description,
    sl.WorkstationID
FROM [DXHistory].[dbo].[SecurityLog] sl
LEFT JOIN [DXSecurity].[dbo].[Users] u 
    ON sl.UserID = u.UserID
WHERE sl.EventType BETWEEN 500 AND 599
    AND sl.LogDateTime > DATEADD(DAY, -30, GETDATE())
ORDER BY sl.LogDateTime DESC;


-- ────────────────────────────────────────────────────────────────────────────
-- SECTION 7: CONNECTION TEST QUERY
-- ────────────────────────────────────────────────────────────────────────────
-- Used by adapter to verify connectivity

-- 7.1 Simple connection test with event count
SELECT
    'Connected' AS Status,
    DB_NAME() AS CurrentDatabase,
    @@VERSION AS SQLServerVersion,
    GETDATE() AS ServerDateTime,
    (SELECT COUNT(*) 
     FROM [DXHistory].[dbo].[SecurityLog]
     WHERE LogDateTime > DATEADD(HOUR, -24, GETDATE())
    ) AS Events24Hours,
    (SELECT COUNT(DISTINCT UserID) 
     FROM [DXHistory].[dbo].[SecurityLog]
     WHERE LogDateTime > DATEADD(HOUR, -24, GETDATE())
    ) AS ActiveUsers24Hours;


-- ────────────────────────────────────────────────────────────────────────────
-- SECTION 8: DATA QUALITY VALIDATION QUERIES
-- ────────────────────────────────────────────────────────────────────────────
-- Run these to assess data quality for compliance reporting

-- 8.1 Check for NULL values in critical fields
SELECT
    'SecurityLog NULL Analysis' AS Report,
    COUNT(*) AS TotalRecords,
    SUM(CASE WHEN UserID IS NULL THEN 1 ELSE 0 END) AS NullUserID,
    SUM(CASE WHEN PatientID IS NULL THEN 1 ELSE 0 END) AS NullPatientID,
    SUM(CASE WHEN WorkstationID IS NULL THEN 1 ELSE 0 END) AS NullWorkstation,
    SUM(CASE WHEN Description IS NULL OR Description = '' THEN 1 ELSE 0 END) AS NullDescription,
    SUM(CASE WHEN IPAddress IS NULL THEN 1 ELSE 0 END) AS NullIPAddress
FROM [DXHistory].[dbo].[SecurityLog]
WHERE LogDateTime > DATEADD(DAY, -90, GETDATE());

-- 8.2 EventType coverage analysis
SELECT
    CASE
        WHEN EventType BETWEEN 100 AND 199 THEN 'Authentication'
        WHEN EventType BETWEEN 200 AND 299 THEN 'Patient Record'
        WHEN EventType BETWEEN 300 AND 399 THEN 'Image/Document'
        WHEN EventType BETWEEN 400 AND 499 THEN 'Security/Admin'
        WHEN EventType BETWEEN 500 AND 599 THEN 'Data Export'
        WHEN EventType BETWEEN 600 AND 699 THEN 'System'
        ELSE 'Unknown'
    END AS EventCategory,
    COUNT(*) AS EventCount,
    COUNT(DISTINCT EventType) AS UniqueEventTypes
FROM [DXHistory].[dbo].[SecurityLog]
WHERE LogDateTime > DATEADD(DAY, -30, GETDATE())
GROUP BY 
    CASE
        WHEN EventType BETWEEN 100 AND 199 THEN 'Authentication'
        WHEN EventType BETWEEN 200 AND 299 THEN 'Patient Record'
        WHEN EventType BETWEEN 300 AND 399 THEN 'Image/Document'
        WHEN EventType BETWEEN 400 AND 499 THEN 'Security/Admin'
        WHEN EventType BETWEEN 500 AND 599 THEN 'Data Export'
        WHEN EventType BETWEEN 600 AND 699 THEN 'System'
        ELSE 'Unknown'
    END
ORDER BY EventCount DESC;

-- 8.3 User context join validation
SELECT
    COUNT(*) AS TotalSecurityLogs,
    SUM(CASE WHEN u.UserID IS NOT NULL THEN 1 ELSE 0 END) AS MatchedUsers,
    SUM(CASE WHEN u.UserID IS NULL AND sl.UserID IS NOT NULL THEN 1 ELSE 0 END) AS OrphanedUserRefs,
    SUM(CASE WHEN p.ProviderID IS NOT NULL THEN 1 ELSE 0 END) AS MatchedProviders
FROM [DXHistory].[dbo].[SecurityLog] sl
LEFT JOIN [DXSecurity].[dbo].[Users] u ON sl.UserID = u.UserID
LEFT JOIN [DentalData].[dbo].[Providers] p ON u.ProviderID = p.ProviderID
WHERE sl.LogDateTime > DATEADD(DAY, -30, GETDATE());


-- ────────────────────────────────────────────────────────────────────────────
-- SECTION 9: CURSOR MANAGEMENT QUERIES
-- ────────────────────────────────────────────────────────────────────────────
-- For implementing cursor-based polling

-- 9.1 Get the latest event (for initial cursor)
SELECT TOP 1
    SecurityLogID,
    LogDateTime
FROM [DXHistory].[dbo].[SecurityLog]
ORDER BY LogDateTime DESC, SecurityLogID DESC;

-- 9.2 Get oldest event (for backfill estimation)
SELECT TOP 1
    SecurityLogID,
    LogDateTime
FROM [DXHistory].[dbo].[SecurityLog]
ORDER BY LogDateTime ASC, SecurityLogID ASC;

-- 9.3 Estimate backlog size
DECLARE @CursorTime datetime2 = '2024-01-01 00:00:00';

SELECT
    COUNT(*) AS PendingEvents,
    MIN(LogDateTime) AS OldestPending,
    MAX(LogDateTime) AS NewestPending
FROM [DXHistory].[dbo].[SecurityLog]
WHERE LogDateTime > @CursorTime;


-- ────────────────────────────────────────────────────────────────────────────
-- SECTION 10: PERFORMANCE OPTIMIZATION
-- ────────────────────────────────────────────────────────────────────────────

-- 10.1 Check existing indexes
SELECT
    i.name AS IndexName,
    i.type_desc AS IndexType,
    c.name AS ColumnName,
    ic.is_included_column AS IsIncluded
FROM sys.indexes i
JOIN sys.index_columns ic ON i.object_id = ic.object_id AND i.index_id = ic.index_id
JOIN sys.columns c ON ic.object_id = c.object_id AND ic.column_id = c.column_id
WHERE i.object_id = OBJECT_ID('[DXHistory].[dbo].[SecurityLog]')
ORDER BY i.name, ic.key_ordinal;

-- 10.2 Recommended index for polling (if not exists)
-- CREATE INDEX IX_SecurityLog_LogDateTime_SecurityLogID 
-- ON [DXHistory].[dbo].[SecurityLog](LogDateTime, SecurityLogID)
-- INCLUDE (PatientID, UserID, EventType, WorkstationID, Description, SourceModule);

