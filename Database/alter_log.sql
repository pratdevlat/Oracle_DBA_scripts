    define DAYS=1/24

    set feed off ver off pages 1000 line 199 trimsp on echo off trimsp on 

    col INST_ID for 99 head I
    col DATE_TIME  for a18
    col MODULE_ID  for a10 trunc
    col MESSAGE_GROUP for a15 trunc
    col MESSAGE_TEXT for a130
    col PROBLEM_KEY for a15 trunc

    SELECT
        INST_ID,
        to_char(ORIGINATING_TIMESTAMP,'mm-dd hh24:mi:ss.FF2') DATE_TIME,
        MODULE_ID,
        MESSAGE_GROUP,
        PROBLEM_KEY,
        rtrim(MESSAGE_TEXT) MESSAGE_TEXT
    FROM
        V$DIAG_ALERT_EXT
    WHERE
        COMPONENT_ID = 'rdbms'
        and originating_timestamp>sysdate-&DAYS
    order by originating_timestamp;
