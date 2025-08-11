import os
from flask import Flask, request, jsonify
import boto3

app = Flask(__name__)
AWS_ENDPOINT_URL = os.environ.get("AWS_ENDPOINT_URL")
SNS_TOPIC_ARN = os.environ["SNS_TOPIC_ARN"]
region = os.environ.get("AWS_DEFAULT_REGION", "us-east-1")

sns = boto3.client("sns", region_name=region, endpoint_url=AWS_ENDPOINT_URL)

@app.get("/health")
def health():
    return {"status":"ok"}, 200

@app.post("/notify")
def notify():
    msg = request.json.get("message","hello-from-app")
    resp = sns.publish(TopicArn=SNS_TOPIC_ARN, Message=msg)
    return jsonify({"messageId": resp["MessageId"]})
    
if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8000)
