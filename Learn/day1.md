# Oracle Database Architecture: SGA, PGA, and Background Processes (In-Depth)

---

## 1. System Global Area (SGA)

The **SGA** is shared memory allocated at instance startup, containing data and control information used by all server and background processes.

### Components:

* **Database Buffer Cache**: Caches data blocks read from disk, optimizing I/O. Managed by **DBWn** background processes.
* **Redo Log Buffer**: Buffers redo entries before writing to online redo logs via **LGWR**.
* **Shared Pool**:

  * **Library Cache**: Caches parsed SQL and PL/SQL code, enables soft parsing.
  * **Data Dictionary Cache**: Holds metadata about database objects.
* **Large Pool**: Supports large allocations (RMAN, parallel execution, UGA in shared server).
* **Java Pool**: Stores Java code and data.
* **Streams Pool**: Supports Oracle Streams replication.

### Memory Management:

* **Automatic Memory Management (AMM)**: Uses `MEMORY_TARGET` to manage SGA + PGA.
* **Automatic Shared Memory Management (ASMM)**: Uses `SGA_TARGET`.
* **Manual**: Explicitly set `DB_CACHE_SIZE`, `SHARED_POOL_SIZE`, etc.

### Monitoring:

```sql
SELECT pool, name, bytes
FROM v$sgastat
WHERE pool IN ('shared pool', 'large pool', 'java pool');

SELECT pool, ROUND(bytes/1024/1024,0) AS free_mb
FROM v$sgastat
WHERE name LIKE '%free memory%';
```

### Additional Tips:

* Use **hugepages** on Linux for better performance.


## 2. Program Global Area (PGA)

The **PGA** is process-private memory allocated per session or background process.

### Components:

* **Session Memory**: Login/session state.
* **Private SQL Area**: Stores parsed SQL, bind variables.
* **SQL Work Areas**: For sorting, hash joins, bitmap merges.

### Key Parameters:

* `PGA_AGGREGATE_TARGET`: Suggests total PGA allocation.

### Monitoring:

```sql
SHOW PARAMETER pga_aggregate_target;

SELECT *
FROM v$pga_target_advice
ORDER BY pga_target_for_estimate;
```

### Best Practices:

* Keep PGA hit ratios >60% to avoid disk spills.
* DSS workloads: higher PGA, OLTP: lower.

---

## 3. Background Processes

Background processes handle I/O, memory management, recovery, and system tasks.

### Mandatory Processes:

| Process  | Description                                           |
| -------- | ----------------------------------------------------- |
| **PMON** | Cleans failed sessions, re-registers with listener    |
| **SMON** | Instance recovery, temp segment cleanup               |
| **DBWn** | Writes dirty buffers to disk                          |
| **LGWR** | Writes redo log buffer to redo logs                   |
| **CKPT** | Signals checkpoints, updates control/datafile headers |
| **ARCn** | Archives redo logs in ARCHIVELOG mode                 |
| **RECO** | Resolves distributed transactions                     |
| **LREG** | Registers services with listener                      |

### Optional Processes:

* **CJQ0**: Job queue coordinator.
* **MMON, MMNL**: Memory management monitoring.
* **FBDA**: Fast incremental backup.

### Monitoring:

```sql
SELECT p.spid, p.program
FROM v$process p
WHERE p.pname IS NOT NULL
ORDER BY p.spid;
```

---

## 4. Instance Lifecycle

* **Startup**:

  * Reads init parameters.
  * Allocates SGA.
  * Starts background processes.
  * Opens control files, datafiles, redo logs.
* **Shutdown**:

  * Flushes buffers.
  * Closes files.
  * Terminates background processes.

---

## 5. Additional Views

| View                  | Description                   |
| --------------------- | ----------------------------- |
| `v$sgastat`           | SGA allocation details        |
| `v$pga_target_advice` | PGA tuning advice             |
| `v$process`           | OS-level background processes |
| `v$session`           | Session details               |
| `v$sysstat`           | Instance statistics           |

---

## 6. Tips for Real-World Usage

* **Use AWR Reports**: Identify SGA/PGA usage trends, top SQL, wait events.
* **Consider RAC**: Adds global cache services (GCS), global enqueue services (GES).
* **Monitor Wait Events**: High CPU or waits may indicate SGA/PGA tuning needed.

---


