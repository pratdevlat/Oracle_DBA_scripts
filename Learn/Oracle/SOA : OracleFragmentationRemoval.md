Oracle Database Fragmentation Removal SOP

1. Introduction & Purpose

Database fragmentation refers to the inefficient use of storage space resulting from frequent insertions, updates, and deletions, leading to scattered data (tables, indexes, LOBs).

Negative Impacts:
	•	Performance degradation
	•	Increased I/O operations
	•	Wasted storage space

This SOP provides structured guidance for safely and effectively managing and resolving fragmentation, including recommendations for operations both with and without downtime.

2. Scope
	•	Applicable Oracle versions: 11g, 12c, 19c, 21c.
	•	Fragmentation types covered: tables, indexes, and LOBs.

3. Prerequisites & Pre-Checks
	•	Permissions: DBA, SYSDBA, ALTER privileges.
	•	Monitoring Tools: AWR, ASH, custom scripts, OEM, third-party tools.
	•	Backup Strategy: Full, verified database backup mandatory.
	•	Change Management: Formal CR approval required.
	•	Resource Availability: Confirm adequate disk, CPU, and memory.
	•	Off-Peak Scheduling: Operations must be performed during designated maintenance windows.

4. Identifying & Analyzing Fragmentation

Table Fragmentation:

SELECT table_name, num_rows, blocks, empty_blocks,
       ROUND((empty_blocks/blocks)*100, 2) AS fragmentation_pct
FROM dba_tables WHERE empty_blocks > 0 ORDER BY fragmentation_pct DESC;

Interpretation: High fragmentation_pct indicates candidates for defragmentation.

Index Fragmentation:

SELECT index_name, blevel, leaf_blocks, clustering_factor
FROM dba_indexes WHERE blevel > 3 OR clustering_factor > leaf_blocks ORDER BY blevel DESC;

Interpretation: High BLEVEL or clustering_factor indicates index fragmentation.

LOB Fragmentation:

SELECT segment_name, tablespace_name, bytes/1024/1024 AS size_mb
FROM dba_segments WHERE segment_type LIKE 'LOB%';

Reporting:

Record results clearly in standardized documentation templates.

5. Recommendations & Fragmentation Removal Methods

Recommendation based on Downtime Availability:
	•	If Downtime is Available:
	•	Prefer methods such as ALTER TABLE MOVE, index rebuilds, or export/import processes.
	•	If Zero/Minimal Downtime is Required:
	•	Use online table redefinition (DBMS_REDEFINITION) or online index rebuilds.

Downtime Required Methods:

Table Defragmentation:
	•	ALTER TABLE MOVE:

ALTER TABLE schema.table_name MOVE TABLESPACE new_tablespace;

	•	Rebuild Indexes after MOVE:

ALTER INDEX schema.index_name REBUILD;

	•	EXPDP/IMPDP:

expdp username/password schemas=schema directory=dir dumpfile=table.dmp logfile=expdp.log
impdp username/password schemas=schema directory=dir dumpfile=table.dmp logfile=impdp.log

	•	CREATE TABLE AS SELECT (CTAS):

CREATE TABLE new_table AS SELECT * FROM old_table;
DROP TABLE old_table;
ALTER TABLE new_table RENAME TO old_table;

Rebuild indexes afterward.

Index Defragmentation:

ALTER INDEX schema.index_name REBUILD;
ALTER INDEX schema.index_name REBUILD PARTITION partition_name;

LOB Defragmentation:

ALTER TABLE schema.table_name MOVE LOB(lob_column) STORE AS (TABLESPACE lob_tablespace);

Zero/Minimal Downtime Methods:

Online Table Redefinition (DBMS_REDEFINITION):
	•	Check eligibility:

EXEC DBMS_REDEFINITION.CAN_REDEF_TABLE('schema', 'table_name');

	•	Start redefinition:

EXEC DBMS_REDEFINITION.START_REDEF_TABLE('schema', 'table_name', 'interim_table');

	•	Copy dependents:

EXEC DBMS_REDEFINITION.COPY_TABLE_DEPENDENTS('schema', 'table_name', 'interim_table');

	•	Finish redefinition:

EXEC DBMS_REDEFINITION.FINISH_REDEF_TABLE('schema', 'table_name', 'interim_table');

Online Index Rebuilds:

ALTER INDEX schema.index_name REBUILD ONLINE;

Partitioning Strategies:
	•	Split Partition:

ALTER TABLE schema.table_name SPLIT PARTITION partition_name AT (value) INTO (PARTITION new_partition1, PARTITION new_partition2);

	•	Merge Partitions:

ALTER TABLE schema.table_name MERGE PARTITIONS partition1, partition2 INTO PARTITION merged_partition;

	•	Drop Partition:

ALTER TABLE schema.table_name DROP PARTITION partition_name;

6. Post-Defragmentation Steps
	•	Gather Statistics:

EXEC DBMS_STATS.GATHER_TABLE_STATS('schema', 'table_name');
EXEC DBMS_STATS.GATHER_INDEX_STATS('schema', 'index_name');

	•	Performance Monitoring: Confirm improvement via AWR/ASH.
	•	Space Utilization Monitoring: Verify space reclamation.
	•	Application Testing: Smoke tests mandatory.
	•	Documentation: Record all operational details thoroughly.

7. Automation & Scripting
	•	Automate analysis and online rebuilds via DBMS_SCHEDULER.
	•	Manual oversight mandatory for ALTER MOVE and EXPDP/IMPDP operations.

8. Troubleshooting & Rollback
	•	Common issues: ORA- errors, space limitations.
	•	Immediate rollback:
	•	Restore from backup.
	•	Revert online operations using transaction logs if necessary.

9. Best Practices & Proactive Measures
	•	Regular monitoring schedule.
	•	Initial proper sizing of segments.
	•	Configure PCTFREE/PCTUSED effectively.
	•	Minimize frequent row deletions; use SHRINK SPACE cautiously.
	•	Implement strategic partitioning and archiving.
	•	Review and optimize application designs.

10. Roles & Responsibilities
	•	DBA: Execute defragmentation, monitor performance.
	•	Operations Team: Resource availability, infrastructure checks.
	•	Application Team: Post-operation application validation.

11. Definitions & Acronyms
	•	SOP: Standard Operating Procedure
	•	LOB: Large Object
	•	HWM: High Water Mark
	•	CR: Change Request

12. Revision History

Version	Date	Author	Description
1.2	YYYY-MM-DD	DBA Team	Added complete SQL/command examples for all methods