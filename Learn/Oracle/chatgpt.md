Here are the first **50 scenario-based Oracle DBA interview questions and detailed answers**, tailored for 10+ years of experience, in **Markdown format**:

---

# Oracle DBA Interview Questions & Answers (Q1–Q50)

## 🧠 Section 1: Oracle Architecture

### 1. **Scenario:** Your database is experiencing slow performance. You suspect shared pool contention.

**Q:** How would you confirm this and what steps would you take to fix it?

**A:**
Check for high **library cache** and **row cache** latch contention via:

```sql
SELECT * FROM v$latch WHERE name IN ('library cache', 'row cache objects');
```

Then review frequently parsed SQL:

```sql
SELECT sql_text, executions FROM v$sql WHERE executions < 5 ORDER BY executions;
```

Fix:

* Use bind variables.
* Increase shared pool size.
* Pin frequently used packages.
* Use `CURSOR_SHARING=FORCE` as a workaround if literals are excessive.

---

### 2. **Scenario:** Users report “ORA-04031: unable to allocate x bytes of shared memory”.

**Q:** What causes this and how do you resolve it?

**A:**
ORA-04031 is due to shared pool or large pool fragmentation. Common causes:

* Poor bind variable usage
* Inadequate memory allocation

Steps:

* Identify using `v$shared_pool_reserved`
* Flush shared pool (temporary fix)
* Use `DBMS_SHARED_POOL` to pin large objects
* Increase memory or enable automatic memory management

---

### 3. **Scenario:** Your DB is in AMM but performance is erratic.

**Q:** When should you avoid AMM and use ASMM instead?

**A:**
Avoid AMM when:

* You're using huge pages (AMM disables huge pages)
* Inconsistent memory allocation is observed
* Memory\_target tuning is not ideal in large workloads

Use `SGA_TARGET` + `PGA_AGGREGATE_TARGET` (ASMM) for finer control in enterprise-grade systems.

---

### 4. **Q:** Explain how background processes interact in Oracle architecture.

**A:**
Key interactions:

* **DBWn** writes dirty buffers to datafiles
* **LGWR** writes redo logs
* **CKPT** updates headers during checkpoints
* **SMON** handles crash recovery
* **PMON** cleans dead sessions
* **MMON** gathers stats and AWR

---

### 5. **Q:** How does Oracle handle physical vs logical reads?

**A:**

* **Logical reads**: Data read from buffer cache
* **Physical reads**: Data read from disk

Use AWR/ASH to monitor high physical reads and tune by caching or indexing.

---

## 🛡️ Section 2: Backup & Recovery

### 6. **Scenario:** You lose a datafile in a critical tablespace.

**Q:** How do you recover it without shutting the DB down?

**A:**

```sql
ALTER DATABASE DATAFILE '/path/to/datafile.dbf' OFFLINE;
RECOVER DATAFILE '/path/to/datafile.dbf';
ALTER DATABASE DATAFILE '/path/to/datafile.dbf' ONLINE;
```

Use RMAN if backup exists:

```bash
RMAN> RESTORE DATAFILE 5;
      RECOVER DATAFILE 5;
```

---

### 7. **Q:** How would you perform an RMAN disaster recovery if all control files are lost?

**A:**

1. Restore control file from autobackup:

```bash
RMAN> RESTORE CONTROLFILE FROM AUTOBACKUP;
```

2. Mount DB:

```bash
RMAN> ALTER DATABASE MOUNT;
```

3. Restore and recover DB:

```bash
RMAN> RESTORE DATABASE;
RMAN> RECOVER DATABASE;
```

---

### 8. **Q:** What is the difference between incomplete and complete recovery?

**A:**

* **Complete**: Recover all changes using all archived logs.
* **Incomplete**: Recover up to a point-in-time or SCN, used in corruption or accidental drop cases.

---

### 9. **Q:** How would you clone a database using RMAN?

**A:**
Use `DUPLICATE TARGET DATABASE`:

