## This is python script generated to put data geneterated by databaseuptime.sh in postgres instance as datasource for grafana dashborad
import os
import platform
import psycopg2
from bs4 import BeautifulSoup
from datetime import datetime
# --- CONFIGURATION ---
HTML_PATH = "/pathto/db_uptime_report.html"
PG_HOST = "localhost"
PG_PORT = "5432"
PG_DB = "GrafanaDB"
PG_USER = "postgres"
TABLE_NAME = "db_uptime_report"
# --- Parse HTML ---
if not os.path.exists(HTML_PATH):
   raise FileNotFoundError(f"HTML file not found: {HTML_PATH}")
with open(HTML_PATH, "r") as f:
   soup = BeautifulSoup(f, "html.parser")
rows = soup.find_all("tr")[1:]  # Skip header
# --- Extract rows ---
data = []
hostname = platform.node()
os_type = platform.system()
for row in rows:
   cols = row.find_all("td")
   if len(cols) == 4:
       db_name = cols[0].text.strip()
       startup_time = cols[1].text.strip()
       uptime_hours = cols[2].text.strip()
       status = cols[3].text.strip()
       data.append((db_name, startup_time, uptime_hours, status))
# --- Connect to PostgreSQL ---
conn = psycopg2.connect(
   host=PG_HOST, port=PG_PORT, dbname=PG_DB,
   user=PG_USER,
)
cur = conn.cursor()
# --- Create table if not exists ---
cur.execute(f"""
CREATE TABLE IF NOT EXISTS {TABLE_NAME} (
   id SERIAL PRIMARY KEY,
   database_name TEXT,
   startup_time TIMESTAMP,
   uptime_hours INTEGER,
   status TEXT
);
""")
# --- Insert data ---
insert_sql = f"""
INSERT INTO {TABLE_NAME} (database_name, startup_time, uptime_hours, status)
VALUES (%s, %s, %s, %s);
"""
for row in data:
   cur.execute(insert_sql, row)
conn.commit()
cur.close()
conn.close()
print(f"Inserted {len(data)} records into {TABLE_NAME}")
