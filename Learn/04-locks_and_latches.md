Here’s the English translation of your document:

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
**INSERT, UPDATE, DELETE, MERGE, SELECT FOR UPDATE.**  
For SELECT FOR UPDATE, adding a **NOWAIT** clause prevents blocking.

- **Blocked INSERT:** Occurs when two sessions attempt to insert the same value into a table with a unique constraint or primary key. The second session waits until the first session commits or rolls back.  
- **Blocked MERGE, UPDATE, DELETE:** If an interactive application fetches data, lets users modify it, and then updates the database, blocked updates/deletes might indicate a lost update issue. **SELECT FOR UPDATE NOWAIT** helps avoid this by verifying that data hasn’t been modified and locking the row.  

### Deadlocks

A **deadlock** happens when two sessions each hold a resource the other needs, preventing both from proceeding.

### Lock Escalation

Lock escalation occurs when a system increases the granularity of a lock—for example, converting 100 row locks into a single table-level lock. This can restrict access to more data than intended.

**Oracle does not perform lock escalation**, but it supports **lock conversion** and **lock promotion** to dynamically adjust lock levels as needed.

## Types of Locks in Oracle

Oracle uses three main types of locks:

- **DML Locks:** Ensure safe concurrent modifications to data, such as row-level locks or table locks.  
- **DDL Locks:** Protect object definitions from concurrent modifications.  
- **Internal Locks and Latches:** Manage Oracle’s internal data structures.

### DML Locks

These locks prevent data loss and ensure transactions remain consistent.

#### TX Locks

A **TX (transaction) lock** is acquired when the first modification occurs within a transaction. This lock exists until a **COMMIT** or **ROLLBACK** happens.

TX locks are managed efficiently—rather than using a traditional lock manager, Oracle stores locks within data blocks themselves.

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

Let me know if you need any refinements or additional explanations!
