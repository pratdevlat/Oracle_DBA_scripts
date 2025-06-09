# Overview

## Database

A collection of operating system files or disks. Oracle 12c provides three different types of databases:
- **Single-tenant database**: Completely self-contained with a full set of data files, control files, redo log files, parameter files, etc. Contains all metadata, data, code, and all application-related metadata, data, and code. All Oracle databases prior to 12c are of this type.
- **Container or root database (CDB)**: Contains a full set of data files, control files, redo log files, and parameter files, but only used to store Oracle's own metadata, internal data, and internal code. It does not store application data or code, only Oracle-specific entities. This database is entirely self-contained and can be mounted and opened independently.
- **Pluggable database (PDB)**: Contains only data files and is not fully self-contained. It must be attached (plugged) to a container database (CDB) to be opened for read and write operations. This database holds only application metadata, objects, data, and code. It relies on the files (control files, redo logs, parameter files) from the CDB.

## Instance

An Oracle instance consists of a set of Oracle background processes/threads and a shared memory region, used by threads/processes running on the same computer. Oracle stores and maintains volatile, non-persistent content here (some of which may be flushed to disk). Importantly, a database instance can exist without disk storage.

Relationships between instances and databases:
- A single-tenant or container database can be mounted and opened by multiple instances, but an instance can only mount and open one database at any given time. An instance can mount and open at most one database during its entire lifecycle.
- For a pluggable database (PDB), it can only be associated with one container database (CDB) at any given time, and thus with one instance. After an instance opens and mounts a CDB, its contained PDBs will also use this instance. An instance can concurrently access multiple PDBs (up to approximately 250), meaning each instance can serve multiple PDBs simultaneously, but it can only open one CDB or single-tenant database at a time.

### Dedicated Server

The default mode of connection is the **dedicated server** mode. In this setup, Oracle creates a new process or thread for each user connection. Each user connecting to the database gets their own dedicated server process that receives and executes SQL over a network channel.

### Shared Server

Oracle also allows connections via **shared server**. In this mode, the database doesn't create new threads or processes for each user connection.

Oracle uses a pool of "shared processes" to serve multiple users. Shared server is effectively a connection pooling mechanism, sharing processes among sessions. Oracle utilizes one or more **dispatcher processes** to handle client requests. Client processes communicate over a network with a dispatcher, which places requests into a queue in the SGA. The first free shared server picks up the request and processes it. Upon completion, the shared server places responses back into the dispatcher's response queue. Dispatchers monitor this queue and return results to the client.

### Pluggable Database

A pluggable database (PDB) under the multitenant architecture comprises a set of non-self-contained data files, containing only application data and metadata. Oracle-specific data isn't stored here but resides in the container database (CDB). To use or query a PDB, it must be "plugged" into a CDB. The CDB contains only Oracle-specific necessary runtime data and metadata. PDB stores remaining data and metadata.

Oracle designed PDBs and multitenant architecture primarily to:
- Efficiently reduce resource usage by multiple databases/applications on a single host.
- Reduce DBA maintenance efforts for multiple databases/applications on a single host.

---

# Memory Structure

Oracle has three main memory structures:
- **System Global Area (SGA)**: This is a large shared memory segment that almost all Oracle processes need to access.
- **Process Global Area (PGA)**: This is a private memory area for a process or thread, which other processes/threads cannot access.
- **User Global Area (UGA)**: This memory area is associated with a specific session. It may be allocated in either the SGA or the PGA, depending on whether the database connection is using a shared server or a dedicated server. If a shared server is used, UGA is allocated in SGA; if a dedicated server is used, UGA is allocated in PGA.

## Process Global Area and User Global Area

PGA (Process Global Area) is a memory segment specific to a process. In other words, it is a private memory allocated to an operating system process or thread, preventing other processes or threads from accessing it. PGA is usually allocated using `malloc()` or `memmap()` and can dynamically expand or shrink during execution. PGA is never allocated in Oracle’s SGA; it is always allocated by the process or thread itself.

