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

**** To find Blocking GOOD query 

set lines 750 pages 9999
col blocking_status for a100 
 select s1.inst_id,s2.inst_id,s1.username || '@' || s1.machine
 || ' ( SID=' || s1.sid || ' )  is blocking '
 || s2.username || '@' || s2.machine || ' ( SID=' || s2.sid || ' ) ' AS blocking_status
  from gv$lock l1, gv$session s1, gv$lock l2, gv$session s2
  where s1.sid=l1.sid and s2.sid=l2.sid and s1.inst_id=l1.inst_id and s2.inst_id=l2.inst_id
  and l1.BLOCK=1 and l2.request > 0
  and l1.id1 = l2.id1
  and l2.id2 = l2.id2
order by s1.inst_id;

**** Check who is blocking who in RAC, including objects

SELECT DECODE(request,0,'Holder: ','Waiter: ') || gv$lock.sid sess, machine, do.object_name as locked_object,id1, id2, lmode, request, gv$lock.type
FROM gv$lock join gv$session on gv$lock.sid=gv$session.sid and gv$lock.inst_id=gv$session.inst_id
join gv$locked_object lo on gv$lock.SID = lo.SESSION_ID and gv$lock.inst_id=lo.inst_id
join dba_objects do on lo.OBJECT_ID = do.OBJECT_ID 
WHERE (id1, id2, gv$lock.type) IN (
  SELECT id1, id2, type FROM gv$lock WHERE request>0)
ORDER BY id1, request;








