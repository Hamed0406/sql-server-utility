--Blocking command:
 
use master           --  master..xp_readerrorlog 1 -- sp_who2 72 85 kill 201 --  dbcc inputbuffer(76) -- kill 59 dbcc opentran sp_lock dbcc tracestatus(-1)
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
select                     --  DBCC MEMORYSTATUS dbcc inputbuffer(58) DBCC TRACESTATUS (-1)
      r.session_id,
         s.loginame,
      r.start_time,
      s.hostname,
      --r.blocking_session_id,
         s.blocked,
      r.command,
      db_name(r.database_id) as Database_name,
      r.wait_type,
      --r.wait_time,
      --r.open_transaction_count,
      r.cpu_time,
      r.total_elapsed_time as 'time(ms)',
      r.percent_complete,
      SUBSTRING(t.text, (r.statement_start_offset/2)+1, 
        ((CASE r.statement_end_offset
          WHEN -1 THEN DATALENGTH(t.text)
         ELSE r.statement_end_offset
         END - r.statement_start_offset)/2) + 1) AS CurrentQuery,
         t.text as ParentQuery      
from sys.dm_exec_requests r
       cross apply sys.dm_exec_sql_text(r.sql_handle) t
       join sys.sysprocesses s on (r.session_id = s.spid)
where r.session_id > 50
and r.session_id != @@spid