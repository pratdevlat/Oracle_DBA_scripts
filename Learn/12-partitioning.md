# Partitioning

Partitioning allows a table or index to be physically divided into multiple smaller, more manageable pieces. Although a partitioned table or index may consist of dozens of physical partitions, from the perspective of the application accessing the database, it accesses a single logical table or index. Each partition is an independent object that can be processed individually or as part of a larger object.

## Partitioning Overview

Partitioning uses a "divide and conquer" approach, suitable for managing very large tables and indexes. Partitioning introduces the concept of a partition key. Data is distributed to corresponding partitions based on its partition key value. The method of partitioning can be based on a range of key values, a list of key values, or a hash function value of the partition key. Here are some benefits of partitioning:
- Improved data availability: This applies to any type of system, regardless of whether it is primarily an OLTP or data warehouse system.
- Breaking down large segments into smaller segments, thereby reducing management burden: Performing management operations on a 100GB table is much more burdensome than performing the same operation 10 times on individual 10GB table partitions. Additionally, by using partitioning, we can delete data without leaving fragmented space, thus eliminating the need to reorganize the table!
- Improved performance for certain queries: This is mainly for large data warehousing environments. By using partitioning, we can skip data in certain partitions, thereby narrowing the range of data that needs to be accessed and processed. However, this is not applicable in transactional systems, as such systems typically access only small amounts of data.
- Distributing data modifications across multiple partitions, thereby reducing contention on high-load OLTP systems: If an application experiences severe contention for a certain segment, we can divide it into multiple segments, which can proportionally reduce contention.

### Increased Availability

Increased availability stems from the independence of each partition. The availability (or unavailability) of one partition in a table (index) does not affect the availability of the table (index) itself. If your table (index) is partitioned, the query optimizer will be aware of this and eliminate unnecessary partitions from the execution plan. For example, if one partition in a large object is unavailable, but your query does not need that partition, Oracle can still successfully process the query.

### Reduced Management Burden

The partitioning mechanism reduces the management burden because performing the same operation on smaller objects is easier, faster, and consumes fewer resources compared to performing it on a large object.

### Enhanced Statement Performance

The third benefit of partitioning is its ability to enhance the performance of some SQL statements (SELECT, INSERT, UPDATE, DELETE, MERGE). These SQL statements fall into two categories: those that modify information and those that read information.

1. Parallel DML
Statements that modify data in the database can be executed in parallel (Parallel DML, PDML). When executed in PDML mode, Oracle uses multiple threads or processes to perform INSERT, UPDATE, DELETE, or MERGE, rather than executing them serially in a single process. On a multi-CPU host with sufficient I/O bandwidth, this large-scale operation...
