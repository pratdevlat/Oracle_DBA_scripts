As a Database Administrator (DBA) working with PostgreSQL (psql), there are several essential commands and practices that you should be familiar with. Here’s a list of key psql commands, along with tips for scripting, formatting output, and automation.

### Essential psql Commands

1. **Connecting to a Database**
   ```bash
   psql -U username -d database_name -h host -p port
   ```

2. **Listing Databases**
   ```sql
   \l
   ```

3. **Connecting to a Database**
   ```sql
   \c database_name
   ```

4. **Listing Tables**
   ```sql
   \dt
   ```

5. **Describing a Table**
   ```sql
   \d table_name
   ```

6. **Executing SQL Queries**
   ```sql
   SELECT * FROM table_name;
   ```

7. **Inserting Data**
   ```sql
   INSERT INTO table_name (column1, column2) VALUES (value1, value2);
   ```

8. **Updating Data**
   ```sql
   UPDATE table_name SET column1 = value1 WHERE condition;
   ```

9. **Deleting Data**
   ```sql
   DELETE FROM table_name WHERE condition;
   ```

10. **Creating a Table**
    ```sql
    CREATE TABLE table_name (
        column1 datatype,
        column2 datatype
    );
    ```

11. **Dropping a Table**
    ```sql
    DROP TABLE table_name;
    ```

12. **Creating an Index**
    ```sql
    CREATE INDEX index_name ON table_name (column_name);
    ```

13. **Backing Up a Database**
    ```bash
    pg_dump database_name > backup_file.sql
    ```

14. **Restoring a Database**
    ```bash
    psql -U username -d database_name < backup_file.sql
    ```

15. **Exiting psql**
    ```sql
    \q
    ```

### Tips for Scripting

- **Use `\g` to Execute Queries**: Instead of using a semicolon, you can use `\g` to execute the last query. This is useful in scripts.
  
- **Use `\i` to Include Files**: You can include SQL files in your scripts using:
  ```sql
  \i /path/to/script.sql
  ```

- **Use Variables**: You can define variables in psql scripts using:
  ```sql
  \set var_name value
  ```

### Formatting Output

- **Set Output Format**: You can change the output format to make it more readable:
  ```sql
  \pset format aligned
  \pset format csv
  ```

- **Set Column Width**: Adjust column width for better readability:
  ```sql
  \pset columns 80
  ```

- **Use `\x` for Expanded Output**: This is useful for wide tables:
  ```sql
  \x
  ```

### Automation

- **Use Shell Scripts**: You can automate psql commands using shell scripts. For example:
  ```bash
  #!/bin/bash
  psql -U username -d database_name -c "SELECT * FROM table_name;"
  ```

- **Schedule Backups with Cron**: You can schedule regular backups using cron jobs:
  ```bash
  0 2 * * * pg_dump database_name > /path/to/backup/backup_$(date +\%Y\%m\%d).sql
  ```

- **Log Output**: Redirect output to a log file for auditing:
  ```bash
  psql -U username -d database_name -f script.sql > output.log 2>&1
  ```

By mastering these commands and practices, you can effectively manage PostgreSQL databases and automate routine tasks, enhancing your efficiency as a DBA. ### Additional psql Commands

16. **Viewing Current Connections**
    ```sql
    SELECT * FROM pg_stat_activity;
    ```

17. **Checking Disk Usage**
    ```sql
    \l+  -- Lists databases with size information
    ```

18. **Viewing Table Size**
    ```sql
    SELECT pg_size_pretty(pg_total_relation_size('table_name'));
    ```

19. **Creating a View**
    ```sql
    CREATE VIEW view_name AS SELECT column1, column2 FROM table_name WHERE condition;
    ```

20. **Dropping a View**
    ```sql
    DROP VIEW view_name;
    ```

### Advanced Scripting Tips

- **Use Conditional Logic**: You can use `DO` blocks for conditional execution:
  ```sql
  DO $$
  BEGIN
      IF EXISTS (SELECT 1 FROM table_name WHERE condition) THEN
          -- Your SQL commands here
      END IF;
  END $$;
  ```

- **Transaction Control**: Use transactions to ensure data integrity:
  ```sql
  BEGIN;
  -- Your SQL commands here
  COMMIT;
  ```

### Output Formatting Enhancements

- **Customizing Column Headers**: You can rename column headers in your output:
  ```sql
  SELECT column1 AS "New Header" FROM table_name;
  ```

- **Using `\pset` for Borders**: Add borders to your output for better visibility:
  ```sql
  \pset border 2
  ```

### Further Automation Techniques

- **Using Environment Variables**: Store sensitive information like passwords in environment variables to avoid hardcoding:
  ```bash
  export PGPASSWORD='your_password'
  ```

- **Using `psql` with `-f` for Batch Processing**: Execute multiple SQL commands from a file:
  ```bash
  psql -U username -d database_name -f /path/to/script.sql
  ```

- **Monitoring with Scripts**: Create scripts to monitor database performance and send alerts:
  ```bash
  #!/bin/bash
  if [ $(psql -U username -d database_name -t -c "SELECT COUNT(*) FROM table_name WHERE condition;") -gt 100 ]; then
      echo "Alert: Condition met!" | mail -s "Database Alert" your_email@example.com
  fi
  ```

By incorporating these additional commands and techniques, you can further enhance your PostgreSQL management skills and streamline your database operations.