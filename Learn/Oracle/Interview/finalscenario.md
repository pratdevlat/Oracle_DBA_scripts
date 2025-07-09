**Q1:  Your production database is experiencing ORA-04031 errors during peak hours. The SGA is 32GB, but you're seeing "unable to allocate memory" errors in the shared pool. Walk through your diagnostic approach and resolution strategy.**

**A:** First, I'd assess the situation:
- Check `V$SGASTAT` and `V$SHARED_POOL_ADVICE` for shared pool utilization
- Query `V$SHARED_POOL_RESERVED` for reserved pool fragmentation
- Review `V$SQL` for hard parsing and cursor sharing issues

**Resolution Strategy:**
1. **Immediate fix:** Flush shared pool (`ALTER SYSTEM FLUSH SHARED_POOL`) during low-activity period
2. **Short-term:** Increase `SHARED_POOL_SIZE` incrementally (add 2-4GB)
3. **Long-term solutions:**
   - Enable `CURSOR_SHARING=SIMILAR` if literals are causing issues
   - Tune `SHARED_POOL_RESERVED_SIZE` (10-15% of shared pool)
   - Implement connection pooling to reduce session memory
   - Use `RESULT_CACHE_MODE=FORCE` for repetitive queries

**Risk Mitigation:** Test changes in non-production first, monitor `V$SHARED_POOL_ADVICE` for optimal sizing.

---

**Q2: In a 4-node RAC environment, you notice that nodes 1 and 2 can communicate with each other, and nodes 3 and 4 can communicate with each other, but the two pairs cannot communicate. What's happening and how do you resolve this?**

**A:** This is a classic network partitioning issue where we have two sub-clusters that can't communicate.

**Assessment:**
- Check cluster interconnect status: `oifcfg getif`
- Verify voting disk accessibility: `crsctl query css votedisk`
- Review cluster logs: `$GRID_HOME/log/*/alert*.log`

**Resolution:**
1. **Immediate:** Identify which partition has majority voting disks
2. **Isolate minority partition:** Stop cluster services on nodes without majority
3. **Fix network connectivity:** Work with network team to restore interconnect
4. **Restart minority nodes:** Once connectivity restored, restart cluster services

**Prevention:** Implement redundant interconnects and ensure odd number of voting disks across different storage.

---

**Q3: The SMON process keeps crashing every 30 minutes in your 19c database. What could be causing this and how would you troubleshoot it?**

**A:** SMON crashes typically indicate data corruption or resource issues.

**Diagnostic Approach:**
- Check alert log for ORA-600/ORA-7445 errors
- Review SMON trace files in `$ORACLE_BASE/diag/rdbms/*/trace/`
- Query `V$PROCESS` and `V$SESSION` for SMON status
- Check for corruption: `VALIDATE DATABASE`

**Common Causes & Solutions:**
1. **Temp tablespace corruption:** Recreate temp tablespace
2. **Dictionary corruption:** Run `VALIDATE DATABASE` and `RMAN BACKUP VALIDATE`
3. **Resource constraints:** Check disk space, file descriptors
4. **Bug-related:** Apply latest PSU/RU patches for 19c

**Immediate Action:** Enable SMON tracing: `ALTER SYSTEM SET EVENTS '10513 trace name context forever, level 2'`

---

**Q4: A batch job is running out of PGA memory and getting ORA-04030 errors. The job processes 10 million records with complex sorts and hash joins. How do you diagnose and resolve this?**

**A:** **Assessment:**
- Check `V$PGASTAT` and `V$PGA_TARGET_ADVICE`
- Review `V$SQL_WORKAREA` for sort/hash operation memory usage
- Monitor `V$PROCESS` for individual session PGA consumption

**Resolution Strategy:**
1. **Immediate:** Increase `PGA_AGGREGATE_TARGET` by 50%
2. **Session-level:** Set `WORKAREA_SIZE_POLICY=MANUAL` and increase `SORT_AREA_SIZE`/`HASH_AREA_SIZE` for the batch session
3. **Query optimization:**
   - Add appropriate indexes to reduce sort operations
   - Use `PARALLEL` hints with controlled DOP
   - Implement array processing in application

**Long-term:** Consider partitioning large tables and implementing parallel processing with multiple smaller batches.

---

**Q5: Your primary database in Mumbai and standby in Singapore have a consistent 45-minute lag during business hours. Network bandwidth is adequate. What are the potential causes and solutions?**

**A:** **Assessment:**
- Check `V$ARCHIVE_DEST_STATUS` for ASYNC/SYNC mode
- Review `V$DATAGUARD_STATS` for apply lag metrics
- Monitor network latency: `V$RECOVERY_PROGRESS`

**Potential Causes & Solutions:**
1. **Redo generation rate:** Check `V$ARCHIVE_DEST` for `REOPEN` parameter
2. **Apply process bottleneck:** Increase `PARALLEL_SERVERS_TARGET`
3. **Network optimization:** Enable compression (`COMPRESSION=ENABLE`)
4. **Standby configuration:** Use `SYNC` mode with `NET_TIMEOUT` for critical data

