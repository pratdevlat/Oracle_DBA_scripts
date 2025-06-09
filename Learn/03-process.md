Here’s the English translation of the document:

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

Let me know if you need clarifications or further details!
