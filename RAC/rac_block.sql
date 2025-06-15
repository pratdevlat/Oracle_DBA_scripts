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

PROMPT
PROMPT -- Explanation for L1 DBAs:
PROMPT -- This report shows key information about data blocks in memory across all RAC instances.
PROMPT --
PROMPT -- INST_ID: The Oracle RAC instance ID where the block is located.
PROMPT -- FILE#:   The data file number where the block belongs.
PROMPT -- BLOCK#:  The block number within that data file.
PROMPT -- OBJECT_NAME: The table or index this block belongs to.
PROMPT --
PROMPT -- Local Buffer Status (from THIS instance's perspective):
PROMPT --   - XCUR (Exclusive Current): This instance has exclusive control, likely modifying the block.
PROMPT --                             This is where new data is written before commit.
PROMPT --   - SCUR (Shared Current): This instance is reading the most current version of the block.
PROMPT --                            Multiple instances can read concurrently.
PROMPT --   - CR (Consistent Read):  This is a snapshot of the block from a specific past time.
PROMPT --                            Used for queries to ensure data consistency.
PROMPT --                            It's NOT the most current version if changes are happening.
PROMPT --
PROMPT -- Global Mode (how the block is managed across the cluster):
PROMPT --   - Exclusive (X): Only ONE instance has write access to this block across the entire cluster.
PROMPT --                    (Always paired with Global Role)
PROMPT --   - Shared (S):    Multiple instances can read this block across the cluster.
PROMPT --                    (Always paired with Global Role)
PROMPT --   - Null (N):      The instance might be tracking the block but doesn't have an active lock for current access.
PROMPT --                    Could be for a CR block or a block recently released.
PROMPT --
PROMPT -- Global Role (how the block is handled globally):
PROMPT --   - Global (G): The Global Cache Service (GCS) actively tracks and manages this block's state
PROMPT --                 across all RAC instances. This is what enables Cache Fusion.
PROMPT --   - Local (L):  The block is primarily managed locally by the instance. Less common for active data blocks
PROMPT --                 in Cache Fusion unless it's a newly read block not yet shared.
PROMPT --
PROMPT -- Past Images (PI_COUNT):
PROMPT --   - If a block is 'Exclusive (X)' AND 'Global (G)', this count shows how many Consistent Read (CR)
PROMPT --     copies of this block have been sent to other instances. A higher number can indicate
PROMPT --     frequent concurrent reads on a block being modified.
PROMPT --
PROMPT -- Dirty?:
PROMPT --   - YES: The block has been modified in memory but not yet written to disk.
PROMPT --   - NO: The block has not been modified or its changes have been written to disk.
PROMPT --
PROMPT -- Look for:
PROMPT --   - High PI_COUNT on XCUR/Exclusive blocks: Indicates potential contention for a block that's being written to and read concurrently.
PROMPT --   - Many CR blocks: Normal for read-intensive workloads, showing Cache Fusion is providing consistent reads.
PROMPT --   - Any unexpected states: If you see something unusual, it might warrant further investigation.