**Resolution:** Implement Real-Time Apply (`ALTER DATABASE RECOVER MANAGED STANDBY DATABASE USING CURRENT LOGFILE`) and tune parallel apply processes.

---

**Q6: In your 3-node RAC, node 1 is handling 70% of connections while nodes 2 and 3 are underutilized. The application uses connection pooling. How do you investigate and fix this imbalance?**

**A:** **Investigation:**
- Check `V$SESSION` distribution across instances
- Review `V$SERVICES` for service configuration
- Verify `LOAD_BALANCE=YES` in TNS entries
- Check connection pool configuration

**Root Cause Analysis:**
1. **Service configuration:** Ensure services have proper `PREFERRED` and `AVAILABLE` instances
2. **Connection string:** Verify `LOAD_BALANCE=TRUE` and `FAILOVER=TRUE`
3. **Session affinity:** Check if application is using database links or sticky sessions

**Resolution:**
- Redistribute services using `srvctl modify service`
- Implement runtime load balancing with `GOAL=THROUGHPUT`
- Use connection pooling with proper `CONNECTION_POOL_CONFIG`
- Monitor using `V$SERVICEMETRIC` for ongoing balance

---

**Q7: Your buffer cache hit ratio is 99.8%, but users are still complaining about slow performance. Explain why this metric might be misleading and what you'd investigate instead.**

**A:** **Why 99.8% hit ratio can be misleading:**
- High ratio doesn't indicate efficient I/O patterns
- May indicate inefficient queries scanning large tables
- Could mask underlying storage performance issues

**Alternative Investigations:**
1. **Wait events:** Focus on `db file sequential read`, `db file scattered read`
2. **Top SQL:** Query `V$SQL` ordered by `BUFFER_GETS` and `DISK_READS`
3. **Segment statistics:** Check `V$SEGMENT_STATISTICS` for hot objects
4. **I/O patterns:** Use `V$FILESTAT` and `V$IOSTAT_FILE`

**Better Metrics:** Buffer cache turnover rate, physical reads per execution, and wait event analysis provide more actionable insights.

---

**Q8:  You're seeing high "gc buffer busy acquire" waits in your RAC database. How do you determine if this is an interconnect issue or something else?**

**A:** **Diagnostic Approach:**
- Check `V$SYSSTAT` for global cache events
- Review `V$SYSTEM_EVENT` for interconnect-related waits
- Monitor `V$CLUSTER_INTERCONNECTS` for network statistics

**Determination Method:**
1. **True interconnect issue:** High `gc buffer busy acquire` with high `gc current block receive time`
2. **Application issue:** High `gc buffer busy acquire` with low network wait times
3. **Network diagnostics:** Use `oifcfg` and `ping` tests between nodes

**Resolution:**
- **Interconnect:** Upgrade network hardware, check MTU settings
- **Application:** Optimize SQL reducing inter-node block transfers
- **Configuration:** Tune `_GC_POLICY_TIME` and consider table partitioning

---

**Q9: The log writer process is becoming a bottleneck with high "log file sync" waits. Your redo logs are on SSD storage. What could be causing this and how do you resolve it?**

**A:** **Assessment:**
- Check `V$SYSTEM_EVENT` for `log file sync` wait times
- Review `V$LGWRIO_OUTLIER` for slow I/O operations
- Monitor `V$LOG_HISTORY` for switching frequency

**Potential Causes:**
1. **Commit frequency:** Application committing too frequently
2. **Log file size:** Undersized redo logs causing frequent switches
3. **Storage latency:** Even SSD can have performance issues
4. **Memory pressure:** Insufficient log buffer

**Resolution:**
- Increase `LOG_BUFFER` size
- Add more redo log groups/members
- Optimize application commit patterns
- Enable `COMMIT_WRITE=BATCH,NOWAIT`
- Consider larger redo log files (1-4GB)

---

**Q10: Oracle's Memory Advisor suggests increasing SGA to 64GB from current 32GB, but your server only has 48GB RAM. How do you handle this recommendation?**

**A:** **Assessment:**
- Current memory distribution: `V$MEMORY_TARGET_ADVICE`
- OS memory usage: Check available memory with `free -m`
- Application memory requirements outside Oracle

**Resolution Strategy:**
1. **Conservative approach:** Increase SGA to 40GB, leaving 8GB for OS/other processes
2. **Memory redistribution:** 
   - Reduce PGA_AGGREGATE_TARGET if over-allocated
   - Use Automatic Memory Management (AMM) with `MEMORY_TARGET=40GB`
3. **Alternative solutions:**
   - Implement result cache to reduce memory needs
   - Use compression to reduce buffer cache requirements
   - Consider In-Memory option for frequently accessed data

**Risk Mitigation:** Test memory changes during maintenance window, monitor swap usage, and prepare rollback plan.
