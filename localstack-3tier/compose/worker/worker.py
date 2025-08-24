# worker/worker.py
import os, time, json, sys, traceback
import boto3
from main import handle_message

endpoint = os.environ.get("AWS_ENDPOINT_URL")
region = os.environ.get("AWS_DEFAULT_REGION", "us-east-1")
queue_url = os.environ.get("QUEUE_URL")

print(f"[worker] start endpoint={endpoint} region={region} queue_url={queue_url}", flush=True)

try:
    sqs = boto3.client("sqs", region_name=region, endpoint_url=endpoint)
except Exception as e:
    print("[worker] boto3 client error:", e, flush=True)
    sys.exit(1)

while True:
    try:
        resp = sqs.receive_message(
            QueueUrl=queue_url,
            MaxNumberOfMessages=5,
            WaitTimeSeconds=5,         # long-poll a bit
            VisibilityTimeout=30       # avoid duplicate processing
        )
        msgs = resp.get("Messages", [])
        if not msgs:
            print("[worker] no messages", flush=True)

        for m in msgs:
            body = m.get("Body", "")
            print(f"[worker] got: {body}", flush=True)

            # If you used RawMessageDelivery=true, Body is your original payload string.
            # If not, Body is an SNS envelope JSON; you can unwrap like this:
            try:
                maybe = json.loads(body)
                if isinstance(maybe, dict) and "Message" in maybe:
                    body_to_store = maybe["Message"]
                else:
                    body_to_store = body
            except Exception:
                body_to_store = body

            # persist to DB
            handle_message(body_to_store)

            # ack
            sqs.delete_message(QueueUrl=queue_url, ReceiptHandle=m["ReceiptHandle"])

    except Exception as e:
        print("[worker] loop error:", e, flush=True)
        traceback.print_exc()
        time.sleep(2)

    time.sleep(1)