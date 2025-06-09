

### Background Processes in oracle

To maximize performance and accommodate many users, a multiprocess Oracle database system uses background processes. Background processes are the processes running behind the scene and are meant to perform certain maintenance activities or to deal with abnormal conditions arising in the instance. Each background process is meant for a specific purpose and its role is well defined.

  

Background processes consolidate functions that would otherwise be handled by multiple database programs running for each user process. Background processes asynchronously perform I/O and monitor other Oracle database processes to provide increased parallelism for better performance and reliability.

  
  
  

A background process is defined as any process that is listed in V$PROCESS and has a non-null value in the pname column.

  

Not all background processes are mandatory for an instance. Some are mandatory and some are optional. Mandatory background processes are DBWn, LGWR, CKPT, SMON, PMON, and RECO. All other processes are optional, will be invoked if that particular feature is activated.

  

Oracle background processes are visible as separate operating system processes in Unix/Linux. In Windows, these run as separate threads within the same service. Any issues related to background processes should be monitored and analyzed from the trace files generated and the alert log.

  

Background processes are started automatically when the instance is started.

  

To find out background processes from database:

SQL> select SID,PROGRAM from v$session where TYPE='BACKGROUND';

  

To find out background processes from OS:

$ ps -ef|grep ora\_|grep SID  
  

  

**Mandatory Background Processes in Oracle**

  

If any one of these 6 mandatory background processes is killed/not running, the instance will be aborted.

  

1) **Database Writer (maximum 20) DBW0-DBW9,DBWa-DBWj**

  

  

Whenever a log switch is occurring as redolog file is becoming CURRENT to ACTIVE stage, oracle calls DBWn and synchronizes all the dirty blocks in database buffer cache to the respective datafiles, scattered or randomly.

  
Database writer (or Dirty Buffer Writer) process does multi-block writing to disk asynchronously. One DBWn process is adequate for most systems. Multiple database writers can be configured by initialization parameter DB\_WRITER\_PROCESSES, depends on the number of CPUs allocated to the instance. To have more than one DBWn only make sense if each DBWn has been allocated its own list of blocks to write to disk. This is done through the initialization parameter DB\_BLOCK\_LRU\_LATCHES. If this parameter is not set correctly, multiple DB writers can end up contending for the same block list.  
  
  

The possible multiple DBWR processes in RAC must be coordinated through the locking and global cache processes to ensure efficient processing is accomplished.

  

DBWn will be invoked in the following scenarios:

*   When the dirty blocks in SGA reach a threshold value, oracle calls DBWn.
*   When the database is shutting down (normal, transactional, immediate) with some dirty blocks in the SGA, then oracle calls DBWn.
*   DBWn has a time-out value (3 seconds by default) and it wakes up whether there are any dirty blocks or not.
*   When a checkpoint is issued.
*   When a server process cannot find a clean reusable buffer after scanning a threshold number of buffers.
*   When a huge table wants to enter into SGA and oracle could not find enough free space where it decides to flush out LRU blocks and which happens to be dirty blocks. Before flushing out the dirty blocks, oracle calls DBWn.
*   [Oracle RAC](https://satya-racdba.blogspot.com/) ping request is made.
*   When Table DROPped or TRUNCATEed.  
    
*   When tablespace is going to OFFLINE/READ ONLY/BEGIN BACKUP.

  
2) **Log Writer (maximum 1) LGWR**

  

LGWR writes redo data from redolog buffers to (online) redolog files, sequentially.

  
Redolog file contains changes to any datafile. The content of the redolog file is file id, block id and new content.

  

LGWR will be invoked more often than DBWn as log files are really small when compared to datafiles (KB vs GB). For every small update we don’t want to open huge gigabytes of datafiles, instead write to the log file.

  
Redolog file has three stages CURRENT, ACTIVE, INACTIVE and this is a cyclic process. The newly created redolog file will be in UNUSED state.

  
When the LGWR is writing to a particular redolog file, that file is said to be in CURRENT status. If the file is filled up completely then a log switch takes place and the LGWR starts writing to the second file (this is the reason every database requires a minimum of 2 redolog groups). The file which is filled up now becomes from CURRENT to ACTIVE.

  

