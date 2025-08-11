import os, time, json, sys, traceback
import boto3

endpoint = os.environ.get("AWS_ENDPOINT_URL")
region = os.environ.get("AWS_DEFAULT_REGION","us-east-1")
queue_url = os.environ.get("QUEUE_URL")

print(f"[worker] start endpoint={endpoint} region={region} queue_url={queue_url}", flush=True)

try:
    sqs = boto3.client("sqs", region_name=region, endpoint_url=endpoint)
except Exception as e:
    print("[worker] boto3 client error:", e, flush=True)
    sys.exit(1)

while True:
    try:
        msgs = sqs.receive_message(QueueUrl=queue_url, MaxNumberOfMessages=5, WaitTimeSeconds=5).get("Messages",[])
        if not msgs:
            print("[worker] no messages", flush=True)
        for m in msgs:
            print("[worker] got:", m.get("Body"), flush=True)
            sqs.delete_message(QueueUrl=queue_url, ReceiptHandle=m["ReceiptHandle"])
    except Exception as e:
        print("[worker] loop error:", e, flush=True)
        traceback.print_exc()
    time.sleep(1)
