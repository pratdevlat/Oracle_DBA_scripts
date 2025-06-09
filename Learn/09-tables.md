# Database Tables

## Table Types

In Oracle, there are mainly the following 9 table types:
- Heap-organized table: This is a regular standard database table. Data is managed in it in a heap fashion. When data is added, the first free space in the segment that can accommodate the data is found and used. When data is deleted from the table, subsequent INSERTs and UPDATEs are allowed to reuse this space. This is where the name "heap" for this table type comes from. "Heap" refers to a set of spaces used in a somewhat random manner.
- Index-organized table (IOT): These tables are stored in an index structure. This enforces a physical order on the rows themselves. Unlike heap tables, where data can be placed anywhere as long as there is space, in an index-organized table (IOT), data must be stored in the IOT in primary key order.
- Index clustered table: A cluster refers to a group of one or more tables whose data is physically stored on the same database block. All rows with the same cluster key value are physically stored adjacent to each other. This structure achieves two goals. First, multiple tables can be physically stored together. Generally, you might think that a database block only contains data from one table, but for clustered tables, data from multiple tables might be stored in the same block. Second, all data containing the same cluster key value is physically stored together. Therefore, data is clustered together by the cluster key value, and the cluster key is built using a B*Tree index. The advantage of index clustered tables is that they can reduce disk I/O and improve query performance when multiple tables connected by a cluster key are frequently accessed.
- Hash clustered table: These tables are similar to index clustered tables, but instead of using a B*Tree index to locate data by the cluster key, a hash cluster hashes the key value to a cluster, directly finding the database block where the data should be. In a hash cluster, the data is the index. Hash clustered tables are suitable for frequent data reads based on key equality comparisons.
- Sorted hash clustered table: This table type was introduced in Oracle 10g. It combines some characteristics of hash clustered tables and IOTs. The concept is as follows: if your rows are hashed by a certain key value, and a series of records related to that key are written to the table in a specific sorted order and processed in that order.
- Nested table: Nested tables are part of Oracle's object-relational extensions. They are essentially child tables in a parent/child relationship that are system-generated and maintained.
- Temporary table: These tables store "draft" data during a transaction or session. Temporary tables allocate temporary segments from the current user's temporary tablespace as needed. Each session can only see the segments allocated to itself and will not see any data created by any other session. Temporary tables can be used to store temporary data, with the advantage that they generate significantly less redo compared to regular heap tables.
- Object table: Object tables are created based on an object type. They have special properties that non-object tables do not. Object tables are a special type of heap-organized table, index-organized table, and temporary table; Oracle uses these types of tables, and even nested tables, to build object tables. Additionally, nested tables are also a type of object table structure.
- External table: The data in these tables is not stored in the database but externally, meaning they are stored as regular operating system files. In Oracle 9i and later versions, external tables can be used to query files outside the database as if they were ordinary tables within the database.

Regardless of the table type, the following basic information applies:
- A table can have a maximum of 1000 columns. If a row contains more than 254 columns, Oracle internally stores it as multiple separate row pieces that point to each other, and these pieces must be reassembled into a complete row image when the row is used.
- The number of rows in a table is theoretically infinite, but due to other limitations, it cannot actually reach "infinite".
- A table can have as many indexes as there are permutations of columns.
- Even within a single database, there can be an infinite number of tables.

## Terminology

### Segment

A segment in Oracle is an object that occupies storage space on disk. There are many types of segments; the most common types are listed below:
- Cluster: This segment type can store multiple tables. There are two types of clusters: B*Tree clusters and hash clusters. Clusters are typically used to store related data from multiple tables, pre-joined and stored on the same database block; they can also be used to store related information for a single table. The term "cluster" refers to the ability of this segment to physically group related information together.
- Table: A table segment stores the data of a database table. This is probably the most commonly used segment type, often used in conjunction with index segments.
- Table partition or subpartition: This segment type is used for partitioning and is very similar to a table segment. A table partition or subpartition stores a portion of the data from a table. A partitioned table consists of one or more table partition segments, and a composite partitioned table consists of one or more table subpartition segments.
- Index: This segment type can store index structures.
- Index partition: Similar to table partitions, this segment type contains a portion of an index. A partitioned index consists of one or more index partition segments.
- LOB partition, LOB subpartition, LOB index, and LOB segment: LOB index and LOB segment types can store large object (LOB) structures. When partitioning a table that contains LOBs, the LOB segments are also partitioned, and LOB partition segments are used for this purpose.
- Nested table: This is the segment type specified for nested tables, which are a special type of child table in a parent/child relationship.
- Rollback segment and "Type2 undo" segment: Undone data is stored here. Rollback segments are segments manually created by DBAs. Type2 undo segments are automatically created and managed by Oracle.

### Segment Space Management

Starting from Oracle 9i, there are two methods for managing segment space:
- Manual Segment Space Management (MSSM): You set FREELISTS, FREELIST GROUPS, PCTUSED, and other parameters to control how space within segments is allocated, used, and reused.
- Automatic Segment Space Management (ASSM): You only need to control one parameter related to space usage, PCTFREE.

### High-Water Mark

If you imagine a table as a flat structure, or a series of blocks arranged from left to right, the High-Water Mark (HWM) is the rightmost block that has ever contained data.
