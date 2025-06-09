# Parallel Execution

Parallel execution is a feature available only in Oracle Enterprise Edition (not in Standard Edition).

Parallel execution refers to the ability to physically divide a large serial task (including all DML and general DDL) into multiple smaller parts, which can be processed simultaneously.
- Parallel query: This refers to the ability to use multiple operating system processes or threads to execute a query. Oracle will identify operations that can be executed in parallel (such as full table scans or large-scale sorting) and create a query plan to achieve parallel execution.
- Parallel DML (PDML): This is essentially very similar to parallel query, but PDML primarily uses parallel processing to perform modifications (INSERT, UPDATE, DELETE, and MERGE).
- Parallel DDL: Parallel DDL refers to Oracle's ability to execute large-scale DDL operations in parallel. For example, index rebuilding, creating a new index, data loading via CREATE TABLE AS SELECT, and reorganization of large tables can all use parallel processing.
- Parallel loading: External tables and SQL\*Loader can load data in parallel.
- Procedural parallelization: This refers to the ability to run developed code in parallel.

There are also two other operations that can be implemented in parallel:
- Parallel recovery: Oracle can parallelize database recovery operations.
- Parallel propagation: Parallel execution also has a more typical data replication scenario, where Oracle Advanced Replication options can perform asynchronous parallel replication, and parallel mode can significantly improve the throughput of data replication operations.

## When to Use Parallel Execution

>The parallel query (PARALLEL QUERY) option is inherently not scalable.

Parallel execution is inherently a non-scalable solution, designed to allow a single user or a specific SQL statement to occupy all database resources. If a feature allows one person to use all available resources, running two people using this feature will encounter significant contention issues. As the number of concurrent users on the system increases, the...