UGA (User Global Area) essentially represents the state of your session. It is a memory segment that remains accessible for your session throughout. The allocation of UGA depends entirely on how you connect to Oracle.

Since Oracle 9iR1, there have been two ways to manage non-UGA memory in PGA:
- **Manual PGA Memory Management**: You specify how much memory a process can use for sorting or hashing.
- **Automatic PGA Memory Management**: You tell Oracle how much total PGA memory it can try to use system-wide.

Since Oracle 11gR1, automatic PGA memory management can be implemented using two techniques:
- By setting the `PGA_AGGREGATE_TARGET` initialization parameter, you tell Oracle how much memory PGA can try to use instance-wide.
- By setting the `MEMORY_TARGET` initialization parameter, you tell Oracle the total memory (SGA and PGA combined) the instance should be allowed to use. The database determines the appropriate PGA size itself based on this parameter.

The amount of PGA memory allocated per process is typically determined based on total available memory and the number of competing processes. As workload increases, the memory allocated to individual work areas decreases. The database tries to ensure total PGA memory usage does not exceed the `PGA_AGGREGATE_TARGET`, but if necessary, it will exceed the limit to maintain database operations.

## System Global Area

Every Oracle database instance has a large memory structure called the **System Global Area (SGA)**. This is a large shared memory segment accessed by all Oracle processes.

SGA consists of several pools, including:
- **Java Pool**: A fixed-size memory allocated for the Java Virtual Machine running within the database. It can be dynamically resized.
- **Large Pool**: Used for session memory (UGA) in shared server connections, message buffers in parallel execution, and disk I/O buffers during RMAN backups. It can be dynamically resized.
- **Shared Pool**: Contains shared cursors, stored procedures, state objects, dictionary cache, and other shared data. It can be dynamically resized.
- **Streams Pool**: A memory pool dedicated to data transfer and sharing mechanisms. It can be dynamically resized.
- **"Null" Pool**: This unnamed pool includes block buffers (for caching database blocks), redo log buffers, and the fixed SGA area.

---

# Oracle Processes

Each process in Oracle performs a specific task (or a set of tasks), allocating memory (PGA) for itself to complete its operations. An Oracle instance primarily consists of three types of processes:
- **Server processes:** These processes complete work based on client requests.
- **Background processes:** These start with the database and handle maintenance tasks such as writing data blocks to disk, maintaining online redo logs, cleaning up aborted processes, and managing the automatic workload repository.
- **Slave processes:** Similar to background processes, they perform additional work on behalf of background or server processes.

## Server Processes

Server processes execute instructions from client sessions. They receive SQL statements sent by applications and execute them within the database.

## Background Processes

An Oracle instance consists of two parts: the **SGA (System Global Area)** and a group of **background processes**. These processes work behind the scenes to ensure smooth database operation.

Background processes fall into two categories: processes with specific tasks and those that handle various other responsibilities.

1. **PMON (Process Monitor):** Monitors processes.
2. **LREG (Listener Registration Process):** Registers database services with the listener.
3. **SMON (System Monitor):** Handles system recovery.
4. **RECO (Recoverer Process):** Manages distributed database recovery.
5. **CKPT (Checkpoint Process):** Tracks checkpoints.
6. **DBWn (Database Writer Process):** Writes modified data blocks to disk.
7. **LGWR (Log Writer Process):** Writes redo log records.
8. **ARCn (Archiver Process):** Archives redo log files.
9. **DIAG (Diagnostics Process):** Handles diagnostics information.
10. **FBDA (Flashback Data Archiver):** Manages flashback archives.
11. **DBRM (Database Resource Manager):** Manages database resources.
12. **GEN0 (Generic Task Executor):** Handles general-purpose tasks.
13. **Other Common Task-Specific Processes.**

## Slave Processes

