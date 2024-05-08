
prompt "List Session ID for a Given OS Process ID."

 
SET PAUSE ON
SET PAUSE 'Press Return to Continue'
SET PAGESIZE 60
SET LINESIZE 300
 
SELECT
   CHR(10)||
   'Check for SESSION ID ---->  '||LPAD( s.sid, 4 )||CHR(10)||CHR(10) as "Session ID"
FROM
   v$session s, v$process p
WHERE
   p.addr = s.paddr AND
   p.spid = &Enter_OSPid
/
