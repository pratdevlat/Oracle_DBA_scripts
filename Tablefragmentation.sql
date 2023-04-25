
----To remove fragmentation in an Oracle database, you can perform the following steps:

----1. Identify the tables and indexes with fragmentation using the following queries:

-- Tables withfragmentation 
SELECT OWNER, TABLE_NAME, PARTITION_NAME, AVG_ROW_LEN, BLOCKS, EMPTY_BLOCKS, NUM_ROWS FROM DBA_TAB_PARTITIONS WHERE(EMPTY_BLOCKS > 10OR(BLOCKS / (EMPTY_BLOCKS + 1)) > 2) ORDERBYTABLE_NAME; -- Indexes withfragmentation SELECTOWNER, INDEX_NAME, LEAF_BLOCKS, EMPTY_BLOCKS, AVG_LEAF_BLOCKS_PER_KEY FROMDBA_INDEXES WHERE(EMPTY_BLOCKS > 10OR(LEAF_BLOCKS / (EMPTY_BLOCKS + 1)) > 2) ORDERBYINDEX_NAME; 

----2. For each table or index with fragmentation, perform a rebuild operation using the following commands:


-- Rebuild table partitions
ALTER TABLE <table_name> MOVE PARTITION<partition_name>TABLESPACE <tablespace_name>; -- Rebuild index
ALTER INDEX <index_name> REBUILD TABLESPACE <tablespace_name>; 

----Note: You can also use the online rebuild option (i.e. "ALTER TABLE ... MOVE ... ONLINE" or "ALTER INDEX ... REBUILD ONLINE") to avoid downtime during the rebuild process.

----3. After the rebuild operation, update the database statistics using the following command:


EXEC DBMS_STATS.GATHER_DATABASE_STATS; 
----This will update the optimizer statistics for the tables and indexes, and help to improve the performance of queries against these objects.
----It's important to note that removing fragmentation in an Oracle database can be a resource-intensive operation and should be performed during off-peak hours to minimize impact on production systems.
