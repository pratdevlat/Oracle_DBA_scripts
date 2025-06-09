# Transactions

Transactions are one of the characteristics that distinguish databases from file systems. A transaction changes a database from one consistent state to another, which is the purpose of designing transactions. When a transaction is committed, the database ensures that either all modifications are saved or none are saved. In addition, the database also guarantees that committed transactions comply with various rules and checks that protect data integrity.

Transactions in Oracle embody the ACID properties:
- Atomicity: All actions in a transaction either occur completely or do not occur at all.
- Consistency: A transaction transforms the database from one consistent state to the next consistent state.
- Isolation: The effects of one transaction are not visible to other transactions until that transaction commits.
- Durability: Once a transaction is committed, its results are permanent.

## Transaction Control Statements

- COMMIT: Ends a transaction and makes all modifications made persistent in the database.
- ROLLBACK: Ends a transaction and undoes the changes made by that transaction.
- SAVEPOINT: Creates a marked point within a transaction; a transaction can have multiple SAVEPOINTs.
- ROLLBACK TO <SAVEPOINT>: Rolls back the transaction to the specified marked point, but it does not roll back work done before this marked point.
- SET TRANSACTION: Sets different transaction attributes, such as the transaction's isolation level and whether the transaction is read-only or read-write.
