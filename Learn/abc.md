

[Satya's DBA Blog](https://satya-dba.blogspot.com/)
===================================================

February 26, 2020
-----------------

 

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

  

Other Oracle Articles:  [Setting SQL prompt](https://satya-dba.blogspot.com/2010/08/setting-sql-prompt-in-oracle.html)    [ORADEBUG tool](https://satya-dba.blogspot.com/2018/08/oradebug-utility-tool-commands.html)  
  

[![](https://resources.blogblog.com/img/icon18_email.gif)](https://www.blogger.com/email-post/2511956539743992936/6323685730910210915 "Email Post")

[Email This](https://www.blogger.com/share-post.g?blogID=2511956539743992936&postID=6323685730910210915&target=email "Email This")[BlogThis!](https://www.blogger.com/share-post.g?blogID=2511956539743992936&postID=6323685730910210915&target=blog "BlogThis!")[Share to X](https://www.blogger.com/share-post.g?blogID=2511956539743992936&postID=6323685730910210915&target=twitter "Share to X")[Share to Facebook](https://www.blogger.com/share-post.g?blogID=2511956539743992936&postID=6323685730910210915&target=facebook "Share to Facebook")[Share to Pinterest](https://www.blogger.com/share-post.g?blogID=2511956539743992936&postID=6323685730910210915&target=pinterest "Share to Pinterest")

Labels: [Background Processes](https://satya-dba.blogspot.com/search/label/Background%20Processes)

#### 12 comments:

(function() { var items = null; var msgs = null; var config = {}; // <!\[CDATA\[ var cursor = null; if (items && items.length > 0) { cursor = parseInt(items\[items.length - 1\].timestamp) + 1; } var bodyFromEntry = function(entry) { var text = (entry && ((entry.content && entry.content.$t) || (entry.summary && entry.summary.$t))) || ''; if (entry && entry.gd$extendedProperty) { for (var k in entry.gd$extendedProperty) { if (entry.gd$extendedProperty\[k\].name == 'blogger.contentRemoved') { return '<span class="deleted-comment">' + text + '</span>'; } } } return text; } var parse = function(data) { cursor = null; var comments = \[\]; if (data && data.feed && data.feed.entry) { for (var i = 0, entry; entry = data.feed.entry\[i\]; i++) { var comment = {}; // comment ID, parsed out of the original id format var id = /blog-(\\d+).post-(\\d+)/.exec(entry.id.$t); comment.id = id ? id\[2\] : null; comment.body = bodyFromEntry(entry); comment.timestamp = Date.parse(entry.published.$t) + ''; if (entry.author && entry.author.constructor === Array) { var auth = entry.author\[0\]; if (auth) { comment.author = { name: (auth.name ? auth.name.$t : undefined), profileUrl: (auth.uri ? auth.uri.$t : undefined), avatarUrl: (auth.gd$image ? auth.gd$image.src : undefined) }; } } if (entry.link) { if (entry.link\[2\]) { comment.link = comment.permalink = entry.link\[2\].href; } if (entry.link\[3\]) { var pid = /.\*comments\\/default\\/(\\d+)\\?.\*/.exec(entry.link\[3\].href); if (pid && pid\[1\]) { comment.parentId = pid\[1\]; } } } comment.deleteclass = 'item-control blog-admin'; if (entry.gd$extendedProperty) { for (var k in entry.gd$extendedProperty) { if (entry.gd$extendedProperty\[k\].name == 'blogger.itemClass') { comment.deleteclass += ' ' + entry.gd$extendedProperty\[k\].value; } else if (entry.gd$extendedProperty\[k\].name == 'blogger.displayTime') { comment.displayTime = entry.gd$extendedProperty\[k\].value; } } } comments.push(comment); } } return comments; }; var paginator = function(callback) { if (hasMore()) { var url = config.feed + '?alt=json&v=2&orderby=published&reverse=false&max-results=50'; if (cursor) { url += '&published-min=' + new Date(cursor).toISOString(); } window.bloggercomments = function(data) { var parsed = parse(data); cursor = parsed.length < 50 ? null : parseInt(parsed\[parsed.length - 1\].timestamp) + 1 callback(parsed); window.bloggercomments = null; } url += '&callback=bloggercomments'; var script = document.createElement('script'); script.type = 'text/javascript'; script.src = url; document.getElementsByTagName('head')\[0\].appendChild(script); } }; var hasMore = function() { return !!cursor; }; var getMeta = function(key, comment) { if ('iswriter' == key) { var matches = !!comment.author && comment.author.name == config.authorName && comment.author.profileUrl == config.authorUrl; return matches ? 'true' : ''; } else if ('deletelink' == key) { return config.baseUri + '/comment/delete/' + config.blogId + '/' + comment.id; } else if ('deleteclass' == key) { return comment.deleteclass; } return ''; }; var replybox = null; var replyUrlParts = null; var replyParent = undefined; var onReply = function(commentId, domId) { if (replybox == null) { // lazily cache replybox, and adjust to suit this style: replybox = document.getElementById('comment-editor'); if (replybox != null) { replybox.height = '250px'; replybox.style.display = 'block'; replyUrlParts = replybox.src.split('#'); } } if (replybox && (commentId !== replyParent)) { replybox.src = ''; document.getElementById(domId).insertBefore(replybox, null); replybox.src = replyUrlParts\[0\] + (commentId ? '&parentID=' + commentId : '') + '#' + replyUrlParts\[1\]; replyParent = commentId; } }; var hash = (window.location.hash || '#').substring(1); var startThread, targetComment; if (/^comment-form\_/.test(hash)) { startThread = hash.substring('comment-form\_'.length); } else if (/^c\[0-9\]+$/.test(hash)) { targetComment = hash.substring(1); } // Configure commenting API: var configJso = { 'maxDepth': config.maxThreadDepth }; var provider = { 'id': config.postId, 'data': items, 'loadNext': paginator, 'hasMore': hasMore, 'getMeta': getMeta, 'onReply': onReply, 'rendered': true, 'initComment': targetComment, 'initReplyThread': startThread, 'config': configJso, 'messages': msgs }; var render = function() { if (window.goog && window.goog.comments) { var holder = document.getElementById('comment-holder'); window.goog.comments.render(holder, provider); } }; // render now, or queue to render when library loads: if (window.goog && window.goog.comments) { render(); } else { window.goog = window.goog || {}; window.goog.comments = window.goog.comments || {}; window.goog.comments.loadQueue = window.goog.comments.loadQueue || \[\]; window.goog.comments.loadQueue.push(render); } })(); // \]\]>

1.  ![](//resources.blogblog.com/img/blank.gif)
    
    Anonymous[September 1, 2009 at 3:52 PM](https://satya-dba.blogspot.com/2009/08/background-processes-in-oracle.html?showComment=1251800546010#c4301704982878908540)
    
    A small correction on the topic LGWR:  
    Newly created redo log file will be in stale state depicting that the redo log file has not been used so far.
    
    Reply[Delete](https://www.blogger.com/comment/delete/2511956539743992936/4301704982878908540)
    
    Replies
    
    Reply
    
2.  ![](//www.blogger.com/img/blogger_logo_round_35.png)
    
    [Satya Thirumani](https://www.blogger.com/profile/14440084623088726822)[May 12, 2012 at 4:24 PM](https://satya-dba.blogspot.com/2009/08/background-processes-in-oracle.html?showComment=1336820078110#c967622784422262434)
    
    Thank you very much...
    
    Reply[Delete](https://www.blogger.com/comment/delete/2511956539743992936/967622784422262434)
    
    Replies
    
    Reply
    
3.  ![](//resources.blogblog.com/img/blank.gif)
    
    Anonymous[September 14, 2012 at 11:32 PM](https://satya-dba.blogspot.com/2009/08/background-processes-in-oracle.html?showComment=1347645722913#c5544227667515527693)
    
    Does yоur site hаve а cοntact ρage?  
      
    I'm having problems locating it but, I'd lіkе to shoot you an e-mail.  
      
    Ι've got some suggestions for your blog you might be interested in hearing. Either way, great blog and I look forward to seeing it grow over time.  
    _Look into my weblog_ :: **[provide](http://www.whadafuck.com/users/MicheleJds)**
    
    Reply[Delete](https://www.blogger.com/comment/delete/2511956539743992936/5544227667515527693)
    
    Replies
    
    Reply
    
4.  ![](//resources.blogblog.com/img/blank.gif)
    
    Anonymous[January 29, 2013 at 7:19 PM](https://satya-dba.blogspot.com/2009/08/background-processes-in-oracle.html?showComment=1359467376927#c7794521188145896882)
    
    Sir can u post a detail description about the new mandatory background process in oracle 11g.  
    I gone through your post on background processes really awesome explanation.  
    One thing i should confirm from you that as far as my knowledge redo log files contains both commited and uncommited data but people around me always says that it contains only completed TX so u give neat explanation on that as,  
      
    To give space in the redo log buffer for the new TXs, log writer writes even uncommited data to redo log files.  
      
    thanks alot for giving me useful info
    
    Reply[Delete](https://www.blogger.com/comment/delete/2511956539743992936/7794521188145896882)
    
    Replies
    
    Reply
    
5.  ![](//resources.blogblog.com/img/blank.gif)
    
    Anonymous[February 4, 2013 at 1:48 PM](https://satya-dba.blogspot.com/2009/08/background-processes-in-oracle.html?showComment=1359965894390#c8766810163946289051)
    
    Each and Every article is clear ...here..  
      
    thank U..  
    
    Reply[Delete](https://www.blogger.com/comment/delete/2511956539743992936/8766810163946289051)
    
    Replies
    
    Reply
    
6.  ![](//www.blogger.com/img/blogger_logo_round_35.png)
    
    [Satya Thirumani](https://www.blogger.com/profile/14440084623088726822)[February 4, 2013 at 5:58 PM](https://satya-dba.blogspot.com/2009/08/background-processes-in-oracle.html?showComment=1359980888548#c3459605770418674404)
    
    Many Thanksssss...
    
    Reply[Delete](https://www.blogger.com/comment/delete/2511956539743992936/3459605770418674404)
    
    Replies
    
    Reply
    
7.  ![](//www.blogger.com/img/blogger_logo_round_35.png)
    
    [Unknown](https://www.blogger.com/profile/11045840891974876606)[February 6, 2018 at 6:41 AM](https://satya-dba.blogspot.com/2009/08/background-processes-in-oracle.html?showComment=1517879475553#c6966136294960899674)
    
    thanks for knowledge  
    
    Reply[Delete](https://www.blogger.com/comment/delete/2511956539743992936/6966136294960899674)
    
    Replies
    
    Reply
    
8.  ![](//www.blogger.com/img/blogger_logo_round_35.png)
    
    [Quốc Vinh](https://www.blogger.com/profile/10987760034610718876)[April 4, 2018 at 11:40 AM](https://satya-dba.blogspot.com/2009/08/background-processes-in-oracle.html?showComment=1522822237257#c7698052904916725188)
    
    Thanks and good luck to you.
    
    Reply[Delete](https://www.blogger.com/comment/delete/2511956539743992936/7698052904916725188)
    
    Replies
    
    Reply
    
9.  ![](//www.blogger.com/img/blogger_logo_round_35.png)
    
    [Unknown](https://www.blogger.com/profile/14983103606458397268)[May 24, 2018 at 4:23 PM](https://satya-dba.blogspot.com/2009/08/background-processes-in-oracle.html?showComment=1527159225915#c8457326837440124206)
    
    This comment has been removed by a blog administrator.
    
    Reply[Delete](https://www.blogger.com/comment/delete/2511956539743992936/8457326837440124206)
    
    Replies
    
    Reply
    
10.  ![](//www.blogger.com/img/blogger_logo_round_35.png)
    
    [Unknown](https://www.blogger.com/profile/05541811550169562218)[June 28, 2018 at 3:19 PM](https://satya-dba.blogspot.com/2009/08/background-processes-in-oracle.html?showComment=1530179349407#c5135586796424389235)
    
    Hai,  
    Thanks for sharing nice informative blog. Very helpful for the learners. Hope this blog https://mindmajix.com/oracle-dba/oracle-database-creation-process may also helpful for you, Please go through it.
    
    Reply[Delete](https://www.blogger.com/comment/delete/2511956539743992936/5135586796424389235)
    
    Replies
    
    Reply
    
11.  ![](//www.blogger.com/img/blogger_logo_round_35.png)
    
    [anuj kumar](https://www.blogger.com/profile/02607994727463376347)[July 31, 2018 at 7:52 PM](https://satya-dba.blogspot.com/2009/08/background-processes-in-oracle.html?showComment=1533046950546#c743844509729447550)
    
    Thanks !!
    
    Reply[Delete](https://www.blogger.com/comment/delete/2511956539743992936/743844509729447550)
    
    Replies
    
    Reply
    
12.  ![](//www.blogger.com/img/blogger_logo_round_35.png)
    
    [Santosh](https://www.blogger.com/profile/11544041608381279512)[May 1, 2023 at 11:58 PM](https://satya-dba.blogspot.com/2009/08/background-processes-in-oracle.html?showComment=1682965691846#c8594146750963258793)
    
    Thanks for sharing in such detailed information about [Background Processes in Oracle](https://orahow.com/key-background-processes-in-oracle/).
    
    Reply[Delete](https://www.blogger.com/comment/delete/2511956539743992936/8594146750963258793)
    
    Replies
    
    Reply
    

Add comment

Load more...

[](https://www.blogger.com/comment/frame/2511956539743992936?po=6323685730910210915&hl=en)BLOG\_CMT\_createIframe('https://www.blogger.com/rpc\_relay.html');

[Newer Post](https://satya-dba.blogspot.com/2020/05/ogg-checkprm-utility-commands.html "Newer Post") [Older Post](https://satya-dba.blogspot.com/2020/01/how-to-start-and-stop-postgresql-server.html "Older Post") [Home](https://satya-dba.blogspot.com/)

Subscribe to: [Post Comments (Atom)](https://satya-dba.blogspot.com/feeds/6323685730910210915/comments/default)

Oracle Articles
---------------

*   [\* Bits n Bytes](https://satya-dba.blogspot.com/2013/04/bits-and-bytes-zetta-yotta-exa-peta.html)
*   [\* Databases in the world](https://satya-dba.blogspot.com/2009/06/databases-in-world.html)
*   [ADRCI Commands in Oracle](https://satya-dba.blogspot.com/2010/10/adrci-commands-tool-utility.html)
*   [ASM](https://satya-dba.blogspot.com/2010/03/automatic-storage-management-asm-10g.html)
*   [asmcmd in Oracle 11g](https://satya-dba.blogspot.com/2010/02/asmcmd-10g-11g.html)
*   [asmcmd in oracle 12c](https://satya-dba.blogspot.com/2018/08/oracle-12c-asmcmd-commands.html)
*   [Auditing in Oracle](https://satya-dba.blogspot.com/2009/05/auditing-in-oracle.html)
*   [Background Processes in Oracle](https://satya-dba.blogspot.com/2009/08/background-processes-in-oracle.html)
*   [Block Change Tracking file](https://satya-dba.blogspot.com/2012/06/block-change-tracking-file-oracle.html)
*   [Data Dictionary Views](https://satya-dba.blogspot.com/2009/02/data-dictionary-views.html)
*   [Data Pump Export Import](https://satya-dba.blogspot.com/2009/05/datapump.html)
*   [Data Pump in Oracle](https://satya-dba.blogspot.com/2009/06/datapump-in-oracle.html)
*   [DataDictionary views Vs V$ views](https://satya-dba.blogspot.com/2009/02/views.html)
*   [dgmgrl utility](https://satya-dba.blogspot.com/2010/09/dgmgrl-utility-tool-executable.html)
*   [emca commands](https://satya-dba.blogspot.com/2012/03/emca-enterprise-manager-configuration.html)
*   [emcli commands](https://satya-dba.blogspot.com/2012/04/emcli-enterprise-manager-command-line.html)
*   [emctl commands (OEM)](https://satya-dba.blogspot.com/2010/01/emctl-commands.html)
*   [Export and Import (exp & imp)](https://satya-dba.blogspot.com/2009/05/export-import.html)
*   [Flash/Fast Recovery Area (FRA)](https://satya-dba.blogspot.com/2009/02/flash-recovery-area.html)
*   [Flashback](https://satya-dba.blogspot.com/2009/02/flashback.html)
*   [Flashback Query](https://satya-dba.blogspot.com/2009/02/flashback-query-oracle-flashback-query.html)
*   [Indexes on Oracle Partitions](https://satya-dba.blogspot.com/2013/02/local-global-indexes-on-partitions.html)
*   [Logical Standby Databases](https://satya-dba.blogspot.com/2012/06/logical-standby-databases-oracle.html)
*   [lsnrctl commands](https://satya-dba.blogspot.com/2010/01/lsnrctl-commands.html)
*   [Managing Oracle Partitions](https://satya-dba.blogspot.com/2013/02/managing-oracle-partitions-add-drop.html)
*   [Materialized View Logs](https://satya-dba.blogspot.com/2013/02/oracle-materialized-view-log.html)
*   [Materialized View Types](https://satya-dba.blogspot.com/2013/03/materialized-view-types-oracle.html)
*   [Materialized Views](https://satya-dba.blogspot.com/2009/07/materialized-views-oracle.html)
*   [Materialized Views Refresh Groups](https://satya-dba.blogspot.com/2013/03/materialized-views-refresh-groups.html)
*   [NID Utility (DBNEWID Utility)](https://satya-dba.blogspot.com/2009/01/nid-utility.html)
*   [omsca utility](https://satya-dba.blogspot.com/2013/11/omsca-oem-oms-ca.html)
*   [opatchauto Tool](https://satya-dba.blogspot.com/2013/10/opatchauto-oem-12c-oms-opatch.html)
*   [orachk utility](https://satya-dba.blogspot.com/2016/05/orachk-oracle-check-raccheck.html)
*   [Oracle 12C](https://satya-dba.blogspot.com/2011/07/oracle12c.html)
*   [Oracle Certifications (for DBAs)](https://satya-dba.blogspot.com/2008/12/oracle-certification_24.html)
*   [Oracle Solaris 11](https://satya-dba.blogspot.com/2011/12/oracle-solaris-11-cloud-os.html)
*   [oracleasm](https://satya-dba.blogspot.com/2011/11/oracleasm-oracle-asm.html)
*   [ORADEBUG tool](https://satya-dba.blogspot.com/2018/08/oradebug-utility-tool-commands.html)
*   [oraversion - Oracle Version Info](https://satya-dba.blogspot.com/2019/09/oraversion-oracle-version-tool.html)
*   [Partitioning in Oracle](https://satya-dba.blogspot.com/2009/07/partitioning-in-oracle.html)
*   [Password file (orapwd utility)](https://satya-dba.blogspot.com/2009/11/password-file-in-oracle.html)
*   [Physical Standby Databases](https://satya-dba.blogspot.com/2012/06/physical-standby-databases-oracle.html)
*   [Profiles in Oracle](https://satya-dba.blogspot.com/2009/02/profiles.html)
*   [Recycle bin in Oracle](https://satya-dba.blogspot.com/2009/02/recycle-bin.html)
*   [Remote Diagnostic Agent (RDA)](https://satya-dba.blogspot.com/2009/01/oracle-remote-diagnostic-agent-rda-rda.html)
*   [RMAN (Recovery Manager)](https://satya-dba.blogspot.com/2009/01/rman-was-first-introduced-in-oracle8.html)
*   [RMAN Commands](https://satya-dba.blogspot.com/2010/04/rman-commands.html)
*   [RMAN Incremental Backups](https://satya-dba.blogspot.com/2012/07/rman-incremental-backups-level-0-level1.html)
*   [Rollback Segments](https://satya-dba.blogspot.com/2009/08/rollback-segments-in-oracle.html)
*   [Setting SQL prompt](https://satya-dba.blogspot.com/2010/08/setting-sql-prompt-in-oracle.html)
*   [Snapshot Standby Databases](https://satya-dba.blogspot.com/2012/06/snapshot-standby-databases-oracle.html)
*   [SQL\*Loader](https://satya-dba.blogspot.com/2009/06/sqlloader.html)
*   [SQLcl commands in Oracle](https://satya-dba.blogspot.com/2019/08/sqlcl-commands-sql-cl-sqlcl.html)
*   [Startup/Shutdown Options](https://satya-dba.blogspot.com/2009/01/startupshutdown-options.html)
*   [Statistics in Oracle](https://satya-dba.blogspot.com/2010/06/oracle-database-statistics-rbo-cbo.html)
*   [Statspack in Oracle](https://satya-dba.blogspot.com/2009/08/statspack-in-oracle.html)
*   [Temporary Tablespace](https://satya-dba.blogspot.com/2009/07/temporary-tablespace-in-oracle.html)
*   [Temporary Tablespace Group](https://satya-dba.blogspot.com/2009/07/temporary-tablespace-group.html)
*   [Test Your Oracle DBA Skills](https://satya-dba.blogspot.com/2017/11/oracle-dba-online-quiz-interview.html)
*   [Transportable Tablespaces (TTS)](https://satya-dba.blogspot.com/2010/01/oracle-transportable-tablespaces-tts.html)
*   [Undo Tablespace/Management](https://satya-dba.blogspot.com/2009/09/undo-tablespace-undo-management.html)
*   [Wait events in Oracle Database](https://satya-dba.blogspot.com/2012/10/wait-events-in-oracle-wait-events.html)
*   [What's New in Oracle 10g Release 1/2](https://satya-dba.blogspot.com/2009/01/whats-new-in-10g.html)
*   [What's New in Oracle 11g Release 1](https://satya-dba.blogspot.com/2009/01/whats-new-in-11g.html)
*   [What's New in Oracle 11g Release 2](https://satya-dba.blogspot.com/2009/09/whats-new-in-11g-release-2.html)
*   [What's New in Oracle 12c Release 1](https://satya-dba.blogspot.com/2012/10/new-features-in-oracle-database-12c.html)
*   [What's New in Oracle 12c Release 2](https://satya-dba.blogspot.com/2016/10/new-features-in-oracle-12c-release-2.html)
*   [What's New in Oracle 18c](https://satya-dba.blogspot.com/2018/06/new-features-in-oracle-18c-features.html)
*   [What's New in Oracle 19c](https://satya-dba.blogspot.com/2019/07/oracle-database-19c-new-features.html)
*   [What's New in Oracle 21c](https://satya-dba.blogspot.com/2021/06/oracle-database-21c-new-features.html)
*   [What's New in Oracle 23c](https://satya-dba.blogspot.com/2022/10/oracle-database-23c-new-features.html)

MySQL Articles/Utilities Cheatsheets (for DBAs)
-----------------------------------------------

*   [Cheatsheet of MySQL utility - mysqlfrm](https://satya-dba.blogspot.com/2019/06/mysqlfrm-mysql-frm-files.html)
*   [Cheatsheet of mysqlbinlog utility](https://satya-dba.blogspot.com/2018/11/mysqlbinlog-mysql-binlog-utility.html)
*   [Cheatsheet of mysqlbinlogpurge](https://satya-dba.blogspot.com/2019/08/mysqlbin-logpurge-mysqlbinlogpurge.html)
*   [MySQL Database Administrator Online Quiz](https://satya-dba.blogspot.com/2019/07/mysql-online-interview.html)
*   [MySQL DBA Basic/Advanced Interview Questions - Part2](https://satya-dba.blogspot.com/2023/03/mysql-database-interview-questions.html)
*   [MySQL DBA Interview Questions and Answers - Part1](https://satya-dba.blogspot.com/2021/08/mysql-dba-interview-questions-answers.html)
*   [MySQL DBA top interview questions answers - Part3](https://satya-dba.blogspot.com/2023/06/mysql-dba-interview-questions-answers.html)
*   [MySQL mysqldbexport cheatsheet](https://satya-dba.blogspot.com/2019/04/mysqldb-mysqldbexport-export.html)
*   [MySQL mysqldumpslow utility commands](https://satya-dba.blogspot.com/2019/02/mysql-mysqldumpslow-dump-slow.html)
*   [MySQL mysqlreplicate cheatsheet](https://satya-dba.blogspot.com/2019/01/mysql-mysqlreplicate-replicate.html)
*   [MySQL mysqlrplsync utility](https://satya-dba.blogspot.com/2019/08/mysql-mysqlrplsync-sync.html)
*   [MySQL mysqluserclone utility cheatsheet](https://satya-dba.blogspot.com/2019/05/mysql-user-clone-mysqluserclone.html)
*   [MySQL utility - mysqlauditadmin](https://satya-dba.blogspot.com/2019/05/mysqlauditadmin-mysql-audit-admin.html)
*   [MySQL utility - mysqlauditgrep cheatsheet](https://satya-dba.blogspot.com/2019/06/mysqlauditgrep-mysql-audit-grep.html)
*   [MySQL utility - mysqlmetagrep](https://satya-dba.blogspot.com/2019/06/mysql-meta-grep-commands.html)
*   [MySQL utility mysqlbinlogrotate](https://satya-dba.blogspot.com/2019/08/mysqlbinlogrotate-mysql-binlog-rotate.html)
*   [MySQL utility mysqlprocgrep cheatsheet](https://satya-dba.blogspot.com/2019/06/mysqlprocgrep-mysql-proc-grep.html)
*   [MySQL utility mysqlslavetrx cheatsheet](https://satya-dba.blogspot.com/2019/09/mysqlslavetrx-mysql-slave-trx.html)
*   [mysql utility/commands](https://satya-dba.blogspot.com/2018/09/mysql-commands-cli-mysql.html)
*   [mysql\_config\_editor commands](https://satya-dba.blogspot.com/2018/10/mysqlconfigeditor-mysql-config-editor.html)
*   [mysql\_install\_db utility commands in MySQL](https://satya-dba.blogspot.com/2019/03/mysql-install-db-mysqlinstalldb.html)
*   [mysqladmin commands](https://satya-dba.blogspot.com/2018/09/mysql-mysqladmin-admin-commands.html)
*   [mysqlbackup commands in MySQL](https://satya-dba.blogspot.com/2022/01/mysqlbackup-mysql-backup-commands.html)
*   [mysqlbinlogmove cheatsheet](https://satya-dba.blogspot.com/2019/09/mysqlbinlogmove-mysql-binlog-move.html)
*   [mysqlcheck utility commands](https://satya-dba.blogspot.com/2018/12/mysql-mysqlcheck-check.html)
*   [mysqld\_multi utility examples](https://satya-dba.blogspot.com/2019/03/mysqld-mysqldmulti-multi.html)
*   [mysqldbcompare utility](https://satya-dba.blogspot.com/2018/11/mysql-mysqldbcompare-compare.html)
*   [mysqldbcopy commands cheatsheet](https://satya-dba.blogspot.com/2019/04/mysqldb-mysqldbcopy-copy.html)
*   [mysqldbimport utility in MariaDB/MySQL/Aurora](https://satya-dba.blogspot.com/2019/05/mysql-mysqldbimport-import.html)
*   [mysqldiff utility in MySQL](https://satya-dba.blogspot.com/2018/12/mysql-mysqldiff-diff-commands.html)
*   [mysqldiskusage utility](https://satya-dba.blogspot.com/2019/03/mysql-mysqldiskusage-disk-usage.html)
*   [mysqldump commands](https://satya-dba.blogspot.com/2018/09/mysqldump-commands-mysql-dump.html)
*   [mysqlfailover commands in MySQL](https://satya-dba.blogspot.com/2018/12/mysql-mysqlfailover-failover.html)
*   [mysqlimport commands](https://satya-dba.blogspot.com/2018/10/mysql-mysqlimport-import.html)
*   [mysqlindexcheck utility commands in MySQL](https://satya-dba.blogspot.com/2019/05/mysqlindexcheck-mysql-index-check.html)
*   [mysqlpump commands in MySQL](https://satya-dba.blogspot.com/2021/08/mysql-pump-mysqlpump.html)
*   [mysqlrouter commands](https://satya-dba.blogspot.com/2023/04/mysql-router-mysqlrouter-commands.html)
*   [mysqlrpladmin utility commands](https://satya-dba.blogspot.com/2019/01/mysql-mysqlrpladmin-rpladmin-utility.html)
*   [mysqlrplcheck replication check utility](https://satya-dba.blogspot.com/2019/01/mysql-mysqlrplcheck-rplcheck-utility.html)
*   [mysqlrplms utility in MySQL](https://satya-dba.blogspot.com/2019/07/mysqlrplms-mysql-rpl-ms.html)
*   [mysqlrplshow utility commands in MySQL](https://satya-dba.blogspot.com/2019/02/mysql-mysqlrplshow-rplshow-utility.html)
*   [mysqlserverclone utility commands](https://satya-dba.blogspot.com/2019/05/mysqlserverclone-mysql-server-clone.html)
*   [mysqlserverinfo commands list](https://satya-dba.blogspot.com/2019/02/mysql-server-info-mysqlserverinfo.html)
*   [mysqlsh - MySQL Shell commands](https://satya-dba.blogspot.com/2023/04/mysqlsh-mysql-shell-usage-commands.html)
*   [mysqlshow utility commands](https://satya-dba.blogspot.com/2018/10/mysql-mysqlshow-show-utility.html)
*   [mysqlslap in Aurora/MySQL/MariaDB](https://satya-dba.blogspot.com/2019/07/mysql-mysqlslap-slap-test.html)
*   [New Features in MySQL 8.1 database](https://satya-dba.blogspot.com/2023/09/new-features-in-mysql-81-database.html)

DBA Interview Questions and Answers
-----------------------------------

*   [Cloud Database/DBA Interview Questions - part 1](https://satya-dba.blogspot.com/2022/01/cloud-dba-database-interview-questions.html)
*   [Cloud DBA/Database Interview Questions - part 2](https://satya-dba.blogspot.com/2023/04/aws-dba-database-interview-questions.html)
*   [Datawarehouse Interview Questions](https://satya-dba.blogspot.com/2021/10/data-warehouse-interview-questions.html)
*   [OGG (Oracle GoldenGate) Interview Questions Part2](https://satya-dba.blogspot.com/2018/11/ogg-oracle-goldengate-interview.html)
*   [Oracle AppsDBA (E-Business Suite) Interview Questions/FAQs](https://satya-dba.blogspot.com/2019/08/oracle-apps-dba-cloning-interview.html)
*   [Oracle ASM Interview Questions/FAQs](https://satya-dba.blogspot.com/2012/10/oracle-asm-interview-questions-faqs.html)
*   [Oracle Data Base Administrator Interview Questions/FAQs – Part3](https://satya-dba.blogspot.com/2012/10/dba-oracle-interview-questions-faqs.html)
*   [Oracle Data Guard Interview Questions/FAQs](https://satya-dba.blogspot.com/2012/10/dataguard-interview-questions-faqs.html)
*   [Oracle Database Admin Interview Questions/FAQs – Part1](https://satya-dba.blogspot.com/2012/10/oracle-dba-interview-questions-faqs.html)
*   [Oracle DataBase Administrator Interview Questions/FAQs – Part2](https://satya-dba.blogspot.com/2012/10/oracle-dba-interview-questionsfaqs.html)
*   [Oracle DBA interview questions answers](https://satya-dba.blogspot.com/2018/10/oracle-dba-interview-questions.html)
*   [Oracle DBA interview questions answers - Part5](https://satya-dba.blogspot.com/2021/10/oracle-dba-interview-questions-answers.html)
*   [Oracle DBA Interview Questions/FAQs – Part4](https://satya-dba.blogspot.com/2012/10/oracle-dba-interview-questions-faqs_22.html)
*   [Oracle DBA Online Quiz Questions/Answers](https://satya-dba.blogspot.com/2017/11/oracle-dba-online-quiz-interview.html)
*   [Oracle DBA Performance interview questions - Part1](https://satya-dba.blogspot.com/2018/10/oracle-dba-interview-questions.html)
*   [Oracle Exadata Interview Questions/FAQs](https://satya-dba.blogspot.com/2019/09/oracle-exadata-interview-questionsfaqs.html)
*   [Oracle Export/Import - Data Pump Interview Questions/FAQs](https://satya-dba.blogspot.com/2012/10/exportimport-data-pump-interview.html)
*   [Oracle GoldenGate (OGG) Interview Questions/FAQs Part1](https://satya-dba.blogspot.com/2012/10/goldengate-interview-questions-faqs.html)
*   [Oracle Performance related interview Questions/FAQs - Part2](https://satya-dba.blogspot.com/2012/10/oracle-performance-related-interview.html)
*   [Oracle PL/SQL Interview Questions/FAQs](https://satya-dba.blogspot.com/2012/10/oracle-plsql-interview-questionsfaqs.html)
*   [Oracle RAC Interview Questions/FAQs](https://satya-racdba.blogspot.com/2012/10/oracle-rac-interview-questions-faqs.html)
*   [Oracle RMAN Interview Questions/FAQs](https://satya-dba.blogspot.com/2012/10/oracle-rman-interview-questions-faqs.html)
*   [UNIX Interview Questions/FAQs for Oracle DBAs](https://satya-dba.blogspot.com/2012/10/unix-interview-questions-for-oracle-dbas.html)

Translator
----------

function googleTranslateElementInit() { new google.translate.TranslateElement({ pageLanguage: 'en', autoDisplay: 'true', layout: google.translate.TranslateElement.InlineLayout.SIMPLE }, 'google\_translate\_element'); }

PostgreSQL Articles
-------------------

*   [Comparison of Oracle PostgreSQL features](https://satya-dba.blogspot.com/2021/08/comparison-oracle-postgresql-commands.html)
*   [pg\_basebackup utility](https://satya-dba.blogspot.com/2021/05/pgbasebackup-postgresql-pg-basebackup.html)
*   [pg\_ctl commands](https://satya-dba.blogspot.com/2020/01/how-to-start-and-stop-postgresql-server.html)
*   [pg\_dumpall utility in PostgreSQL](https://satya-dba.blogspot.com/2021/05/postgres-pgdumpall-postgresql.html)
*   [pg\_restore PostgreSQL tool](https://satya-dba.blogspot.com/2021/05/pgrestore-postgresql-pg-restore.html)
*   [pg\_upgrade utility in PostgreSQL](https://satya-dba.blogspot.com/2023/04/postgres-pgupgrade-utility-pg.html)
*   [pg\_verifybackup tool in Postgres](https://satya-dba.blogspot.com/2023/04/postgres-pgverifybackup-tool-pg.html)
*   [pglogical replication between Aurora Postgres instances](https://satya-dba.blogspot.com/2022/09/pglogical-replication-between-aurora.html)
*   [Postgres 12/13 new features](https://satya-dba.blogspot.com/2022/10/postgres-new-features-in-postgresql-13.html)
*   [Postgres 14 new features](https://satya-dba.blogspot.com/2022/09/postgres-new-features-in-postgresql-14.html)
*   [Postgres 15 new features](https://satya-dba.blogspot.com/2022/10/postgres-new-features-in-postgresql-15.html)
*   [Postgres 16 new features](https://satya-dba.blogspot.com/2023/05/postgresql-16-new-features-postgres.html)
*   [Postgres initdb utility](https://satya-dba.blogspot.com/2023/04/postgres-initdb-postgresql-tool.html)
*   [PostgreSQL pg\_dump tool](https://satya-dba.blogspot.com/2021/05/pgdump-postgresql-utility.html)
*   [PostgreSQL/Aurora DBA Interview Questions Part1](https://satya-dba.blogspot.com/2021/07/postgresql-dba-interview-questions.html)
*   [PostgreSQL/Aurora Postgres DBA Interview Questions Part2](https://satya-dba.blogspot.com/2022/11/aurora-postgres-interview-questions.html)
*   [psql utility](https://satya-dba.blogspot.com/2021/05/postgresql-psql-postgres.html)
*   [vacuumdb utility commands](https://satya-dba.blogspot.com/2021/07/vacuumdb-postgresql-vacuum.html)

Percona/Percona XtraDB Cluster
------------------------------

*   [Percona XtraDB Cluster (PXC) Installation/Configuration](https://satya-dba.blogspot.com/2021/08/installing-percona-xtradb-cluster.html)
*   [ProxySQL 2 installation/configuration](https://satya-dba.blogspot.com/2021/09/installing-proxysql-configuration.html)
*   [Percona Toolkit Usage and Installation](https://satya-dba.blogspot.com/2021/09/installing-percona-toolkit-usage.html)
*   [Percona Xtrabackup Backup & Recovery (full/incremental)](https://satya-dba.blogspot.com/2021/09/percona-xtrabackup-installation.html)
*   [Percona Monitoring and Management (PMM) server/client](https://satya-dba.blogspot.com/2021/09/pmm-percona-monitoring-management.html)

Visitor Count (since Jan 2022)
------------------------------

//<!\[CDATA\[ var sc\_project=7550740; var sc\_invisible=0; var sc\_security="057c0587"; var scJsHost = (("https:" == document.location.protocol) ? "https://secure." : "http://www."); document.write("<sc"+"ript type='text/javascript' src='" + scJsHost+ "statcounter.com/counter/counter\_xhtml.js'></"+"script>"); //\]\]>

[![hit counter for blogger](https://lh3.googleusercontent.com/blogger_img_proxy/AEn0k_smC1dm9I8pjrZxd7kndMUbdwwy4148Mb_UM5t_plxAxojzmQN1muSnc_fo_zZ-1WKS9yq1HYBLEgm15wVCiryJWKIUjuXF_94m0tEwm1LwpiU=s0-d)](http://statcounter.com/blogger/ "hit counter for blogger")

OGG (Golden Gate) Articles
--------------------------

*   [ggsci - Oracle GoldenGate](https://satya-dba.blogspot.com/2012/02/ggsci-goldengate-command-interpreter.html)
*   [Golden Gate LogDump Utility Commands](https://satya-dba.blogspot.com/2013/09/golden-gate-logdump-utility-commands.html)
*   [GoldenGate utility adminclient commands](https://satya-dba.blogspot.com/2021/10/ogg-admin-client-adminclient.html)
*   [OGG checkprm utility](https://satya-dba.blogspot.com/2020/05/ogg-checkprm-utility-commands.html)
*   [Oracle Golden Gate (OGG) Interview Questions answers part 2](https://satya-dba.blogspot.com/2018/11/ogg-oracle-goldengate-interview.html)
*   [Oracle GoldenGate (OGG) Interview Questions answers part 1](https://satya-dba.blogspot.com/2012/10/goldengate-interview-questions-faqs.html)

Followers
---------

window.followersIframe = null; function followersIframeOpen(url) { gapi.load("gapi.iframes", function() { if (gapi.iframes && gapi.iframes.getContext) { window.followersIframe = gapi.iframes.getContext().openChild({ url: url, where: document.getElementById("followers-iframe-container"), messageHandlersFilter: gapi.iframes.CROSS\_ORIGIN\_IFRAMES\_FILTER, messageHandlers: { '\_ready': function(obj) { window.followersIframe.getIframeEl().height = obj.height; }, 'reset': function() { window.followersIframe.close(); followersIframeOpen("https://www.blogger.com/followers/frame/2511956539743992936?colors\\x3dCgt0cmFuc3BhcmVudBILdHJhbnNwYXJlbnQaByMzMzMzMzMiByNkNTJhMzMqByNmY2ZiZjUyByMzMzMzMzM6ByMzMzMzMzNCByNkNTJhMzNKByM2NjY2NjZSByNkNTJhMzNaC3RyYW5zcGFyZW50\\x26pageSize\\x3d21\\x26hl\\x3den\\x26origin\\x3dhttps://satya-dba.blogspot.com"); }, 'open': function(url) { window.followersIframe.close(); followersIframeOpen(url); } } }); } }); } followersIframeOpen("https://www.blogger.com/followers/frame/2511956539743992936?colors\\x3dCgt0cmFuc3BhcmVudBILdHJhbnNwYXJlbnQaByMzMzMzMzMiByNkNTJhMzMqByNmY2ZiZjUyByMzMzMzMzM6ByMzMzMzMzNCByNkNTJhMzNKByM2NjY2NjZSByNkNTJhMzNaC3RyYW5zcGFyZW50\\x26pageSize\\x3d21\\x26hl\\x3den\\x26origin\\x3dhttps://satya-dba.blogspot.com");

Popular Posts
-------------

*   [Oracle Data Guard broker utility - dgmgrl](https://satya-dba.blogspot.com/2010/09/dgmgrl-utility-tool-executable.html)
*   [30 Top Oracle RMAN basic/advanced Interview Questions for DBAs](https://satya-dba.blogspot.com/2012/10/oracle-rman-interview-questions-faqs.html)
*   [Oracle Export Import (exp & imp)](https://satya-dba.blogspot.com/2009/05/export-import.html)
*   [Temporary Tablespace in Oracle](https://satya-dba.blogspot.com/2009/07/temporary-tablespace-in-oracle.html)
*   [Background Processes in oracle](https://satya-dba.blogspot.com/2009/08/background-processes-in-oracle.html)
*   [Physical Standby Databases](https://satya-dba.blogspot.com/2012/06/physical-standby-databases-oracle.html)

Oracle Exadata Articles
-----------------------

*   [ipmitool Oracle Exadata](https://satya-dba.blogspot.com/2019/07/ipmitool-oracle-exadata.html)
*   [cellcli commands in Oracle Exadata](https://satya-dba.blogspot.com/2018/07/cellcli-commands-in-oracle-exadata.html)
*   [dcli commands in Oracle Exadata](https://satya-dba.blogspot.com/2018/08/dcli-commands-in-oracle-exadata.html)
*   [Differences between Full Half Quarter Racks](https://satya-dba.blogspot.com/2017/03/oracle-exadata-full-half-quarter-racks.html)
*   [Exadata Statistics](https://satya-dba.blogspot.com/2019/06/oracle-exadata-statistics.html)
*   [Exadata Wait Events](https://satya-dba.blogspot.com/2019/02/oracle-exadata-wait-events.html)
*   [InfiniBand Related Tools in Oracle Exadata](https://satya-dba.blogspot.com/2019/04/oracle-exadata-infiniband-related-tools.html)
*   [Oracle Exadata Interview Questions](https://satya-dba.blogspot.com/2019/09/oracle-exadata-interview-questionsfaqs.html)
*   [Oracle Exadata Interview Questions - Online Quiz](https://satya-dba.blogspot.com/2019/12/oracle-exadata-interview-questions-2020.html)
*   [Oracle Exadata Terminology](https://satya-dba.blogspot.com/2019/08/oracle-exadata-terms.html)
*   [Oracle Exadata X3](https://satya-dba.blogspot.com/2016/10/oracle-exadata-x3.html)

Oracle Apps DBA articles
------------------------

*   [Oracle Apps 11i/R12 DBA Cloning Interview Questions](https://satya-dba.blogspot.com/2019/06/oracle-apps-11ir12-dba-cloning.html)
*   [Oracle Apps DBA ad utilities Interview Questions answers Part 3](https://satya-dba.blogspot.com/2019/06/oracle-apps-dba-ad-utilities-interview.html)
*   [Oracle Apps DBA adutilities Interview Questions Part2](https://satya-dba.blogspot.com/2019/04/oracle-apps-dba-adutilities-interview.html)
*   [Oracle Apps DBA adutilities Interview Questions with answers Part1 \[ 2022 \]](https://satya-dba.blogspot.com/2019/12/oracle-apps-dba-adutilities-interview.html)
*   [Oracle Apps DBA Architecture Interview Questions/FAQs \[2022\]](https://satya-dba.blogspot.com/2019/10/oracle-apps-dba-architecture-interview.html)
*   [Oracle Apps DBA Cloning Interview Questions 11i/R12 \[ 2022 \]](https://satya-dba.blogspot.com/2019/08/oracle-apps-dba-cloning-interview.html)
*   [Oracle Apps DBA Patching Interview Questions/FAQs Part1](https://satya-dba.blogspot.com/2019/03/oracle-apps-dba-patching-interview.html)
*   [Oracle Apps DBA RDBMS Interview Questions with Answers 11i/R12 Part1](https://satya-dba.blogspot.com/2019/08/oracle-apps-dba-rdbms-interview.html)
*   [Oracle Apps DBA RDBMS Interview Questions/FAQs Part2](https://satya-dba.blogspot.com/2019/03/oracle-apps-dba-rdbms-interview.html)
*   [Oracle AppsDBA (Applications R12 E-Business Suite) Quiz Questions](https://satya-dba.blogspot.com/2019/11/oracle-appsdba-applications-r12-e.html)
*   [Oracle AppsDBA online Quiz](https://satya-dba.blogspot.com/2019/07/oracle-appsdba-online-quiz.html)
*   [Oracle AppsDBA Patching Interview Questions/FAQs Part2](https://satya-dba.blogspot.com/2019/06/oracle-appsdba-patching-interview.html)

Labels
------

[12.1.0](https://satya-dba.blogspot.com/search/label/12.1.0) (1) [12.2.0](https://satya-dba.blogspot.com/search/label/12.2.0) (1) [18c](https://satya-dba.blogspot.com/search/label/18c) (1) [19c Database](https://satya-dba.blogspot.com/search/label/19c%20Database) (1) [ADRCI Commands in Oracle](https://satya-dba.blogspot.com/search/label/ADRCI%20Commands%20in%20Oracle) (1) [Amazon Aurora](https://satya-dba.blogspot.com/search/label/Amazon%20Aurora) (2) [ASM](https://satya-dba.blogspot.com/search/label/ASM) (5) [asmcmd](https://satya-dba.blogspot.com/search/label/asmcmd) (2) [Auditing in Oracle](https://satya-dba.blogspot.com/search/label/Auditing%20in%20Oracle) (1) [Aurora PostgreSQL Interview Questions](https://satya-dba.blogspot.com/search/label/Aurora%20PostgreSQL%20Interview%20Questions) (2) [AWS](https://satya-dba.blogspot.com/search/label/AWS) (5) [AWS RDS](https://satya-dba.blogspot.com/search/label/AWS%20RDS) (2) [Background Processes](https://satya-dba.blogspot.com/search/label/Background%20Processes) (1) [Best Oracle Database 21c new features](https://satya-dba.blogspot.com/search/label/Best%20Oracle%20Database%2021c%20new%20features) (1) [Best Oracle Database 23c new features](https://satya-dba.blogspot.com/search/label/Best%20Oracle%20Database%2023c%20new%20features) (1) [Bits n Bytes](https://satya-dba.blogspot.com/search/label/Bits%20n%20Bytes) (1) [Block Change Tracking file](https://satya-dba.blogspot.com/search/label/Block%20Change%20Tracking%20file) (1) [cellcli commands Exadata](https://satya-dba.blogspot.com/search/label/cellcli%20commands%20Exadata) (1) [Cloud DBA Interview Questions](https://satya-dba.blogspot.com/search/label/Cloud%20DBA%20Interview%20Questions) (2) [Comparison between Oracle and PostgreSQL](https://satya-dba.blogspot.com/search/label/Comparison%20between%20Oracle%20and%20PostgreSQL) (1) [Data Dictionary Views](https://satya-dba.blogspot.com/search/label/Data%20Dictionary%20Views) (1) [Data Pump expdp impdp](https://satya-dba.blogspot.com/search/label/Data%20Pump%20expdp%20impdp) (1) [Data Pump Export Import](https://satya-dba.blogspot.com/search/label/Data%20Pump%20Export%20Import) (1) [Data Warehouse Interview Questions and answers](https://satya-dba.blogspot.com/search/label/Data%20Warehouse%20Interview%20Questions%20and%20answers) (1) [Database Administrator](https://satya-dba.blogspot.com/search/label/Database%20Administrator) (3) [Databases in the world](https://satya-dba.blogspot.com/search/label/Databases%20in%20the%20world) (1) [DataDictionary views Vs V$ views](https://satya-dba.blogspot.com/search/label/DataDictionary%20views%20Vs%20V%24%20views) (1) [DBA Interview Questions (Part3)](https://satya-dba.blogspot.com/search/label/DBA%20Interview%20Questions%20%28Part3%29) (1) [DBMS\_STATS - Statistics](https://satya-dba.blogspot.com/search/label/DBMS_STATS%20-%20Statistics) (1) [dcli commands Exadata](https://satya-dba.blogspot.com/search/label/dcli%20commands%20Exadata) (1) [ddbsh commands](https://satya-dba.blogspot.com/search/label/ddbsh%20commands) (1) [dgmgrl utility](https://satya-dba.blogspot.com/search/label/dgmgrl%20utility) (1) [DynamoDB](https://satya-dba.blogspot.com/search/label/DynamoDB) (1) [emca commands](https://satya-dba.blogspot.com/search/label/emca%20commands) (1) [emcli commands](https://satya-dba.blogspot.com/search/label/emcli%20commands) (1) [emctl commands](https://satya-dba.blogspot.com/search/label/emctl%20commands) (1) [Essential 25+ Oracle DBA Data Guard Interview Questions](https://satya-dba.blogspot.com/search/label/Essential%2025%2B%20Oracle%20DBA%20Data%20Guard%20Interview%20Questions) (1) [Exadata Full Half Quarter Racks](https://satya-dba.blogspot.com/search/label/Exadata%20Full%20Half%20Quarter%20Racks) (1) [Exadata InfiniBand Related Tools](https://satya-dba.blogspot.com/search/label/Exadata%20InfiniBand%20Related%20Tools) (1) [Exadata Mock Test](https://satya-dba.blogspot.com/search/label/Exadata%20Mock%20Test) (1) [Exadata Quiz](https://satya-dba.blogspot.com/search/label/Exadata%20Quiz) (1) [Exadata Statistics](https://satya-dba.blogspot.com/search/label/Exadata%20Statistics) (1) [Exadata Terms](https://satya-dba.blogspot.com/search/label/Exadata%20Terms) (1) [exp & imp in Oracle](https://satya-dba.blogspot.com/search/label/exp%20%26%20imp%20in%20Oracle) (1) [Export and Import](https://satya-dba.blogspot.com/search/label/Export%20and%20Import) (1) [Export/Import - Data Pump Interview Questions](https://satya-dba.blogspot.com/search/label/Export%2FImport%20-%20Data%20Pump%20Interview%20Questions) (1) [Flash Recovery Area (FRA)](https://satya-dba.blogspot.com/search/label/Flash%20Recovery%20Area%20%28FRA%29) (1) [Flashback](https://satya-dba.blogspot.com/search/label/Flashback) (1) [Flashback Query](https://satya-dba.blogspot.com/search/label/Flashback%20Query) (1) [Frequently asked DBA Interview Questions (Part2)](https://satya-dba.blogspot.com/search/label/Frequently%20asked%20DBA%20Interview%20Questions%20%28Part2%29) (1) [ggsci](https://satya-dba.blogspot.com/search/label/ggsci) (1) [Indexes on Partitions](https://satya-dba.blogspot.com/search/label/Indexes%20on%20Partitions) (1) [initdb tool](https://satya-dba.blogspot.com/search/label/initdb%20tool) (1) [Interview Questions](https://satya-dba.blogspot.com/search/label/Interview%20Questions) (9) [ipmitool - Exadata](https://satya-dba.blogspot.com/search/label/ipmitool%20-%20Exadata) (1) [Logical Standby Databases](https://satya-dba.blogspot.com/search/label/Logical%20Standby%20Databases) (1) [Managing Oracle partitions](https://satya-dba.blogspot.com/search/label/Managing%20Oracle%20partitions) (1) [MariaBackup commands](https://satya-dba.blogspot.com/search/label/MariaBackup%20commands) (1) [MariaDB](https://satya-dba.blogspot.com/search/label/MariaDB) (4) [Materialized View Log](https://satya-dba.blogspot.com/search/label/Materialized%20View%20Log) (1) [Materialized View Types](https://satya-dba.blogspot.com/search/label/Materialized%20View%20Types) (1) [Materialized Views](https://satya-dba.blogspot.com/search/label/Materialized%20Views) (1) [Materialized Views Refresh Groups](https://satya-dba.blogspot.com/search/label/Materialized%20Views%20Refresh%20Groups) (1) [MySQL](https://satya-dba.blogspot.com/search/label/MySQL) (14) [MySQL 8.1 new features](https://satya-dba.blogspot.com/search/label/MySQL%208.1%20new%20features) (1) [mysql commands](https://satya-dba.blogspot.com/search/label/mysql%20commands) (1) [MySQL DBA Interview Questions And Answers](https://satya-dba.blogspot.com/search/label/MySQL%20DBA%20Interview%20Questions%20And%20Answers) (1) [MySQL DBA Mock Test](https://satya-dba.blogspot.com/search/label/MySQL%20DBA%20Mock%20Test) (1) [MySQL DBA Online Quiz](https://satya-dba.blogspot.com/search/label/MySQL%20DBA%20Online%20Quiz) (1) [MySQL interview questions answers](https://satya-dba.blogspot.com/search/label/MySQL%20interview%20questions%20answers) (3) [MySQL mysqlbinlogmove utility commands](https://satya-dba.blogspot.com/search/label/MySQL%20mysqlbinlogmove%20utility%20commands) (1) [MySQL Quiz Questions and answers](https://satya-dba.blogspot.com/search/label/MySQL%20Quiz%20Questions%20and%20answers) (1) [MySQL Shell](https://satya-dba.blogspot.com/search/label/MySQL%20Shell) (1) [MySQL Tools](https://satya-dba.blogspot.com/search/label/MySQL%20Tools) (13) [MySQL utilities](https://satya-dba.blogspot.com/search/label/MySQL%20utilities) (11) [MySQL utility](https://satya-dba.blogspot.com/search/label/MySQL%20utility) (11) [mysql\_config\_editor commands](https://satya-dba.blogspot.com/search/label/mysql_config_editor%20commands) (1) [mysql\_install\_db utility usage](https://satya-dba.blogspot.com/search/label/mysql_install_db%20utility%20usage) (1) [mysql\_secure\_installation utility](https://satya-dba.blogspot.com/search/label/mysql_secure_installation%20utility) (1) [mysql\_upgrade commands](https://satya-dba.blogspot.com/search/label/mysql_upgrade%20commands) (1) [mysqladmin commands](https://satya-dba.blogspot.com/search/label/mysqladmin%20commands) (1) [mysqlauditadmin Utility cheatsheet](https://satya-dba.blogspot.com/search/label/mysqlauditadmin%20Utility%20cheatsheet) (1) [mysqlauditgrep commands](https://satya-dba.blogspot.com/search/label/mysqlauditgrep%20commands) (1) [mysqlbackup commands](https://satya-dba.blogspot.com/search/label/mysqlbackup%20commands) (1) [mysqlbinlog commands](https://satya-dba.blogspot.com/search/label/mysqlbinlog%20commands) (1) [mysqlbinlogpurge commands](https://satya-dba.blogspot.com/search/label/mysqlbinlogpurge%20commands) (1) [mysqlbinlogrotate example commands](https://satya-dba.blogspot.com/search/label/mysqlbinlogrotate%20example%20commands) (1) [mysqlcheck commands](https://satya-dba.blogspot.com/search/label/mysqlcheck%20commands) (1) [mysqld\_multi utility commands](https://satya-dba.blogspot.com/search/label/mysqld_multi%20utility%20commands) (1) [mysqldbcompare commands](https://satya-dba.blogspot.com/search/label/mysqldbcompare%20commands) (1) [mysqldbcopy utility cheatsheet](https://satya-dba.blogspot.com/search/label/mysqldbcopy%20utility%20cheatsheet) (1) [mysqldbexport commands cheatsheet](https://satya-dba.blogspot.com/search/label/mysqldbexport%20commands%20cheatsheet) (1) [mysqldbimport usage](https://satya-dba.blogspot.com/search/label/mysqldbimport%20usage) (1) [mysqldiff commands](https://satya-dba.blogspot.com/search/label/mysqldiff%20commands) (1) [mysqldiskusage utility](https://satya-dba.blogspot.com/search/label/mysqldiskusage%20utility) (1) [mysqldump commands](https://satya-dba.blogspot.com/search/label/mysqldump%20commands) (1) [mysqldumpslow utility commands](https://satya-dba.blogspot.com/search/label/mysqldumpslow%20utility%20commands) (1) [mysqlfailover utility commands](https://satya-dba.blogspot.com/search/label/mysqlfailover%20utility%20commands) (1) [mysqlfrm utility examples](https://satya-dba.blogspot.com/search/label/mysqlfrm%20utility%20examples) (1) [mysqlgrants utility examples](https://satya-dba.blogspot.com/search/label/mysqlgrants%20utility%20examples) (1) [mysqlimport commands](https://satya-dba.blogspot.com/search/label/mysqlimport%20commands) (1) [mysqlindexcheck utility in MySQL](https://satya-dba.blogspot.com/search/label/mysqlindexcheck%20utility%20in%20MySQL) (1) [mysqlmetagrep utility](https://satya-dba.blogspot.com/search/label/mysqlmetagrep%20utility) (1) [mysqlprocgrep utility](https://satya-dba.blogspot.com/search/label/mysqlprocgrep%20utility) (1) [mysqlpump utility](https://satya-dba.blogspot.com/search/label/mysqlpump%20utility) (1) [mysqlreplicate commands](https://satya-dba.blogspot.com/search/label/mysqlreplicate%20commands) (1) [mysqlrouter](https://satya-dba.blogspot.com/search/label/mysqlrouter) (1) [mysqlrpladmin utility commands](https://satya-dba.blogspot.com/search/label/mysqlrpladmin%20utility%20commands) (1) [mysqlrplcheck utility](https://satya-dba.blogspot.com/search/label/mysqlrplcheck%20utility) (1) [mysqlrplms utility in MySQL](https://satya-dba.blogspot.com/search/label/mysqlrplms%20utility%20in%20MySQL) (1) [mysqlrplshow utility commands](https://satya-dba.blogspot.com/search/label/mysqlrplshow%20utility%20commands) (1) [mysqlrplsync utility](https://satya-dba.blogspot.com/search/label/mysqlrplsync%20utility) (1) [mysqlserverclone utility](https://satya-dba.blogspot.com/search/label/mysqlserverclone%20utility) (1) [mysqlserverinfo utility](https://satya-dba.blogspot.com/search/label/mysqlserverinfo%20utility) (1) [mysqlsh](https://satya-dba.blogspot.com/search/label/mysqlsh) (1) [mysqlshow commands](https://satya-dba.blogspot.com/search/label/mysqlshow%20commands) (1) [mysqlslap utility](https://satya-dba.blogspot.com/search/label/mysqlslap%20utility) (1) [mysqlslavetrx utility commands](https://satya-dba.blogspot.com/search/label/mysqlslavetrx%20utility%20commands) (1) [mysqluc utility](https://satya-dba.blogspot.com/search/label/mysqluc%20utility) (1) [mysqluserclone example commands](https://satya-dba.blogspot.com/search/label/mysqluserclone%20example%20commands) (1) [New features in Oracle Database 18c release 1 release 2 release3](https://satya-dba.blogspot.com/search/label/New%20features%20in%20Oracle%20Database%2018c%20release%201%20release%202%20release3) (1) [NID Utility (DBNEWID Utility)](https://satya-dba.blogspot.com/search/label/NID%20Utility%20%28DBNEWID%20Utility%29) (1) [OGG adminclient utility](https://satya-dba.blogspot.com/search/label/OGG%20adminclient%20utility) (1) [OGG checkprm utility](https://satya-dba.blogspot.com/search/label/OGG%20checkprm%20utility) (1) [omsca commands](https://satya-dba.blogspot.com/search/label/omsca%20commands) (1) [opatchauto](https://satya-dba.blogspot.com/search/label/opatchauto) (1) [Operations on Oracle Partitions](https://satya-dba.blogspot.com/search/label/Operations%20on%20Oracle%20Partitions) (1) [orachk utility in Oracle](https://satya-dba.blogspot.com/search/label/orachk%20utility%20in%20Oracle) (1) [Oracle](https://satya-dba.blogspot.com/search/label/Oracle) (1) [Oracle 12c](https://satya-dba.blogspot.com/search/label/Oracle%2012c) (2) [Oracle 21c](https://satya-dba.blogspot.com/search/label/Oracle%2021c) (1) [Oracle 23c](https://satya-dba.blogspot.com/search/label/Oracle%2023c) (1) [Oracle Applications R12 E-Business Suite](https://satya-dba.blogspot.com/search/label/Oracle%20Applications%20R12%20E-Business%20Suite) (2) [Oracle Apps DBA](https://satya-dba.blogspot.com/search/label/Oracle%20Apps%20DBA) (7) [Oracle Apps DBA Interview Questions and answers for experienced](https://satya-dba.blogspot.com/search/label/Oracle%20Apps%20DBA%20Interview%20Questions%20and%20answers%20for%20experienced) (3) [Oracle Apps DBA Interview Questions with answers for experienced](https://satya-dba.blogspot.com/search/label/Oracle%20Apps%20DBA%20Interview%20Questions%20with%20answers%20for%20experienced) (2) [Oracle Apps DBA Interview Questions/FAQs](https://satya-dba.blogspot.com/search/label/Oracle%20Apps%20DBA%20Interview%20Questions%2FFAQs) (5) [Oracle Apps DBA Mock Test](https://satya-dba.blogspot.com/search/label/Oracle%20Apps%20DBA%20Mock%20Test) (2) [Oracle Apps DBA Quiz answers](https://satya-dba.blogspot.com/search/label/Oracle%20Apps%20DBA%20Quiz%20answers) (2) [Oracle AppsDBA Interview Questions And Answers](https://satya-dba.blogspot.com/search/label/Oracle%20AppsDBA%20Interview%20Questions%20And%20Answers) (2) [Oracle AppsDBA Online Quiz](https://satya-dba.blogspot.com/search/label/Oracle%20AppsDBA%20Online%20Quiz) (2) [Oracle AppsDBA Quiz Questions](https://satya-dba.blogspot.com/search/label/Oracle%20AppsDBA%20Quiz%20Questions) (2) [Oracle AppsDBA R12](https://satya-dba.blogspot.com/search/label/Oracle%20AppsDBA%20R12) (3) [Oracle ASM library (ASMLib)](https://satya-dba.blogspot.com/search/label/Oracle%20ASM%20library%20%28ASMLib%29) (1) [Oracle Automatic Storage Management](https://satya-dba.blogspot.com/search/label/Oracle%20Automatic%20Storage%20Management) (1) [Oracle Certifications (for DBAs)](https://satya-dba.blogspot.com/search/label/Oracle%20Certifications%20%28for%20DBAs%29) (1) [Oracle Data Guard Interview Questions](https://satya-dba.blogspot.com/search/label/Oracle%20Data%20Guard%20Interview%20Questions) (1) [Oracle Data Guard Manager Utility](https://satya-dba.blogspot.com/search/label/Oracle%20Data%20Guard%20Manager%20Utility) (1) [Oracle Database 19c new features](https://satya-dba.blogspot.com/search/label/Oracle%20Database%2019c%20new%20features) (1) [Oracle Database 21c](https://satya-dba.blogspot.com/search/label/Oracle%20Database%2021c) (1) [Oracle Database 23c](https://satya-dba.blogspot.com/search/label/Oracle%20Database%2023c) (1) [Oracle Database Administrator](https://satya-dba.blogspot.com/search/label/Oracle%20Database%20Administrator) (1) [Oracle Database Adminstrator](https://satya-dba.blogspot.com/search/label/Oracle%20Database%20Adminstrator) (1) [Oracle Database Auditing](https://satya-dba.blogspot.com/search/label/Oracle%20Database%20Auditing) (1) [Oracle DBA](https://satya-dba.blogspot.com/search/label/Oracle%20DBA) (3) [Oracle DBA ASM Interview Questions](https://satya-dba.blogspot.com/search/label/Oracle%20DBA%20ASM%20Interview%20Questions) (1) [Oracle DBA Interview Questions](https://satya-dba.blogspot.com/search/label/Oracle%20DBA%20Interview%20Questions) (4) [Oracle DBA Interview Questions (Part1)](https://satya-dba.blogspot.com/search/label/Oracle%20DBA%20Interview%20Questions%20%28Part1%29) (1) [Oracle DBA Interview Questions And Answers](https://satya-dba.blogspot.com/search/label/Oracle%20DBA%20Interview%20Questions%20And%20Answers) (2) [Oracle DBA interview questions answers](https://satya-dba.blogspot.com/search/label/Oracle%20DBA%20interview%20questions%20answers) (1) [Oracle DBA Mock Test](https://satya-dba.blogspot.com/search/label/Oracle%20DBA%20Mock%20Test) (1) [Oracle DBA Online Quiz](https://satya-dba.blogspot.com/search/label/Oracle%20DBA%20Online%20Quiz) (1) [Oracle DBA Quiz answers](https://satya-dba.blogspot.com/search/label/Oracle%20DBA%20Quiz%20answers) (1) [Oracle DBA Quiz Questions](https://satya-dba.blogspot.com/search/label/Oracle%20DBA%20Quiz%20Questions) (1) [Oracle Exadata Interview Questions And Answers](https://satya-dba.blogspot.com/search/label/Oracle%20Exadata%20Interview%20Questions%20And%20Answers) (1) [Oracle Exadata Interview Questions/FAQs](https://satya-dba.blogspot.com/search/label/Oracle%20Exadata%20Interview%20Questions%2FFAQs) (1) [Oracle Exadata X3](https://satya-dba.blogspot.com/search/label/Oracle%20Exadata%20X3) (1) [Oracle Golden Gate (OGG)](https://satya-dba.blogspot.com/search/label/Oracle%20Golden%20Gate%20%28OGG%29) (6) [Oracle GoldenGate Interview Questions](https://satya-dba.blogspot.com/search/label/Oracle%20GoldenGate%20Interview%20Questions) (1) [Oracle GoldenGate LogDump Utility](https://satya-dba.blogspot.com/search/label/Oracle%20GoldenGate%20LogDump%20Utility) (1) [Oracle lsnrctl commands](https://satya-dba.blogspot.com/search/label/Oracle%20lsnrctl%20commands) (1) [Oracle Password file orapwd utility](https://satya-dba.blogspot.com/search/label/Oracle%20Password%20file%20orapwd%20utility) (1) [Oracle Profiles](https://satya-dba.blogspot.com/search/label/Oracle%20Profiles) (1) [Oracle RMAN (Recovery Manager)](https://satya-dba.blogspot.com/search/label/Oracle%20RMAN%20%28Recovery%20Manager%29) (1) [Oracle Snapshot Standby Databases](https://satya-dba.blogspot.com/search/label/Oracle%20Snapshot%20Standby%20Databases) (1) [Oracle Solaris 11](https://satya-dba.blogspot.com/search/label/Oracle%20Solaris%2011) (1) [Oracle SQL\*Loader](https://satya-dba.blogspot.com/search/label/Oracle%20SQL*Loader) (1) [oracleasm](https://satya-dba.blogspot.com/search/label/oracleasm) (1) [ORADEBUG Utility](https://satya-dba.blogspot.com/search/label/ORADEBUG%20Utility) (1) [oraversion utility](https://satya-dba.blogspot.com/search/label/oraversion%20utility) (1) [Partitioning](https://satya-dba.blogspot.com/search/label/Partitioning) (1) [Password file (orapwd)](https://satya-dba.blogspot.com/search/label/Password%20file%20%28orapwd%29) (1) [Percona](https://satya-dba.blogspot.com/search/label/Percona) (5) [Percona Monitoring and Management](https://satya-dba.blogspot.com/search/label/Percona%20Monitoring%20and%20Management) (1) [Percona Toolkit](https://satya-dba.blogspot.com/search/label/Percona%20Toolkit) (1) [Percona Xtrabackup](https://satya-dba.blogspot.com/search/label/Percona%20Xtrabackup) (1) [Performance related interview Questions](https://satya-dba.blogspot.com/search/label/Performance%20related%20interview%20Questions) (2) [pg\_basebackup](https://satya-dba.blogspot.com/search/label/pg_basebackup) (1) [pg\_ctl commands](https://satya-dba.blogspot.com/search/label/pg_ctl%20commands) (1) [pg\_dump](https://satya-dba.blogspot.com/search/label/pg_dump) (1) [pg\_dumpall](https://satya-dba.blogspot.com/search/label/pg_dumpall) (1) [pg\_restore](https://satya-dba.blogspot.com/search/label/pg_restore) (1) [pg\_upgrade utility](https://satya-dba.blogspot.com/search/label/pg_upgrade%20utility) (1) [pg\_verifybackup tool](https://satya-dba.blogspot.com/search/label/pg_verifybackup%20tool) (1) [pglogical replication](https://satya-dba.blogspot.com/search/label/pglogical%20replication) (1) [Physical Standby Databases](https://satya-dba.blogspot.com/search/label/Physical%20Standby%20Databases) (1) [PL/SQL Interview Questions](https://satya-dba.blogspot.com/search/label/PL%2FSQL%20Interview%20Questions) (1) [Postgres](https://satya-dba.blogspot.com/search/label/Postgres) (8) [PostgreSQL](https://satya-dba.blogspot.com/search/label/PostgreSQL) (10) [PostgreSQL 12](https://satya-dba.blogspot.com/search/label/PostgreSQL%2012) (1) [PostgreSQL 13](https://satya-dba.blogspot.com/search/label/PostgreSQL%2013) (1) [PostgreSQL 14](https://satya-dba.blogspot.com/search/label/PostgreSQL%2014) (1) [PostgreSQL 15](https://satya-dba.blogspot.com/search/label/PostgreSQL%2015) (1) [PostgreSQL 16](https://satya-dba.blogspot.com/search/label/PostgreSQL%2016) (1) [PostgreSQL DBA Interview Questions](https://satya-dba.blogspot.com/search/label/PostgreSQL%20DBA%20Interview%20Questions) (2) [ProxySQL](https://satya-dba.blogspot.com/search/label/ProxySQL) (1) [psql](https://satya-dba.blogspot.com/search/label/psql) (1) [PXC Percona XtraDB Cluster](https://satya-dba.blogspot.com/search/label/PXC%20Percona%20XtraDB%20Cluster) (5) [Realtime Interview Questions](https://satya-dba.blogspot.com/search/label/Realtime%20Interview%20Questions) (1) [Recycle bin](https://satya-dba.blogspot.com/search/label/Recycle%20bin) (1) [Release 1](https://satya-dba.blogspot.com/search/label/Release%201) (1) [Release 2](https://satya-dba.blogspot.com/search/label/Release%202) (1) [Remote Diagnostic Agent (RDA)](https://satya-dba.blogspot.com/search/label/Remote%20Diagnostic%20Agent%20%28RDA%29) (1) [RMAN (Recovery Manager)](https://satya-dba.blogspot.com/search/label/RMAN%20%28Recovery%20Manager%29) (4) [RMAN Commands](https://satya-dba.blogspot.com/search/label/RMAN%20Commands) (1) [RMAN Incremental Backups](https://satya-dba.blogspot.com/search/label/RMAN%20Incremental%20Backups) (1) [RMAN Interview Questions](https://satya-dba.blogspot.com/search/label/RMAN%20Interview%20Questions) (1) [Rollback Segments](https://satya-dba.blogspot.com/search/label/Rollback%20Segments) (1) [Setting SQL prompt](https://satya-dba.blogspot.com/search/label/Setting%20SQL%20prompt) (1) [Solaris Interview Questions](https://satya-dba.blogspot.com/search/label/Solaris%20Interview%20Questions) (1) [sqlcl commands](https://satya-dba.blogspot.com/search/label/sqlcl%20commands) (1) [Startup/Shutdown Options](https://satya-dba.blogspot.com/search/label/Startup%2FShutdown%20Options) (1) [Statspack](https://satya-dba.blogspot.com/search/label/Statspack) (1) [Temp file](https://satya-dba.blogspot.com/search/label/Temp%20file) (1) [Temporary Tablespace](https://satya-dba.blogspot.com/search/label/Temporary%20Tablespace) (1) [Temporary Tablespace Group](https://satya-dba.blogspot.com/search/label/Temporary%20Tablespace%20Group) (1) [Test Your Exadata Knowledge/Skills](https://satya-dba.blogspot.com/search/label/Test%20Your%20Exadata%20Knowledge%2FSkills) (1) [Test Your MySQL DBA Skills](https://satya-dba.blogspot.com/search/label/Test%20Your%20MySQL%20DBA%20Skills) (1) [Test Your Oracle Apps DBA Skills](https://satya-dba.blogspot.com/search/label/Test%20Your%20Oracle%20Apps%20DBA%20Skills) (2) [Test Your Oracle DBA Skills](https://satya-dba.blogspot.com/search/label/Test%20Your%20Oracle%20DBA%20Skills) (1) [Top 20 Oracle DBA Interview Questions answers](https://satya-dba.blogspot.com/search/label/Top%2020%20Oracle%20DBA%20Interview%20Questions%20answers) (1) [Transportable Tablespaces (TTS)](https://satya-dba.blogspot.com/search/label/Transportable%20Tablespaces%20%28TTS%29) (1) [Undo Tablespace/Management](https://satya-dba.blogspot.com/search/label/Undo%20Tablespace%2FManagement) (1) [UNIX Interview Questions for Oracle DBAs](https://satya-dba.blogspot.com/search/label/UNIX%20Interview%20Questions%20for%20Oracle%20DBAs) (1) [vacuumdb utility commands](https://satya-dba.blogspot.com/search/label/vacuumdb%20utility%20commands) (1) [Wait Events in Exadata](https://satya-dba.blogspot.com/search/label/Wait%20Events%20in%20Exadata) (1) [wait events in Oracle](https://satya-dba.blogspot.com/search/label/wait%20events%20in%20Oracle) (1) [What's New in 10g Release 1/2](https://satya-dba.blogspot.com/search/label/What%27s%20New%20in%2010g%20Release%201%2F2) (1) [What's New in 11g Release 1](https://satya-dba.blogspot.com/search/label/What%27s%20New%20in%2011g%20Release%201) (1) [What's New in 11g Release 2](https://satya-dba.blogspot.com/search/label/What%27s%20New%20in%2011g%20Release%202) (1) [What's New in 9i Release 1/2](https://satya-dba.blogspot.com/search/label/What%27s%20New%20in%209i%20Release%201%2F2) (1) [What's New in MySQL 8.1](https://satya-dba.blogspot.com/search/label/What%27s%20New%20in%20MySQL%208.1) (1) [What's New in Oracle 12c](https://satya-dba.blogspot.com/search/label/What%27s%20New%20in%20Oracle%2012c) (2) [What's new in Oracle 18c](https://satya-dba.blogspot.com/search/label/What%27s%20new%20in%20Oracle%2018c) (1)

Powered by [Blogger](https://www.blogger.com).

var infolinks\_pid = 1190123; var infolinks\_wsid = 0;

window.setTimeout(function() { document.body.className = document.body.className.replace('loading', ''); }, 10); window\['\_\_wavt'\] = 'AOuZoY4T8FK0sVnwAI0oL0jpNONUezHD8w:1749498442938';\_WidgetManager.\_Init('//www.blogger.com/rearrange?blogID\\x3d2511956539743992936','//satya-dba.blogspot.com/2009/08/background-processes-in-oracle.html','2511956539743992936'); \_WidgetManager.\_SetDataContext(\[{'name': 'blog', 'data': {'blogId': '2511956539743992936', 'title': 'Satya\\x27s DBA Blog', 'url': 'https://satya-dba.blogspot.com/2009/08/background-processes-in-oracle.html', 'canonicalUrl': 'https://satya-dba.blogspot.com/2009/08/background-processes-in-oracle.html', 'homepageUrl': 'https://satya-dba.blogspot.com/', 'searchUrl': 'https://satya-dba.blogspot.com/search', 'canonicalHomepageUrl': 'https://satya-dba.blogspot.com/', 'blogspotFaviconUrl': 'https://satya-dba.blogspot.com/favicon.ico', 'bloggerUrl': 'https://www.blogger.com', 'hasCustomDomain': false, 'httpsEnabled': true, 'enabledCommentProfileImages': true, 'gPlusViewType': 'FILTERED\_POSTMOD', 'adultContent': false, 'analyticsAccountNumber': 'UA-27465268-1', 'encoding': 'UTF-8', 'locale': 'en', 'localeUnderscoreDelimited': 'en', 'languageDirection': 'ltr', 'isPrivate': false, 'isMobile': false, 'isMobileRequest': false, 'mobileClass': '', 'isPrivateBlog': false, 'isDynamicViewsAvailable': true, 'feedLinks': '\\x3clink rel\\x3d\\x22alternate\\x22 type\\x3d\\x22application/atom+xml\\x22 title\\x3d\\x22Satya\\x26#39;s DBA Blog - Atom\\x22 href\\x3d\\x22https://satya-dba.blogspot.com/feeds/posts/default\\x22 /\\x3e\\n\\x3clink rel\\x3d\\x22alternate\\x22 type\\x3d\\x22application/rss+xml\\x22 title\\x3d\\x22Satya\\x26#39;s DBA Blog - RSS\\x22 href\\x3d\\x22https://satya-dba.blogspot.com/feeds/posts/default?alt\\x3drss\\x22 /\\x3e\\n\\x3clink rel\\x3d\\x22service.post\\x22 type\\x3d\\x22application/atom+xml\\x22 title\\x3d\\x22Satya\\x26#39;s DBA Blog - Atom\\x22 href\\x3d\\x22https://www.blogger.com/feeds/2511956539743992936/posts/default\\x22 /\\x3e\\n\\n\\x3clink rel\\x3d\\x22alternate\\x22 type\\x3d\\x22application/atom+xml\\x22 title\\x3d\\x22Satya\\x26#39;s DBA Blog - Atom\\x22 href\\x3d\\x22https://satya-dba.blogspot.com/feeds/6323685730910210915/comments/default\\x22 /\\x3e\\n', 'meTag': '', 'adsenseHostId': 'ca-host-pub-1556223355139109', 'adsenseHasAds': false, 'adsenseAutoAds': false, 'boqCommentIframeForm': true, 'loginRedirectParam': '', 'view': '', 'dynamicViewsCommentsSrc': '//www.blogblog.com/dynamicviews/4224c15c4e7c9321/js/comments.js', 'dynamicViewsScriptSrc': '//www.blogblog.com/dynamicviews/0af581e0b182fc0a', 'plusOneApiSrc': 'https://apis.google.com/js/platform.js', 'disableGComments': true, 'interstitialAccepted': false, 'sharing': {'platforms': \[{'name': 'Get link', 'key': 'link', 'shareMessage': 'Get link', 'target': ''}, {'name': 'Facebook', 'key': 'facebook', 'shareMessage': 'Share to Facebook', 'target': 'facebook'}, {'name': 'BlogThis!', 'key': 'blogThis', 'shareMessage': 'BlogThis!', 'target': 'blog'}, {'name': 'X', 'key': 'twitter', 'shareMessage': 'Share to X', 'target': 'twitter'}, {'name': 'Pinterest', 'key': 'pinterest', 'shareMessage': 'Share to Pinterest', 'target': 'pinterest'}, {'name': 'Email', 'key': 'email', 'shareMessage': 'Email', 'target': 'email'}\], 'disableGooglePlus': true, 'googlePlusShareButtonWidth': 0, 'googlePlusBootstrap': '\\x3cscript type\\x3d\\x22text/javascript\\x22\\x3ewindow.\_\_\_gcfg \\x3d {\\x27lang\\x27: \\x27en\\x27};\\x3c/script\\x3e'}, 'hasCustomJumpLinkMessage': false, 'jumpLinkMessage': 'Read more', 'pageType': 'item', 'postId': '6323685730910210915', 'pageName': 'Background Processes in oracle', 'pageTitle': 'Satya\\x27s DBA Blog: Background Processes in oracle', 'metaDescription': 'Mandatory Background Processes in Oracle Database, Optional Background Processes in Oracle 10g and Oracle 11g'}}, {'name': 'features', 'data': {}}, {'name': 'messages', 'data': {'edit': 'Edit', 'linkCopiedToClipboard': 'Link copied to clipboard!', 'ok': 'Ok', 'postLink': 'Post Link'}}, {'name': 'template', 'data': {'name': 'custom', 'localizedName': 'Custom', 'isResponsive': false, 'isAlternateRendering': false, 'isCustom': true}}, {'name': 'view', 'data': {'classic': {'name': 'classic', 'url': '?view\\x3dclassic'}, 'flipcard': {'name': 'flipcard', 'url': '?view\\x3dflipcard'}, 'magazine': {'name': 'magazine', 'url': '?view\\x3dmagazine'}, 'mosaic': {'name': 'mosaic', 'url': '?view\\x3dmosaic'}, 'sidebar': {'name': 'sidebar', 'url': '?view\\x3dsidebar'}, 'snapshot': {'name': 'snapshot', 'url': '?view\\x3dsnapshot'}, 'timeslide': {'name': 'timeslide', 'url': '?view\\x3dtimeslide'}, 'isMobile': false, 'title': 'Background Processes in oracle', 'description': 'Mandatory Background Processes in Oracle Database, Optional Background Processes in Oracle 10g and Oracle 11g', 'url': 'https://satya-dba.blogspot.com/2009/08/background-processes-in-oracle.html', 'type': 'item', 'isSingleItem': true, 'isMultipleItems': false, 'isError': false, 'isPage': false, 'isPost': true, 'isHomepage': false, 'isArchive': false, 'isLabelSearch': false, 'postId': 6323685730910210915}}\]); \_WidgetManager.\_RegisterWidget('\_NavbarView', new \_WidgetInfo('Navbar1', 'navbar', document.getElementById('Navbar1'), {}, 'displayModeFull')); \_WidgetManager.\_RegisterWidget('\_HeaderView', new \_WidgetInfo('Header1', 'header', document.getElementById('Header1'), {}, 'displayModeFull')); \_WidgetManager.\_RegisterWidget('\_BlogView', new \_WidgetInfo('Blog1', 'main', document.getElementById('Blog1'), {'cmtInteractionsEnabled': false, 'lightboxEnabled': true, 'lightboxModuleUrl': 'https://www.blogger.com/static/v1/jsbin/155092491-lbx.js', 'lightboxCssUrl': 'https://www.blogger.com/static/v1/v-css/123180807-lightbox\_bundle.css'}, 'displayModeFull')); \_WidgetManager.\_RegisterWidget('\_HTMLView', new \_WidgetInfo('HTML8', 'main', document.getElementById('HTML8'), {}, 'displayModeFull')); \_WidgetManager.\_RegisterWidget('\_LinkListView', new \_WidgetInfo('LinkList1', 'main', document.getElementById('LinkList1'), {}, 'displayModeFull')); \_WidgetManager.\_RegisterWidget('\_LinkListView', new \_WidgetInfo('LinkList3', 'main', document.getElementById('LinkList3'), {}, 'displayModeFull')); \_WidgetManager.\_RegisterWidget('\_LinkListView', new \_WidgetInfo('LinkList2', 'main', document.getElementById('LinkList2'), {}, 'displayModeFull')); \_WidgetManager.\_RegisterWidget('\_TranslateView', new \_WidgetInfo('Translate1', 'sidebar-right-1', document.getElementById('Translate1'), {}, 'displayModeFull')); \_WidgetManager.\_RegisterWidget('\_LinkListView', new \_WidgetInfo('LinkList4', 'sidebar-right-1', document.getElementById('LinkList4'), {}, 'displayModeFull')); \_WidgetManager.\_RegisterWidget('\_HTMLView', new \_WidgetInfo('HTML7', 'sidebar-right-1', document.getElementById('HTML7'), {}, 'displayModeFull')); \_WidgetManager.\_RegisterWidget('\_LinkListView', new \_WidgetInfo('LinkList7', 'sidebar-right-1', document.getElementById('LinkList7'), {}, 'displayModeFull')); \_WidgetManager.\_RegisterWidget('\_HTMLView', new \_WidgetInfo('HTML1', 'sidebar-right-1', document.getElementById('HTML1'), {}, 'displayModeFull')); \_WidgetManager.\_RegisterWidget('\_LinkListView', new \_WidgetInfo('LinkList8', 'sidebar-right-1', document.getElementById('LinkList8'), {}, 'displayModeFull')); \_WidgetManager.\_RegisterWidget('\_FollowersView', new \_WidgetInfo('Followers2', 'sidebar-right-1', document.getElementById('Followers2'), {}, 'displayModeFull')); \_WidgetManager.\_RegisterWidget('\_PopularPostsView', new \_WidgetInfo('PopularPosts1', 'sidebar-right-1', document.getElementById('PopularPosts1'), {}, 'displayModeFull')); \_WidgetManager.\_RegisterWidget('\_LinkListView', new \_WidgetInfo('LinkList6', 'footer-1', document.getElementById('LinkList6'), {}, 'displayModeFull')); \_WidgetManager.\_RegisterWidget('\_LinkListView', new \_WidgetInfo('LinkList5', 'footer-1', document.getElementById('LinkList5'), {}, 'displayModeFull')); \_WidgetManager.\_RegisterWidget('\_LabelView', new \_WidgetInfo('Label1', 'footer-1', document.getElementById('Label1'), {}, 'displayModeFull')); \_WidgetManager.\_RegisterWidget('\_AttributionView', new \_WidgetInfo('Attribution1', 'footer-3', document.getElementById('Attribution1'), {}, 'displayModeFull')); \_WidgetManager.\_RegisterWidget('\_HTMLView', new \_WidgetInfo('HTML9', 'footer-3', document.getElementById('HTML9'), {}, 'displayModeFull'));
