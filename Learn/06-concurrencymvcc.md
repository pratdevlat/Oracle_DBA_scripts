

# Concurrency and Multi-Version Control

## What is Concurrency Control?

Concurrency control refers to the set of mechanisms in a database that allow multiple users to access and modify data simultaneously. **Locks** are a core feature that Oracle uses to manage concurrent access to shared resources and prevent interference between database transactions.

Oracle employs several types of locks, summarized below:
- **TX (Transaction) Locks:** These are acquired when a transaction modifies data.  
- **TM (DML Queue) Locks and DDL Locks:** TM locks protect objects from structural changes during modifications, while DDL locks safeguard object definitions.  
- **Latches and Mutexes:** These are internal Oracle locks that regulate access to shared data structures.  

Oracle does not just rely on efficient locking mechanisms—it also implements a **multi-version control architecture**, enabling controlled yet highly concurrent data access. Multi-version control allows Oracle to materialize multiple versions of data simultaneously, ensuring **consistent reads**.

By default, Oracle's multi-version read consistency is **statement-level**, but it can be adjusted to **transaction-level** if needed.

## Transaction Isolation Levels

The ANSI/ISO SQL standard defines **four transaction isolation levels**, each yielding different results for the same transaction. That means two identical transactions with the same inputs may produce entirely different outcomes based on isolation levels.

Isolation levels are categorized based on the following **three phenomena** that they allow or prevent:
- **Dirty Reads:** Reads uncommitted data, leading to potential data integrity issues.  
- **Nonrepeatable Reads:** If a row is read at time T1 and then read again at T2, its contents may have changed or even disappeared.  
- **Phantom Reads:** If a query is executed at T1 and re-run at T2, new rows may appear in the results due to additional insertions.  

The following table illustrates how each isolation level handles these phenomena:

| Isolation Level      | Dirty Read | Nonrepeatable Read | Phantom Read |
|---------------------|-----------|--------------------|-------------|
| READ UNCOMMITTED   | Allowed   | Allowed           | Allowed     |
| READ COMMITTED     | -         | Allowed           | Allowed     |
| REPEATABLE READ    | -         | -                 | Allowed     |
| SERIALIZABLE       | -         | -                 | -           |

Oracle **explicitly supports** the **READ COMMITTED** and **SERIALIZABLE** isolation levels.

Oracle **does not** use dirty reads—it completely **prevents** them.

## Read Consistency

Oracle utilizes **undo records** to enable **non-blocking queries** while maintaining read consistency. When executing a query, Oracle retrieves data blocks from the buffer cache and ensures that the block versions are sufficiently **"old"** to maintain the correct visibility for the query.

## Write Consistency

Old versions of a block **cannot be modified**. Any row update must alter the **current version** of the block.

Oracle performs **two types of reads** during modification:
1. **Consistent Read:** Identifies rows to modify.  
2. **Current Read:** Acquires the latest data block for actual modification.  

If an `UPDATE` statement targets rows with `Y=5`, but during execution, one of those rows has changed to `Y=10`, Oracle will **internally roll back** the update and retry it.

- Under **READ COMMITTED**, Oracle silently retries the transaction without user intervention.  
- Under **SERIALIZABLE**, Oracle raises an **ORA-08177: can't serialize access for this transaction** error instead of retrying.  

In **READ COMMITTED** mode, if an update conflict occurs, Oracle **resets the transaction's starting point**, acquiring row locks through `SELECT FOR UPDATE`, and only **after all locks are acquired**, executes the update.

---

Let me know if you need any refinements or additional explanations!
