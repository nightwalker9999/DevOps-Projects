# worker/main.py
from db import ensure_schema, insert_message

def handle_message(msg_body: str):
    ensure_schema()
    total = insert_message(msg_body)
    print(f"[worker] Inserted 1 row into MySQL. Total rows now: {total}", flush=True)