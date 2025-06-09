# Oracle Database 19c Technical Architecture

© 2019, Oracle and/or its affiliates. All rights reserved.

> This software and related documentation are provided under a license agreement containing restrictions on use and disclosure and are protected by intellectual property laws.

---

## Database Server

- **Database Server**
  - **Client Application** (client process)
  - **Connect Packet Listener**
  - **Database Instance** (memory and processes)
  - **Server Process**
  - **Database**
    - **Data Files**
    - **System Files**

> An Oracle Database consists of at least one database instance and one database.  
> - **Single-instance architecture**: One instance and one database.  
> - **Oracle RAC architecture**: Multiple instances share one database.

---

## Database Instance

- **SGA (System Global Area)**
  - Shared Pool
  - Database Buffer Cache
  - Large Pool
  - Java Pool
  - Streams Pool
  - Flashback Buffer
  - Redo Log Buffer
  - Database Smart Flash Cache
  - Memoptimize Pool
  - Shared I/O Pool
- **PGA (Program Global Area)**
  - User Global Area (UGA)
  - Private SQL Area
  - Session Memory
  - Hash Area
  - Bitmap Merge Area

> The **SGA** contains shared memory structures, while the **PGA** contains process-private memory areas.

---

## Background Processes

- **Mandatory Processes**: PMON, SMON, DBWn, CKPT, LGWR, MMON, etc.
- **Optional Processes**: ARCn, CJQ0, RVWR, FBDA, etc.
- **Slave Processes**: Dnnn, Snnn, etc.

> Each background process performs specific maintenance tasks.

[Detailed information on background processes](http://www.oracle.com/pls/topic/lookup?ctx=db18&id=REFRN104)

---

## Shared Pool

- Library Cache
- Reserved Pool
- Data Dictionary Cache
- Server Result Cache
- PL/SQL Function Result Cache

> The shared pool is crucial for parsing and caching shared SQL and PL/SQL code.

---

## Large Pool

- Supports shared server processes
- Memory allocations for UGA, I/O buffers, etc.
- Deferred Inserts Pool for **MEMOPTIMIZE FOR WRITE** feature

---

## Database Buffer Cache

- **Default pool** (8KB)
- **Keep pool**
- **Recycle pool**
- **Flash Cache**
- **LRU** (Least Recently Used) algorithm

> Stores copies of data blocks read from data files to optimize I/O.

---

## In-Memory Area

- IM Column Store (IMCU, IMEU)
- Metadata pool
- Expression Statistics Store (ESS)

> Optimized for analytic queries and high-performance OLTP workloads.

---

## Database Data Files

- **Container Database (CDB)**:
  - Root Container (CDB$ROOT)
  - Seed PDB (PDB$SEED)
  - Regular PDBs

- **Tablespaces**:
  - SYSTEM, SYSAUX, USERS, TEMP, UNDO

---

## Database System Files

- Control Files
- Parameter File (pfile/spfile)
- Online Redo Log Files
- ADR (Automatic Diagnostic Repository)
- Backup Files
- Archive Redo Log Files
- Password File
- Wallets
- Block Change Tracking File
- Flashback Logs

---

## Application Containers

- **Application Root**
- **Application PDBs**
- **Application Seed**

---

## Automatic Diagnostic Repository (ADR)

- Alert Log
- Trace Files
- Dump Files
- Health Monitor Reports
- Incident Packages

---

## Backup Files

- **Physical backups**: RMAN, OS utilities
- **Logical backups**: Data Pump Export

> RMAN supports image copies and backup sets, including advanced features.

---

## Key Background Processes

- **PMON**: Cleans up after failed processes.
- **PMAN**: Manages processes like dispatcher, job queues.
- **LREG**: Registers services with listeners.
- **SMON**: Performs recovery and cleanup.
- **DBWn**: Writes buffers to disk.
- **CKPT**: Coordinates checkpoints.
- **RECO**: Resolves distributed transactions.
- **LGWR**: Writes redo logs.
- **ARCn**: Archives redo logs.
- **CJQ0**: Manages job queues.
- **RVWR**: Manages flashback logs.

---

For detailed information, refer to Oracle Database documentation:

- [Database Concepts](http://www.oracle.com/pls/topic/lookup?ctx=db18&id=CNCPT005)
- [Oracle Database In-Memory](http://www.oracle.com/pls/topic/lookup?ctx=db18&id=GUID-BFA53515-7643-41E5-A296-654AB4A9F9E7)
- [Physical Storage Structures](http://www.oracle.com/pls/topic/lookup?ctx=db18&id=CNCPT003)
- [Background Processes](http://www.oracle.com/pls/topic/lookup?ctx=db18&id=REFRN104)

---

