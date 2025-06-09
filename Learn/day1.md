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
# HugePages in Oracle Database: Overview and Calculator

---

## What are HugePages?

**HugePages** (also called **Large Pages**) are a Linux kernel feature that allows Oracle to allocate SGA memory using larger memory pages than the default (typically 4 KB).

**Benefits:**

* Reduced page table overhead.
* Improved Translation Lookaside Buffer (TLB) efficiency.
* Reduced memory fragmentation.

**Default page size:** 4 KB
**Typical HugePage size:** 2 MB (some systems support 1 GB).

---

## 2️ Why Use HugePages in Oracle?

✅ **Better Performance**: Fewer page table entries, less CPU spent managing memory.
✅ **Non-Swappable**: Keeps the SGA resident in memory, preventing paging.
✅ **Recommended**: Especially when SGA is >4 GB or for multi-instance environments.

---

## 3️ How to Calculate HugePages?

### Manual Method:

1. **Total SGA usage** (sum of SGA\_TARGET, SGA\_MAX\_SIZE, or use `ipcs -m`).
2. **Divide by HugePage size** (usually 2 MB).

Example:

```
SGA size = 20 GB
HugePage size = 2 MB

Required HugePages = (20 * 1024) / 2 = 10240
```

### Official Oracle Calculator:

Oracle provides a Perl script in Metalink:

* **Doc ID 401749.1** — *HugePages on Linux: What It Is... and What It Is Not...*

Use the script:

```
cd $ORACLE_HOME/rdbms/admin
sqlplus / as sysdba
SQL> ! ./hugepages_settings.sh
```

---

## 4️ Quick Commands

* **Check HugePages Usage:**

  ```bash
  grep HugePages_Total /proc/meminfo
  grep Hugepagesize /proc/meminfo
  ```

* **Reserve HugePages:**
  Edit `/etc/sysctl.conf`:

  ```conf
  vm.nr_hugepages = <calculated_value>
  ```

  Then reload:

  ```bash
  sysctl -p
  ```

---

## 5️ HugePages Calculator Script

🔗 **Download from Oracle Metalink:**

[MOS Doc ID 401749.1 — HugePages on Linux: What It Is... and What It Is Not...](https://support.oracle.com/epmos/faces/DocumentDisplay?id=401749.1)

(Note: Requires Oracle Support login)

---

## 6️⃣ Summary Table

| Item                  | Description                                |
| --------------------- | ------------------------------------------ |
| Default Page Size     | 4 KB                                       |
| Typical HugePage Size | 2 MB (or 1 GB on some systems)             |
| Benefits              | Less CPU overhead, improved TLB efficiency |
| Tool                  | hugepages\_settings.sh script              |
| Oracle Doc ID         | 401749.1 (My Oracle Support)               |



* Check **granule size**: 4MB (<1GB SGA) or 16MB (>1GB SGA).

---

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


