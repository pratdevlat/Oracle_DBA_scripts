-- SQL Script: Oracle RAC Cache Fusion Block State Monitor for L1 DBA
-- Purpose: To quickly understand the global state of data blocks in the buffer cache
--          across all RAC instances, focusing on current (XCUR, SCUR) and
--          Consistent Read (CR) blocks.

-- Best practice: Run this script while the database is active and experiencing typical load.

SET LINESIZE 200
SET PAGESIZE 100
COL INST_ID FORMAT 99 HEADING 'Inst|ID'
COL FILE# FORMAT 9999 HEADING 'File|Num'
COL BLOCK# FORMAT 999999 HEADING 'Block|Num'
COL OBJECT_NAME FORMAT A30 HEADING 'Object Name'
COL LOCAL_STATUS FORMAT A15 HEADING 'Local Buffer|Status'
COL GLOBAL_MODE FORMAT A10 HEADING 'Global|Mode'
COL GLOBAL_ROLE FORMAT A10 HEADING 'Global|Role'
COL PI_COUNT FORMAT 9999 HEADING 'Past|Images'
COL DIRTY FORMAT A5 HEADING 'Dirty?'

BREAK ON INST_ID SKIP 1

SELECT
    bh.inst_id,
    bh.file#,
    bh.block#,
    o.object_name,
    bh.status AS local_buffer_status,
    DECODE(le.mode_held,
           0, 'Null (N)',
           3, 'Shared (S)',
           5, 'Exclusive (X)',
           TO_CHAR(le.mode_held)
          ) AS global_mode,
    DECODE(le.role_held,
           1, 'Local (L)',
           2, 'Global (G)',
           TO_CHAR(le.role_held)
          ) AS global_role,
    le.pi_count,
    CASE WHEN bh.dirty = 'Y' THEN 'YES' ELSE 'NO' END AS dirty
FROM
    GV$BH bh
LEFT JOIN -- Use LEFT JOIN to ensure all BH entries are shown, even if no corresponding LE is found (rare for active blocks)
    GV$LOCK_ELEMENT le ON bh.inst_id = le.inst_id
                      AND bh.lock_element_addr = le.lock_element_addr
LEFT JOIN
    DBA_OBJECTS o ON bh.objd = o.data_object_id
WHERE
    bh.status IN ('xcur', 'scur', 'cr') -- Focus on active buffer cache blocks
    AND bh.objd IS NOT NULL             -- Exclude internal/system blocks without a clear object
ORDER BY
    bh.inst_id, bh.file#, bh.block#;