Log writer will write synchronously to the redolog groups in a circular fashion. If any damage is identified with a redolog file, the log writer will log an error in the LGWR trace file and the alert log. Sometimes, when additional redolog buffer space is required, the LGWR will even write uncommitted redolog entries to release the held buffers. LGWR can also use group commits (multiple committed transaction's redo entries taken together) to write to redologs when a database is undergoing heavy write operations.  
  
  

In RAC, each RAC instance has its own LGWR process that maintains that instance’s thread of redo logs.

  

LGWR will be invoked in the following scenarios:

*   LGWR is invoked whenever 1/3rd of the redo buffer is filled up.
*   Whenever the log writer times out (3sec).
*   Whenever 1MB of redolog buffer is filled (This means that there is no sense in making the redolog buffer more than 3MB).
*   Shutting down the database.
*   Whenever checkpoint event occurs.
*   When a transaction is completed (either committed or rollbacked) then oracle calls the LGWR and synchronizes the log buffers to the redolog files and then only passes on the acknowledgment back to the user. This means the transaction is not guaranteed although we said commit, unless we receive the acknowledgment. When a transaction is committed, a System Change Number (SCN) is generated and tagged to it. Log writer puts a commit record in the redolog buffer and writes it to disk immediately along with the transaction's redo entries. Changes to actual data blocks are deferred until a convenient time (Fast-Commit mechanism).
*   When DBWn signals the writing of redo records to disk. All redo records associated with changes in the block buffers must be written to disk first (The write-ahead protocol). While writing dirty buffers, if the DBWn process finds that some redo information has not been written, it signals the LGWR to write the information and waits until the control is returned.

  
3) **Checkpoint** (maximum 1) CKPT

  
  

Checkpoint is a background process that triggers the checkpoint event, to synchronize all database files with the checkpoint information. It ensures data consistency and faster database recovery in case of a crash.

  
When checkpoint occurred it will invoke the DBWn and updates the SCN block of all datafiles and the control file with the current SCN. This is done by LGWR. This SCN is called checkpoint SCN.

*   Checkpoint event can occur in the following conditions:
    *   Whenever database buffer cache filled up.
    *   Whenever times out (3seconds until 9i, 1second from 10g).
    *   Log switch occurred.
    *   Whenever manual log switch is done.  
        SQL> ALTER SYSTEM SWITCH LOGFILE;
    *   Manual checkpoint.  
        SQL> ALTER SYSTEM CHECKPOINT;
    *   Graceful shutdown of the database.
    *   Whenever BEGIN BACKUP command is issued.  
        
    *   When the time specified by the initialization parameter LOG\_CHECKPOINT\_TIMEOUT (in seconds), exists between the incremental checkpoint and the tail of the log.
    *   When the number of OS blocks specified by the initialization parameter LOG\_CHECKPOINT\_INTERVAL, exists between the incremental checkpoint and the tail of the log.
    *   The number of buffers specified by the initialization parameter FAST\_START\_IO\_TARGET required to perform roll-forward is reached.
    *   [Oracle 9i](https://satya-dba.blogspot.com/2009/01/whats-new-in-9i.html) onwards, the time specified by the initialization parameter FAST\_START\_MTTR\_TARGET (in seconds) is reached and specifies the time required for crash recovery. The parameter FAST\_START\_MTTR\_TARGET replaces LOG\_CHECKPOINT\_INTERVAL and FAST\_START\_IO\_TARGET, but these parameters can still be used.

**4) **System Monitor (maximum 1) SMON****