```bash
RMAN> CONNECT TARGET /
RMAN> CONNECT AUXILIARY sys@newdb
RMAN> DUPLICATE TARGET DATABASE TO newdb NOFILENAMECHECK;
```

---

### 10. **Q:** Can you recover a dropped table without flashback enabled?

**A:**
If no recyclebin or flashback, restore from RMAN backup:

* Mount clone
* Export table from clone
* Import into source DB

---

## 🔧 Section 3: Patching & Upgrade

### 11. **Q:** Explain the steps for applying a PSU in a RAC environment.

**A:**

1. Download PSU
2. Run `opatchauto` or `opatch` on each node
3. Use rolling patching if downtime not allowed
4. Validate with `opatch lsinventory`

---

### 12. **Q:** How do you apply a patch without downtime?

**A:**
Use:

* **Rolling patching** in RAC
* **Dataguard switchover** if non-RAC
* Apply on standby → switchover → patch old primary

---

### 13. **Q:** What's the difference between PSU and RU?

**A:**

* **PSU**: Patch Set Update (older)
* **RU**: Release Update (newer, replaces PSU)

RU includes:

* Security + functionality fixes
* Delivered quarterly

---

### 14. **Q:** How to rollback a patch?

**A:**

```bash
$ORACLE_HOME/OPatch/opatch rollback -id <patch_id>
```

Must check:

* Inventory backup
* Dependencies

---

### 15. **Q:** During patching, the DB fails to start. What do you check?

**A:**

* Alert log
* `$ORACLE_HOME` corruption
* Patch conflict in `opatch lsinventory`
* Revert patch if necessary

---

## ⚙️ Section 4: Performance Tuning

### 16. **Q:** Query suddenly slowed down. No stats change. What do you check?

**A:**

* SQL Plan baseline changes (`DBMS_XPLAN`)
* Adaptive plans
* Bind variable peeking
* Session wait events (v\$session, ASH)

---

### 17. **Q:** What is AWR and how do you use it?

**A:**
AWR collects DB performance snapshots. Compare:

```sql
SELECT * FROM dba_hist_snapshot;
```

Generate via:

```sql
@$ORACLE_HOME/rdbms/admin/awrrpt.sql
```

---

### 18. **Q:** Difference between DB time and elapsed time?

**A:**

* **DB Time**: Time spent by all sessions in DB calls
* **Elapsed Time**: Total real-world time

---

### 19. **Q:** How would you tune a high-CPU SQL query?

**A:**

* Examine execution plan
* Check index usage
* Use SQL Monitor/AWR
* Apply hints or rewrite query

---

### 20. **Q:** Explain how you handle high I/O wait in database.

**A:**

* Identify using AWR wait events
* Check top SQLs for full scans
* Tune SQL or increase caching
* Optimize storage layer

---

## 🧩 Section 5: High Availability (RAC/DG)

### 21. **Q:** RAC node crash. How do you identify root cause?

**A:**

* Check `crsd.log`, `alert.log`, OS logs
* Use `oerr ora <code>` for error details
* Use `diagcollection.pl` to gather cluster diagnostics

---

### 22. **Q:** How to sync data between primary and standby?

**A:**
Use:

```sql
SELECT DEST_ID, GAP_STATUS FROM V$ARCHIVE_DEST_STATUS;
```

Fix gaps with:

```sql
RECOVER MANAGED STANDBY DATABASE;
```

---

### 23. **Q:** What is role of `RFS` and `MRP` in standby?

**A:**

* `RFS`: Remote File Server – receives redo
* `MRP`: Managed Recovery Process – applies redo

---

### 24. **Q:** RAC load imbalance. How do you fix?

**A:**

* Use services with preferred instances
* Monitor via GV\$ACTIVE\_SESSION\_HISTORY
* Use `Instance Caging` if needed

---

### 25. **Q:** Can I apply patch to standby and promote it?

**A:**
Yes. Steps:

1. Patch standby
2. Switchover
3. Patch old primary
4. Switchover back

---
