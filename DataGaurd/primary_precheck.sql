
prompt " Check Max Sequence of All Threads:-"

SELECT THREAD#,MAX(SEQUENCE#) FROM V$ARCHIVED_LOG GROUP BY THREAD#;

prompt "Check for any errors on the Standby Destination"

column destination format a40
SELECT DEST_ID, DESTINATION ,status ,ERROR FROM V$ARCHIVE_DEST WHERE DESTINATION IS NOT NULL;
