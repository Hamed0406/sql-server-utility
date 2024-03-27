DECLARE @SchemaName NVARCHAR(128);
DECLARE @TableName NVARCHAR(128);
DECLARE @SqlCmd NVARCHAR(MAX);

-- Cursor to iterate through all tables in the database
DECLARE tableCursor CURSOR FOR
SELECT TABLE_SCHEMA, TABLE_NAME
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_TYPE = 'BASE TABLE';

OPEN tableCursor;

FETCH NEXT FROM tableCursor INTO @SchemaName, @TableName;

WHILE @@FETCH_STATUS = 0
BEGIN
    -- Check if the table is a heap (no clustered index)
    IF (SELECT COUNT(*) FROM sys.indexes WHERE object_id = OBJECT_ID(@SchemaName+'.'+@TableName) AND index_id = 0) > 0
    BEGIN
        -- Build the SQL command to rebuild the heap
        SET @SqlCmd = 'ALTER TABLE [' + @SchemaName + '].[' + @TableName + '] REBUILD;';
        -- Execute the rebuild command
        EXEC sp_executesql @SqlCmd;
        -- Optionally, print a message
        PRINT 'Rebuilt heap: ' + @SchemaName + '.' + @TableName;
    END

    FETCH NEXT FROM tableCursor INTO @SchemaName, @TableName;
END

CLOSE tableCursor;
DEALLOCATE tableCursor;
