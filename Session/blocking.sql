SELECT s1.username || '@' || s1.machine
    || ' ( SID=' || s1.sid || ' )  is blocking '
    || s2.username || '@' || s2.machine || ' ( SID=' || s2.sid || ' ) ' AS blocking_status
    FROM gv$lock l1, gv$session s1, gv$lock l2, gv$session s2
    WHERE s1.sid=l1.sid AND s2.sid=l2.sid
    AND l1.BLOCK=1 AND l2.request > 0
    AND l1.id1 = l2.id1
    AND l1.id2 = l2.id2;
	
select sid, serial#, username,status from v$session where sid in ('holder','waiter');

-- OR --

select decode(request,0,'Holder: ','Waiter: ')||sid sess,
id1, id2, lmode, request, type
from gv$lock
where (id1, id2, type) in
(select id1, id2, type from gv$lock where request>0)
order by id1, request;

-- OR --

SELECT
   s.blocking_session, 
   s.sid, 
   s.serial#, 
   s.seconds_in_wait
FROM
   gv$session s
WHERE
   blocking_session IS NOT NULL;

-- OR --
   
SELECT 
   l1.sid || ' is blocking ' || l2.sid blocking_sessions
FROM 
   gv$lock l1, gv$lock l2
WHERE
   l1.block = 1 AND
   l2.request > 0 AND
   l1.id1 = l2.id1 AND
   l1.id2 = l2.id2;
   
-- OR --

SELECT sid, id1 FROM v$lock WHERE TYPE='TM';
SELECT object_name FROM dba_objects WHERE object_id='&object_id_from_above_output';
select sid,type,lmode,request,ctime,block from v$lock;
select blocking_session, sid, wait_class,
seconds_in_wait
from v$session
where blocking_session is not NULL
order by blocking_session;