1. **I/O Slave Process:** Simulates asynchronous I/O on systems or devices that do not support it.
2. **Pnnn (Parallel Query Execution Server):** Executes parallel queries.

---

# Locks and Latches

## What is a Lock?

A lock is used to manage concurrent access to shared resources.

## Lock Issues

### Lost Updates

A lost update is a classic database problem that occurs in multi-user computing environments. It happens when:
1. A transaction in Session1 retrieves a row and displays it to User1.
2. Another transaction in Session2 retrieves the same row and displays it to User2.
3. User1 modifies the row and commits the update.
4. User2 modifies the row and commits their update, overwriting User1’s changes.

The modifications made in Step 3 are lost due to this process.

### Pessimistic Locking

Pessimistic locking is applied before a user modifies the data. This method is only suitable in **stateful** or **connected** environments, where the application maintains a continuous connection with the database during the transaction.

### Optimistic Locking

Optimistic locking delays the locking action until just before an update is executed. Users modify displayed information without locking it beforehand. This method works in all environments but increases the chance of **update failures**. If the row has already changed, the user must start over.

### Blocking

Blocking occurs when a session holds a lock on a resource while another session requests the same resource. The requesting session is blocked until the locking session releases the resource.

Blocking typically happens with these DML operations:
**INSERT, UPDATE, DELETE, MERGE, SELECT... FOR UPDATE**.

## Types of Locks

### DML Locks

DML locks control access to rows during data manipulation.

#### TX Locks (Transaction Locks)

A **TX lock** is acquired when a transaction modifies data. It is associated with the row being modified and prevents other transactions from modifying the same row.

#### TM Locks (DML Enqueue)

A **TM lock** ensures that a table’s structure is not altered while its data is modified. Unlike TX locks (one per transaction), a TM lock is acquired for each modified table.

### DDL Locks

DDL operations automatically lock objects to protect their definitions.

There are three types of DDL locks:
- **Exclusive DDL Lock:** Prevents modifications to an object while it is in use.
- **Shared DDL Lock:** Allows data modification but prevents structural changes.
- **Breakable Parse Lock:** Registers dependencies between objects, invalidating dependent objects when the base object changes.

Most DDL operations use exclusive locks.

### Latches

A **latch** is a lightweight serialization mechanism that coordinates multi-user access to shared structures, such as buffer caches or shared pools.

Latches are held briefly and cleaned up by the **PMON** process if needed.

### Mutexes

A **mutex (mutual exclusion)** is similar to a latch but is more efficient. Mutexes require less memory and fewer instructions compared to latches.

### Manual Locking and User-Defined Locks

#### Manual Locking

Oracle allows manual locking with **SELECT ... FOR UPDATE** to lock rows explicitly.

Alternatively, tables can be locked manually using **LOCK TABLE** statements.

#### Custom Locks

The **DBMS_LOCK** package lets users create custom locks for application-specific needs.

---

# Concurrency and Multi-Version Control

## What is Concurrency Control?

Concurrency control refers to the set of mechanisms in a database that allow multiple users to access and modify data simultaneously. **Locks** are a core feature that Oracle uses to manage concurrent access to shared resources and prevent interference between database transactions.

Oracle employs several types of locks, summarized below:
- **TX (Transaction) Locks:** These are acquired when a transaction modifies data.
- **TM (DML Queue) Locks and DDL Locks:** TM locks protect objects from structural changes during modifications, while DDL locks safeguard object definitions.
- **Latches and Mutexes:** These are internal Oracle locks that regulate access to shared data structures.

Oracle does not just rely on efficient locking mechanisms—it also implements a **multi-version control architecture**, enabling controlled yet highly concurrent data access. Multi-version control allows Oracle to materialize multiple versions of data simultaneously, ensuring **consistent reads**.

By default, Oracle's multi-version read consistency is **statement-level**, but it can be adjusted to **transaction-level** if needed.

## Transaction Isolation Levels

