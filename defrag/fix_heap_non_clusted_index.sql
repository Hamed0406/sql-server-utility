DECLARE @DatabaseName NVARCHAR(256) = N'YourDBNAME';
DECLARE @SchemaName NVARCHAR(256), @TableName NVARCHAR(256), @IndexName NVARCHAR(256), @IndexId INT, @IndexTypeDesc NVARCHAR(256), @DynamicSQL NVARCHAR(MAX);

-- Cursor to iterate through all indexes in the database
DECLARE IndexCursor CURSOR FOR
SELECT
    SCHEMA_NAME(t.schema_id) AS SchemaName,
    t.name AS TableName,
    i.name AS IndexName,
    i.index_id AS IndexId,
    i.type_desc AS IndexTypeDesc
FROM
    sys.tables t
INNER JOIN
    sys.indexes i ON t.object_id = i.object_id
WHERE
    i.type IN (0, 1, 2) -- 0 = Heap, 1 = Clustered, 2 = Nonclustered
    AND t.is_ms_shipped = 0 -- Exclude system tables
ORDER BY
    t.name, i.index_id;

OPEN IndexCursor;

FETCH NEXT FROM IndexCursor INTO @SchemaName, @TableName, @IndexName, @IndexId, @IndexTypeDesc;

WHILE @@FETCH_STATUS = 0
BEGIN
    IF @IndexId = 0 -- Heap
    BEGIN
        SET @DynamicSQL = 'ALTER TABLE [' + @SchemaName + '].[' + @TableName + '] REBUILD;';
    END
    ELSE -- Clustered and Nonclustered Indexes
    BEGIN
        SET @DynamicSQL = 'ALTER INDEX [' + @IndexName + '] ON [' + @SchemaName + '].[' + @TableName + '] REBUILD;';
    END

    PRINT 'Executing: ' + @DynamicSQL;
    -- Uncomment the next line to actually execute the SQL statement. 
    EXEC sp_executesql @DynamicSQL;

    FETCH NEXT FROM IndexCursor INTO @SchemaName, @TableName, @IndexName, @IndexId, @IndexTypeDesc;
END

CLOSE IndexCursor;
DEALLOCATE IndexCursor;
