#!/bin/bash

# --- CONFIGURATION ---
DB_USER="usr"
DB_PASS="pwd"   # Use env var or wallet in production
DB_LIST_FILE="/pathto/db_list.txt"
HTML_OUTPUT="/pathto/db_uptime_report.html"
LOG_DIR="/pathto/sqlplus_debug_logs"

# --- Setup logs ---
mkdir -p "$LOG_DIR"
> "$HTML_OUTPUT"

if [ ! -f "$DB_LIST_FILE" ]; then
  echo " DB list file $DB_LIST_FILE not found. Please run validate_tns_connections.sh first."
  exit 1
fi

# --- Start HTML ---
cat <<EOF > "$HTML_OUTPUT"
<!DOCTYPE html>
<html>
<head>
    <title>Oracle Database Uptime Report</title>
    <style>
        body { font-family: Arial, sans-serif; padding: 20px; background: #f4f4f4; }
        table { border-collapse: collapse; width: 80%; margin: auto; background: #fff; box-shadow: 0 0 10px rgba(0,0,0,0.1); }
        th, td { border: 1px solid #ccc; padding: 12px; text-align: center; }
        th { background-color: #333; color: white; }
        tr:nth-child(even) { background-color: #f2f2f2; }
    </style>
</head>
<body>
    <h2 style="text-align: center;">Oracle Database Uptime Report</h2>
    <table>
        <tr>
            <th>Database Name</th>
            <th>Startup Time</th>
            <th>Uptime (Hours)</th>
            <th>Status</th>
        </tr>
EOF

# --- Loop through DB list ---
for DB_NAME in $(cat "$DB_LIST_FILE"); do
  echo " Checking $DB_NAME..."
  DEBUG_LOG="$LOG_DIR/sqlplus_debug_${DB_NAME}.log"

  OUTPUT=$(sqlplus -s "${DB_USER}/${DB_PASS}@${DB_NAME}" <<EOF 2>&1 | tee "$DEBUG_LOG"
SET HEADING OFF FEEDBACK OFF PAGESIZE 0
SELECT TO_CHAR(startup_time, 'YYYY-MM-DD HH24:MI:SS') FROM v\$instance;
EXIT;
EOF
)

  STARTUP_TIME=$(echo "$OUTPUT" | grep -Eo '[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}' | head -1)

  if [[ -z "$STARTUP_TIME" ]]; then
    echo " Could not connect to $DB_NAME → Check log: $DEBUG_LOG"
    echo "<tr><td>$DB_NAME</td><td colspan='2'>Connection failed</td><td style='color: red;'>DOWN</td></tr>" >> "$HTML_OUTPUT"
    continue
  fi

  CURRENT_TIME=$(date '+%Y-%m-%d %H:%M:%S')
  CURRENT_SEC=$(date -d "$CURRENT_TIME" +%s 2>/dev/null)
  STARTUP_SEC=$(date -d "$STARTUP_TIME" +%s 2>/dev/null)

  if [[ -z "$CURRENT_SEC" || -z "$STARTUP_SEC" ]]; then
    echo " Time conversion error for $DB_NAME"
    echo "<tr><td>$DB_NAME</td><td colspan='2'>Time conversion error</td><td style='color: orange;'>UNKNOWN</td></tr>" >> "$HTML_OUTPUT"
    continue
  fi

  UPTIME_HOURS=$(( (CURRENT_SEC - STARTUP_SEC) / 3600 ))
  echo "<tr><td>$DB_NAME</td><td>$STARTUP_TIME</td><td>$UPTIME_HOURS</td><td style='color: green;'>UP</td></tr>" >> "$HTML_OUTPUT"
done

# --- Close HTML ---
cat <<EOF >> "$HTML_OUTPUT"
    </table>
</body>
</html>
EOF

echo -e "\n HTML report generated: $HTML_OUTPUT"
echo " Debug logs saved to: $LOG_DIR"
