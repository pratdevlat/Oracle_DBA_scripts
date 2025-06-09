
# Memory Structure

Oracle has three main memory structures:
- **System Global Area (SGA)**: This is a large shared memory segment that almost all Oracle processes need to access.
- **Process Global Area (PGA)**: This is a private memory area for a process or thread, which other processes/threads cannot access.
- **User Global Area (UGA)**: This memory area is associated with a specific session. It may be allocated in either the SGA or the PGA, depending on whether the database connection is using a shared server or a dedicated server. If a shared server is used, UGA is allocated in SGA; if a dedicated server is used, UGA is allocated in PGA.

## Process Global Area and User Global Area

PGA (Process Global Area) is a memory segment specific to a process. In other words, it is a private memory allocated to an operating system process or thread, preventing other processes or threads from accessing it. PGA is usually allocated using `malloc()` or `memmap()` and can dynamically expand or shrink during execution. PGA is never allocated in Oracle’s SGA; it is always allocated by the process or thread itself.

UGA (User Global Area) essentially represents the state of your session. It is a memory segment that remains accessible for your session throughout. The allocation of UGA depends entirely on how you connect to Oracle.

Since Oracle 9iR1, there have been two ways to manage non-UGA memory in PGA:
- **Manual PGA Memory Management**: You specify how much memory a process can use for sorting and hashing operations.
- **Automatic PGA Memory Management**: You define how much memory PGA can use across the entire system.

From Oracle 11gR1 onwards, automatic PGA memory management can be implemented using:
- Setting the `PGA_AGGREGATE_TARGET` initialization parameter to define the total amount of PGA memory available to the system.
- Setting the `MEMORY_TARGET` initialization parameter, which specifies the total memory available for both SGA and PGA. The database automatically adjusts the appropriate PGA size based on this setting.

Common questions include: “How is memory allocated?” and “How much memory is my session using?” These are difficult to answer. Some information from MetaLink (documents 147806.1 and 223730.1) helps in analysis:
- `PGA_AGGREGATE_TARGET` is a maximum target, not a preallocated size at database startup.
- The amount of PGA memory available to a specific session depends on `PGA_AGGREGATE_TARGET`. The algorithms determining the maximum memory available to a process vary by database version. Typically, the amount of PGA memory allocated per process is determined based on total available memory and the number of competing processes.
- As workload increases, the memory allocated to individual work areas decreases. The database tries to ensure total PGA memory usage does not exceed the `PGA_AGGREGATE_TARGET`, but if necessary, it will exceed the limit to maintain database operations.

## System Global Area

Every Oracle database instance has a large memory structure called the **System Global Area (SGA)**. This is a large shared memory segment accessed by all Oracle processes.

SGA consists of several pools, including:
- **Java Pool**: A fixed-size memory allocated for the Java Virtual Machine running within the database. It can be dynamically resized.
- **Large Pool**: Used for session memory (UGA) in shared server connections, message buffers in parallel execution, and disk I/O buffers during RMAN backups. It can be dynamically resized.
- **Shared Pool**: Contains shared cursors, stored procedures, state objects, dictionary cache, and other shared data. It can be dynamically resized.
- **Streams Pool**: A memory pool dedicated to data transfer and sharing mechanisms. It can be dynamically resized.
- **"Null" Pool**: This unnamed pool includes block buffers (for caching database blocks), redo log buffers, and the fixed SGA area.

This translation should make it easier for you to work with. Let me know if you need any further clarifications!
