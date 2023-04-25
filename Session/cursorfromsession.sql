    set pages 0 head off feed off lines 9999 trimsp on long 1000000
    col line for a2000
    select /*+ ordered */ chr(10)||rownum||' - '||s.sql_id||') '||sql_fulltext  as line
    from
            v$open_cursor o,
            v$sqlarea s
    where 
        o.sql_id=s.sql_id and 
        sid='&session_id';
