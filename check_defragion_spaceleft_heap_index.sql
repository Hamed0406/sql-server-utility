DECLARE @DatabaseName NVARCHAR(128);
DECLARE @DynamicSQL NVARCHAR(MAX);

DECLARE db_cursor CURSOR FOR 
SELECT name 
FROM sys.databases 
WHERE state = 0 -- Only include online databases
AND database_id > 4 -- Exclude system databases

OPEN db_cursor  
FETCH NEXT FROM db_cursor INTO @DatabaseName  

WHILE @@FETCH_STATUS = 0  
BEGIN  
    SET @DynamicSQL = '
        USE [' + @DatabaseName + '];

        SELECT 
            ''' + @DatabaseName + ''' AS [DatabaseName],
            dbschemas.[name] AS [SchemaName], 
            dbtables.[name] AS [TableName], 
            dbindexes.[name] AS [IndexName], 
            indexstats.index_type_desc AS [IndexType],
            indexstats.avg_fragmentation_in_percent AS [AvgFragmentationInPercent],
            indexstats.page_count AS [PageCount],
            indexstats.avg_page_space_used_in_percent AS [AvgPageSpaceUsedPercent],
            indexstats.record_count AS [RecordCount],
            (100 - indexstats.avg_page_space_used_in_percent) AS [SpaceLeftPercent]
        FROM 
            sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, ''DETAILED'') AS indexstats
        INNER JOIN 
            sys.tables dbtables ON dbtables.[object_id] = indexstats.[object_id]
        INNER JOIN 
            sys.schemas dbschemas ON dbtables.[schema_id] = dbschemas.[schema_id]
        INNER JOIN 
            sys.indexes AS dbindexes ON dbindexes.[object_id] = indexstats.[object_id]
            AND indexstats.index_id = dbindexes.index_id
        WHERE 
            indexstats.avg_fragmentation_in_percent > 5
        ORDER BY 
            indexstats.avg_fragmentation_in_percent DESC;'

    EXEC sp_executesql @DynamicSQL

    FETCH NEXT FROM db_cursor INTO @DatabaseName  
END  

CLOSE db_cursor  
DEALLOCATE db_cursor