The ANSI/ISO SQL standard defines **four transaction isolation levels**, each yielding different results for the same transaction. That means two identical transactions with the same inputs may produce entirely different outcomes based on isolation levels.

These isolation levels are defined by three "phenomena" that they may allow or disallow:
- **Dirty Read:** The ability to read uncommitted data, also known as dirty data. Dirty reads affect data integrity, can break foreign key constraints, and ignore uniqueness constraints.
- **Nonrepeatable Read:** If you read a row at time T1 and then re-read it at time T2, the row may have been modified (updated or deleted) or disappeared, leading to different results.
- **Phantom Read:** If you execute a query at time T1 and then execute the same query at time T2, new rows may have been added to the database that affect your results. The difference from nonrepeatable reads is that in phantom reads, the already read data has not changed, but T2 has more data satisfying your query criteria than T1.

SQL isolation levels are defined by whether they allow the above phenomena.

| Isolation Level | Dirty Read | Nonrepeatable Read | Phantom Read |
|---|---|---|---|
| READ UNCOMMITTED | YES | YES | YES |
| READ COMMITTED | NO | YES | YES |
| REPEATABLE READ | NO | NO | YES |
| SERIALIZABLE | NO | NO | NO |

Oracle **explicitly supports** the **READ COMMITTED** and **SERIALIZABLE** isolation levels.

Oracle **does not** use dirty reads—it completely **prevents** them.

## Read Consistency

Oracle utilizes **undo records** to enable **non-blocking queries** while maintaining read consistency. When executing a query, Oracle retrieves data blocks from the buffer cache and ensures that the block versions are sufficiently **"old"** to maintain the correct visibility for the query.

## Write Consistency

Old versions of a block **cannot be modified**. Any row update must alter the **current version** of the block.

Oracle performs **two types of reads** during modification:
1. **Consistent Read:** Identifies rows to modify.
2. **Current Read:** Acquires the latest data block for actual modification.

If an `UPDATE` statement targets rows with `Y=5`, but during execution, one of those rows has changed to `Y=10`, Oracle will **internally roll back** the update and retry it.

- Under **READ COMMITTED**, Oracle silently retries the transaction without user intervention.
- Under **SERIALIZABLE**, Oracle raises an **ORA-08177: can't serialize access for this transaction** error instead of retrying.

In **READ COMMITTED** mode, if an update conflict occurs, Oracle **resets the transaction's starting point**, acquiring row locks through `SELECT FOR UPDATE`, and only **after all locks are acquired**, executes the update.

---

# Redo and Undo

Redo (redo information) is information recorded in Oracle online (or archived) redo log files, which can be used to "replay" (or redo) transactions when a database fails. Undo (rollback information) is information recorded by Oracle in undo segments, primarily used to cancel or roll back transactions.

## What is Redo

Redo log files are crucial to Oracle databases; they are the transaction logs of the database. Oracle maintains two types of redo log files: online redo log files and archived redo log files. Both types of redo log files are used for recovery, and their main purpose is to be used when a database instance or media failure occurs.

Archived redo log files are essentially copies of "old" online redo log files that have been filled. When the database fills an online redo log file, the ARCn process creates a copy of it in another location. Of course, it can also keep multiple copies locally or on a remote server.

Every Oracle database has at least two online redo log groups, and each group has at least one member (redo log file). These online redo log groups are used in a circular fashion. Oracle first writes to the log files in group 1, and when it reaches the end of the files in group 1, it switches to log file group 2 and starts writing to the files in this group. When log file group 2 is full, Oracle will switch back to log file group 1 again.

Redo logs are probably the most important recovery structure in the database, but without other components (such as undo segments, distributed transaction recovery, etc.), redo logs alone cannot do anything.

## What is Undo

Conceptually, undo is the opposite of redo. When data is modified, the database generates undo information, so that if necessary, these changes can be canceled or rolled back in the future.