*   **If the database is crashed (power failure) and next time when we restart the database SMON observes that last time the database was not shutdown gracefully. Hence it requires some recovery, which is known as INSTANCE CRASH RECOVERY. When performing the crash recovery before the database is completely open, if it finds any transaction committed but not found in the datafiles, will now be applied from redolog files to datafiles.**
***   If SMON observes some uncommitted transaction that has already updated the table in the datafile, is going to be treated as a in doubt transaction and will be rolled back with the help of before image available in [rollback segments.](https://satya-dba.blogspot.com/2009/08/rollback-segments-in-oracle.html)
*   SMON also cleans up [temporary segments](https://satya-dba.blogspot.com/2009/07/temporary-tablespace-in-oracle.html) that are no longer in use.
*   It also coalesces contiguous free extents in dictionary managed tablespaces that have PCTINCREASE set to a non-zero value.
*   In [RAC environment](https://satya-racdba.blogspot.com/), the SMON process of one instance can perform instance recovery for other instances that have failed.
*   SMON wakes up about every 5 minutes to perform housekeeping activities.**

**5) **Process Monitor (maximum 1) PMON****

**If a client has an open transaction which is no longer active (client session is closed) then PMON comes into the picture and that transaction becomes in doubt transaction which will be rolled back.**

****PMON** is responsible for performing recovery if a user process fails. It will rollback uncommitted transactions. If the old session locked any resources that will be unlocked by PMON.  
  
PMON is responsible for cleaning up the database buffer cache and freeing resources that were allocated to a process.  
  
PMON also registers information about the instance and dispatcher processes with Oracle (network) listener. PMON also checks the dispatcher & server processes and restarts them if they have failed. Since [Oracle 12c](https://satya-dba.blogspot.com/2012/10/new-features-in-oracle-database-12c.html), LREG (Listener REGistration) process is taking care of listener operations.**

**PMON wakes up every 3 seconds to perform housekeeping activities.**

[In RAC](https://satya-racdba.blogspot.com/2012/03/background-processes-in-rac.html), PMON’s role as service registration agent is particularly important.

****6) Recoverer (maximum 1) RECO \[Mandatory from Oracle 10g\]****

**This process is intended for recovery in distributed databases. The distributed transaction recovery process finds pending distributed transactions and resolves them. All in-doubt transactions are recovered by this process in the distributed database setup. RECO will connect to the remote database to resolve pending transactions.**

**Pending distributed transactions are two-phase commit transactions involving multiple databases. The database that the transaction started is normally the coordinator. It will send requests to other databases involved in two-phase commit if they are ready to commit. If a negative request is received from one of the other sites, the entire transaction will be rolled back. Otherwise, the distributed transaction will be committed on all sites. However, there is a chance that an error (network related or otherwise) causes the two-phase commit transaction to be left in pending state (i.e. not committed or rolled back). It's the role of the RECO process to liaise with the coordinator to resolve the pending two-phase commit transaction. RECO will either commit or rollback this transaction.**  

**Optional Background Processes in Oracle**

**Archiver (maximum 10) ARC0-ARC9**

The ARCn process is responsible for writing the online redolog files to the mentioned archive log destination after a log switch has occurred. ARCn is present only if the database is running in archivelog mode and automatic archiving is enabled. The log writer process is responsible for starting multiple ARCn processes when the workload increases. Unless ARCn completes the copying of a redolog file, it is not released to log writer for overwriting.

  

The number of archiver processes that can be invoked initially is specified by the initialization parameter LOG\_ARCHIVE\_MAX\_PROCESSES (by default 2, max 10). The actual number of archiver processes in use may vary based on the workload.

  

ARCH processes, running on primary database, select archived redo logs and send them to standby database. Archive log files are used for media recovery (in case of a hard disk failure and for maintaining an Oracle standby database via log shipping). Archives the standby redo logs applied by the managed recovery process (MRP).  
  
  
In RAC, the various ARCH processes can be utilized to ensure that copies of the archived redo logs for each instance are available to the other instances in the RAC setup should they be needed for recovery.

  

**Coordinated Job Queue Processes (maximum 1000) CJQ0/Jnnn**

Job queue processes carry out batch processing. All scheduled jobs are executed by these processes. The initialization parameter JOB\_QUEUE\_PROCESSES specifies the maximum job processes that can be run concurrently. These processes will be useful in refreshing [materialized views](https://satya-dba.blogspot.com/2009/07/materialized-views-oracle.html).

  

This is the Oracle’s dynamic job queue coordinator. It periodically selects jobs (from JOB$) that need to be run, scheduled by the Oracle job queue. The coordinator process dynamically spawns job queue slave processes (J000-J999) to run the jobs. These jobs could be PL/SQL statements or procedures on an Oracle instance.  
**CQJ0** \- Job queue controller process wakes up periodically and checks the job log. If a job is due, it spawns Jnnnn processes to handle jobs.

  

From [Oracle 11g release2](https://satya-dba.blogspot.com/2009/09/whats-new-in-11g-release-2.html), DBMS\_JOB and DBMS\_SCHEDULER work without setting JOB\_QUEUE\_PROCESSES. Prior to 11gR2 the default value is 0, and from 11gR2 the default value is 1000.

  

**Dedicated Server**  
Dedicated server processes are used when MTS is not used. Each user process gets a dedicated connection to the database. These user processes also handle disk reads from database datafiles into the database block buffers.

**LISTENER**  
The LISTENER process listens for connection requests on a specified port and passes these requests to either a distributor process if MTS is configured, or to a dedicated process if MTS is not used. The LISTENER process is responsible for load balance and failover in case a RAC instance fails or is overloaded.

**CALLOUT Listener**  
Used by internal processes to make calls to externally stored procedures.

  

**Lock Monitor** (maximum 1) LMON

Lock monitor manages global locks and resources. It handles the redistribution of instance locks whenever instances are started or shutdown. Lock monitor also recovers instance lock information prior to the instance recovery process. Lock monitor coordinates with the Process Monitor (PMON) to recover dead processes that hold instance locks.

  

**Lock Manager Daemon (maximum 10) LMDn**

LMDn processes manage instance locks that are used to share resources between instances. LMDn processes also handle deadlock detection and remote lock requests.

  
  

**Global Cache Service** (LMS)

In an [Oracle Real Application Clusters](https://satya-racdba.blogspot.com/) environment, this process manages resources and provides inter-instance resource control.

**Lock processes (maximum 10) LCK0- LCK9**

The instance locks that are used to share resources between instances are held by the lock processes.

  

**Block Server Process (maximum 10) BSP0-BSP9**

Block server Processes have to do with providing a consistent read image of a buffer that is requested by a process of another instance, in certain circumstances.

  

**Queue Monitor (maximum 10) QMN0-QMN9**

This is the advanced queuing time manager process. QMNn monitors the message queues. QMN used to manage Oracle Streams Advanced Queuing.

  

**Event Monitor (maximum 1) EMN0/EMON**

This process is also related to advanced queuing, and is meant for allowing a publish/subscribe style of messaging between applications.

  

**Dispatcher (maximum 1000) Dnnn**

Intended for multi threaded server (MTS) setups. Dispatcher processes listen to and receive requests from connected sessions and place them in the request queue for further processing. Dispatcher processes also pick up outgoing responses from the result queue and transmit them back to the clients. Dnnn are mediators between the client processes and the shared server processes. The maximum number of dispatcher process can be specified using the initialization parameter MAX\_DISPATCHERS.

  

**Shared Server Processes (maximum 1000) Snnn**

Intended for multi-threaded server (MTS) setups. These processes pick up requests from the call request queue, process them and then return the results to a result queue. These user processes also handle disk reads from database datafiles into the database block buffers. The number of shared server processes to be created at instance startup can be specified using the initialization parameter SHARED\_SERVERS. Maximum shared server processes can be specified by MAX\_SHARED\_SERVERS.

  

**Parallel Execution/Query Slaves (maximum 1000) Pnnn**

These processes are used for parallel processing. It can be used for parallel execution of SQL statements or recovery. The maximum number of parallel processes that can be invoked is specified by the initialization parameter PARALLEL\_MAX\_SERVERS.

  

**Trace Writer (maximum 1) TRWR**

Trace writer writes trace files from an Oracle internal tracing facility.

  

**Input/Output Slaves (maximum 1000) Innn**

These processes are used to simulate asynchronous I/O on platforms that do not support it. The initialization parameter DBWR\_IO\_SLAVES is set for this purpose.

  

Data Guard Monitor (maximum 1) DMON

The Data Guard broker process. DMON is started when Data Guard is started. This is broker controller process is the main broker process and is responsible for coordinating all broker actions as well as maintaining the broker configuration files. This process is enabled/disabled with the DG\_BROKER\_START parameter.  

  

**Data Guard Broker Resource Manager** RSM0  
The RSM process is responsible for handling any SQL commands used by the broker that needs to be executed on one of the databases in the configuration.

  

**Data Guard NetServer/NetSlave** NSVn  
These are responsible for making contact with the remote database and sending across any work items to the remote database. From 1 to n of these network server processes can exist. NSVn is created when a Data Guard broker configuration is enabled. There can be as many NSVn processes (where n is 0- 9 and A-U) created as there are databases in the Data Guard broker configuration.

  

**DRCn**  
These network receiver processes establish the connection from the source database NSVn process. When the broker needs to send something (e.g. data or SQL) between databases, it uses this NSV to DRC connection. These connections are started as needed.

  

**Data Guard Broker Instance Slave Process** INSV  
Performs Data Guard broker communication among instances in an Oracle RAC environment

  

**Data Guard Broker Fast Start Failover Pinger Process** FSFP  
Maintains fast-start failover state between the primary and target standby databases. FSFP is created when fast-start failover is enabled.  
  

  

**LGWR Network Server process** LNS

  
In Data Guard, LNS process performs actual network I/O and waits for each network I/O to complete. Each LNS has a user configurable buffer that is used to accept outbound redo data from the LGWR process. The NET\_TIMEOUT attribute is used only when the LGWR process transmits redo data using a LGWR Network Server(LNS) process.

  

**Managed Recovery Process** MRP

In Data Guard environment, this managed recovery process will apply archived redo logs to the standby database.

  

**Remote File Server process** RFS

The remote file server process, in Data Guard environment, on the standby database receives archived redo logs from the primary database.

  

**Logical Standby Process** LSP

The logical standby process is the coordinator process for a set of processes that concurrently read, prepare, build, analyze, and apply completed SQL transactions from the archived redo logs. The LSP also maintains metadata in the database. The RFS process communicates with the logical standby process (LSP) to coordinate and record which files arrived.

  

**Wakeup Monitor Process (maximum 1) WMON**

This process was available in older versions of Oracle to alarm other processes that are suspended while waiting for an event to occur. This process is obsolete and has been removed.

  

  
Recovery Writer (maximum 1) RVWR  
This is responsible for writing [flashback](https://satya-dba.blogspot.com/2009/02/flashback.html) logs (to [FRA](https://satya-dba.blogspot.com/2009/02/flash-recovery-area.html)).  
  
Fetch Archive Log (FAL) Server  
Services requests for archive redo logs from FAL clients running on multiple standby databases. Multiple FAL servers can be run on a primary database, one for each FAL request.  
  
Fetch Archive Log (FAL) Client  
Pulls archived redo log files from the primary site. Initiates the transfer of archived redo logs when it detects a gap sequence.

  

**[Data Pump](https://satya-dba.blogspot.com/2009/06/datapump-in-oracle.html) Master Process** DMnn  
Creates and deletes the master table at the time of export and import. Master table contains the job state and object information. Coordinates the Data Pump job tasks performed by Data Pump worker processes and handles client interactions. The Data Pump master (control) process is started during job creation and coordinates all tasks performed by the Data Pump job. It handles all client interactions and communication, establishes all job contexts, and coordinates all worker process activities on behalf of the job. Creates the Worker Process.

  

**Data Pump** **Worker Process** DWnn  
It performs the actual heavy-duty work of loading and unloading of data. It maintains the information in master table. The Data Pump worker process is responsible for performing tasks that are assigned by the Data Pump master process, such as the loading and unloading of metadata and data.

  

**Shadow Process**  
When client logs in to an Oracle Server the database creates and Oracle process to service Data Pump API.

  

**Client Process**  
The client process calls the [Data pump](https://satya-dba.blogspot.com/2009/06/datapump-in-oracle.html) API.

  

New Background Processes in [Oracle 10g](https://satya-dba.blogspot.com/2009/01/whats-new-in-10g.html)

  

**Memory Manager** (maximum 1) MMAN

MMAN dynamically adjusts the sizes of the SGA components like buffer cache, large pool, shared pool and java pool and serves as SGA memory broker. It is a new process added to Oracle 10g as part of automatic shared memory management.

  

**Memory Monitor** (maximum 1) MMON

MMON monitors SGA and performs various manageability related background tasks. MMON, the Oracle 10g background process, used to collect statistics for the Automatic Workload Repository (AWR).Tracks/aggregates space utilization while performing regular space management activities.

  

**Memory Monitor Light** (maximum 1) MMNL

New background process in Oracle 10g. This process performs frequent and lightweight manageability-related tasks, such as session history capture and metrics computation. This process will flush the ASH buffer to AWR tables when the buffer is full or a snapshot is taken.

  

Change Tracking Writer (maximum 1) CTWR

CTWR will be useful in RMAN. Optimized incremental backups using [block change tracking](https://satya-dba.blogspot.com/2012/06/block-change-tracking-file-oracle.html) (faster incremental backups) using a file (named block change tracking file). CTWR (Change Tracking Writer) is the background process responsible for tracking the blocks.

  

  

**ASMB**

This ASMB process is used to provide information to and from cluster synchronization services used by [ASM](https://satya-dba.blogspot.com/2010/03/automatic-storage-management-asm-10g.html) to manage the disk resources. It's also used to update [statistics](https://satya-dba.blogspot.com/2010/06/oracle-database-statistics-rbo-cbo.html) and provide a heartbeat mechanism.

  

**Re-Balance** RBAL

RBAL is the ASM related process that performs rebalancing of disk resources controlled by [ASM](https://satya-dba.blogspot.com/2010/03/automatic-storage-management-asm-10g.html).

  

**Actual Rebalance** ARBx

ARBx is configured by ASM\_POWER\_LIMIT.

  

**New Background Processes in [Oracle 11g](https://satya-dba.blogspot.com/2009/01/whats-new-in-11g.html)**

*   ACMS - Atomic Controlfile to Memory Server
*   DBRM - Database Resource Manager
*   DIA0 - Diagnosibility process 0
*   DIAG - Diagnosibility process
*   FBDA - [Flashback](https://satya-dba.blogspot.com/2009/02/flashback.html) Data Archiver, 
    
    Background process **fbda** captures data asynchronously,
    
    Every 5 minutes (default), more frequent intervals based on activity.
    
*   GTX0 - Global Transaction Process 0
*   KATE - Konductor (Conductor) of ASM Temporary Errands
*   MARK - Mark Allocation unit for Resync Koordinator (coordinator)
*   SMCO - Space Manager
*   VKTM - Virtual Keeper of TiMe process
*   W000 - Space Management Worker Processes
*   ABP - Autotask Background Process

  
Autotask Background Process (ABP)

It translates tasks into jobs for execution by the scheduler. It determines the list of jobs that must be created for each maintenance window. Stores task execution history in the SYSAUX tablespace. It is spawned by the MMON background process at the start of the maintenance window.

  

**File Monitor (FMON)**

The database communicates with the mapping libraries provided by storage vendors through an external non-Oracle Database process that is spawned by a background process called FMON. FMON is responsible for managing the mapping information. When you specify the FILE\_MAPPING initialization parameter for mapping datafiles to physical devices on a storage subsystem, then the FMON process is spawned.

  
  

**Dynamic Intimate Shared Memory (DISM)**

By default, Oracle uses intimate shared memory (ISM) instead of standard System V shared memory on Solaris Operating system. When a shared memory segment is made into an ISM segment, it is mapped using large pages and the memory for the segment is locked (i.e., it cannot be paged out). This greatly reduces the overhead due to process context switches, which improves Oracle's performance linearity under load.  
  
**New background processes in [Oracle Database 12c](https://satya-dba.blogspot.com/2012/10/new-features-in-oracle-database-12c.html)**  
  
LREG (Listener Registration)  
SA (SGA Allocator)  
RM  

  
