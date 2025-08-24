# worker/db.py
import os
import time
import pymysql
from contextlib import contextmanager

def connect_with_retry(max_retries=10, delay=2):
    host = os.getenv("DB_HOST", "mysql")           # use the service name in compose
    port = int(os.getenv("DB_PORT", "3306"))       # must be int
    user = os.getenv("DB_USER", "app")
    password = os.getenv("DB_PASS", "app")
    db = os.getenv("DB_NAME", "appdb")
    for i in range(1, max_retries + 1):
        try:
            return pymysql.connect(
                host=host,
                port=port,
                user=user,
                password=password,
                database=db,
                autocommit=True,
                cursorclass=pymysql.cursors.DictCursor,  # so fetchone() returns dict
            )
        except Exception as e:
            print(f"[db] connect attempt {i}/{max_retries} failed: {e}", flush=True)
            time.sleep(delay)
    raise Exception("MySQL not reachable after retries")

@contextmanager
def get_conn():
    conn = connect_with_retry()
    try:
        yield conn
    finally:
        conn.close()

def ensure_schema():
    with get_conn() as conn, conn.cursor() as cur:
        cur.execute(
            """
            CREATE TABLE IF NOT EXISTS messages (
              id BIGINT PRIMARY KEY AUTO_INCREMENT,
              body TEXT NOT NULL,
              created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
            """
        )

def insert_message(body: str) -> int:
    with get_conn() as conn, conn.cursor() as cur:
        cur.execute("INSERT INTO messages (body) VALUES (%s)", (body,))
        cur.execute("SELECT COUNT(*) AS cnt FROM messages")
        row = cur.fetchone()
        return int(row["cnt"])