Undo information is not a copy of the block before modification, but rather a set of operations that can revert the block to its previous state.

It is highly likely that blocks modified by one transaction are also being modified by other transactions at the same time. Therefore, you cannot simply revert a block to its state before the transaction began, as this would undo the work of other transactions!

## How Redo and Undo Work Together

Although undo information is stored in undo tablespaces and undo segments, it is also protected by redo. In other words, the database treats undo as it treats table data or index data; modifications to undo generate redo, which is written to the log buffer and then to the log files. Similar to non-undo data in the database, undo data is written to undo segments and also placed in the buffer cache.

### INSERT-UPDATE-DELETE-COMMIT Example Scenario

#### 1. INSERT

After an INSERT occurs, the block buffer cache contains modified undo blocks, index blocks, and table data blocks, all of which are "protected" by corresponding entries in the redo log buffer.

Before flushing the modified data blocks to disk, the redo information in the redo log buffer is written to disk. This way, if a crash occurs, all modifications can be replayed using this redo information to restore the SGA to its current state, and then the database also has corresponding undo information to roll back uncommitted transactions.

#### 2. UPDATE

UPDATE operations are largely similar to INSERTs, but UPDATEs generate more UNDO; this is because UPDATEs need to save an image of the data before modification.

---

# Indexes

## Overview

Oracle provides several different types of indexes:
- B\*Tree index: This is the most commonly used index in Oracle and most other databases. A B\*Tree is structured like a binary tree, allowing for fast access to a single row of data by its key value, or locating multiple rows within a range of key values; accessing data through this index usually only requires a few I/Os. It's important to note that the B in B\*Tree does not stand for binary, but for balanced. A B\*Tree index is not a binary tree. In addition to regular B\*Tree indexes, the following types are also considered B\*Tree indexes.
    - Index-organized table (IOT): This is a table, but its storage is also a B\*Tree structure. Data in an IOT is stored and sorted by the primary key.
    - B\*Tree cluster index: This is an approximate variant of a traditional B\*Tree index. A B\*Tree cluster index is an index built on a cluster key. In a traditional B\*Tree index, the key points to the row level; however, in a B\*Tree cluster, a cluster key points to a block that contains data related to that cluster key.
    - Descending index: In a descending index, data is arranged in "largest to smallest" order (descending), rather than "smallest to largest" (ascending).
    - Reverse key index: This is also a B\*Tree index, but the bytes within the key are "reversed." If increasing data is continuously inserted into an index, reverse key indexes will result in a more even distribution of this data. Oracle processes an index scan by reversing the bytes of the data before storing it in the index, which causes data that might have been adjacent in the original index to be placed in non-adjacent locations.

The optimizer knows what the index's column list is, and the optimizer decides whether to use your index based on the information you provide.

## B\*Tree Index

B\*Tree indexes are the most common type of index structure in databases, and their implementation is very similar to a binary search tree. Their goal is to minimize the time Oracle spends searching for data.

The blocks at the lowest level of the tree are called leaf nodes or leaf blocks, which contain individual index keys and a rowid (pointing to the indexed row). Internal blocks above the leaf nodes are called branch blocks, and data searches pass through these blocks to ultimately reach the leaf nodes.

The structure of the index leaf node level is actually a doubly linked list. If we need to search for data within a certain range (also called an index range scan), once the starting leaf node (the first value in the range) is found, the subsequent work becomes much easier. At this point, there is no need to scan the index structure from the beginning; one only needs to scan forward or backward through the leaf nodes.

One characteristic of B\*Trees is that all leaf blocks should be on the same level of the tree. This level is also called the height of the index, and all traversals from the root block of the index to a leaf block will visit the same number of blocks. The index is height-balanced. Most B\*Tree indexes have a height of 2 or 3, even with millions of records. This means that finding the first leaf block through the index only takes 2 or 3 I/Os.

---

I hope this merged document is helpful! Let me know if you need any further assistance.
