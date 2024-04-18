-- Declare variables to hold the name of the database
DECLARE @DatabaseName NVARCHAR(256) = N'YourDatabaseName'; -- Replace YourDatabaseName with your actual database name

-- Dynamic SQL to set the context to the target database
DECLARE @DynamicSQL NVARCHAR(MAX) = N'USE [' + @DatabaseName + '];';

-- Append the main query to the dynamic SQL
SET @DynamicSQL = @DynamicSQL + N'
SELECT 
    DB_NAME() AS DatabaseName,
    OBJECT_SCHEMA_NAME(ips.OBJECT_ID) AS SchemaName,
    OBJECT_NAME(ips.OBJECT_ID) AS TableName,
    i.name AS IndexName,
    i.type_desc AS IndexType,
    ips.avg_fragmentation_in_percent AS FragmentationPercent,
    ips.page_count AS PageCount,
    ips.avg_page_space_used_in_percent AS AvgPageSpaceUsedPercent,
    (100 - ips.avg_page_space_used_in_percent) AS SpaceLeftPercent
FROM 
    sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, ''DETAILED'') ips
INNER JOIN 
    sys.indexes i ON ips.OBJECT_ID = i.OBJECT_ID AND ips.index_id = i.index_id
WHERE 
    ips.database_id = DB_ID()
    AND ips.page_count > 0 -- Considering only indexes with pages
ORDER BY 
    ips.avg_fragmentation_in_percent DESC;';

-- Execute the dynamic SQL
EXEC sp_executesql @DynamicSQL;
