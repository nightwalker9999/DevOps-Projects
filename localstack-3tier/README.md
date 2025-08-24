# LocalStack 3-Tier (Messaging-first) — Terraform + Docker Compose

A compact, interview-ready project that runs **AWS-like services locally** with **LocalStack** and **Terraform**, plus a **Docker Compose** app stack.

- **Infra (Terraform → LocalStack):** S3 (state + artifacts + logs), DynamoDB (state lock), SQS (with DLQ), SNS (topic), CloudWatch Logs (log group).
- **App (Docker Compose):** `app` (Flask HTTP API that publishes to SNS) → SNS → SQS → `worker` (Python consumer) + `nginx` reverse proxy.

> Goal: practice IaC, state/locking, messaging patterns, and CI-friendly local dev without cloud costs.

---

## Repo layout

<img width="530" height="476" alt="image" src="https://github.com/user-attachments/assets/c92ba58d-bd8e-46d6-a766-c2f1665be6cc" />

---

## Prereqs

- Docker & Docker Compose  
- Python 3 (for LocalStack CLI)  
- Terraform ≥ 1.5  
- LocalStack CLI & AWS CLI shim:
  ```bash
  pipx install localstack awscli-local \
    || pip install --user localstack awscli-local

---

## Quick start

1) Start LocalStack & set env

		localstack start -d

		export AWS_ACCESS_KEY_ID=test
		export AWS_SECRET_ACCESS_KEY=test
		export AWS_DEFAULT_REGION=us-east-1
		export AWS_ENDPOINT_URL=http://localhost:4566

2) Bootstrap Terraform backend (S3 state + DDB lock)

		./scripts/bootstrap_state_localstack.sh

		This creates:
			•	S3 bucket tfstate-arjun (state) with versioning
			•	DynamoDB table tfstate-locks (state locking)

3) Terraform (dev)

		# from repo root (localstack-3tier/)
		make init                 # runs 'terraform init' in infra/envs/dev
		make plan ENV=dev
		make apply ENV=dev

#### Outputs you should see:
		•	artifacts_bucket = "arjun-artifacts"
		•	logs_bucket = "arjun-logs"
		•	queue_url = http://.../arjun-main-queue
		•	dlq_url = http://.../arjun-main-queue-dlq
		•	sns_topic_arn = arn:aws:sns:us-east-1:000000000000:arjun_notify

4) Verify (optional)

		awslocal s3 ls
		awslocal sqs list-queues
		TOPIC_ARN=$(terraform -chdir=infra/envs/dev output -raw sns_topic_arn)
		awslocal sns publish --topic-arn "$TOPIC_ARN" --message 'hello-from-localstack'
		QURL=$(awslocal sqs get-queue-url --queue-name arjun-main-queue --query QueueUrl --output text)
		awslocal sqs receive-message --queue-url "$QURL" --wait-time-seconds 2


---

## Compose stack (app + worker + nginx)

Compose uses host networking so containers can reach LocalStack via http://127.0.0.1:4566. If you’re on non-Linux Docker, swap to a user-defined network and address the LocalStack container by name.


1) Generate compose/.env from Terraform outputs

		make compose-env
		# writes compose/.env with SNS_TOPIC_ARN and QUEUE_URL, plus AWS_* vars

2) Up / test / down

		make compose-up

		# health of app through nginx (port 8080)
		curl -s http://localhost:8080/health

		# publish -> SNS -> SQS -> worker
		curl -s -X POST http://localhost:8080/notify \
		-H 'Content-Type: application/json' \
		-d '{"message":"ping-$(date +%H:%M:%S)"}'

		# tail worker logs (should print 'got: ...')
		docker compose -f compose/docker-compose.yml logs -f worker

		# when done
		make compose-down


---

## Make targets

### Terraform
		fmt             # terraform fmt -recursive
		init            # terraform init in envs/$(ENV)  (bootstrap wired)
		plan            # terraform plan
		apply           # terraform apply
		destroy         # terraform destroy

		# Helpers
		test-sns        # publish to SNS and read one message from SQS

		# Compose
		compose-env     # generate compose/.env from TF outputs
		compose-up      # docker compose up -d --build
		compose-down    # docker compose down


⸻

### Key concepts (plain English)
			•	ARN: unique ID for an AWS resource, used in permissions/subscriptions.
			•	SNS Topic: publish messages once → SNS fans out to subscribers.
			•	SQS Queue: durable mailbox; consumers poll and process.
			•	Subscription: connects a topic to a destination (here: SQS with protocol sqs).
			•	Queue policy: allows sns.amazonaws.com to SendMessage to your queue, restricted to your topic ARN.
			•	Terraform state backend: S3 stores TF’s memory of what exists; DynamoDB provides a lock so applies don’t collide.

⸻

### Implementation notes
			•	Provider endpoints: versions.tf points AWS services to http://localhost:4566 (LocalStack).
			•	Backend: backend.tf uses S3 (LocalStack) with endpoint + force_path_style for compatibility on older Terraform installs (you may see deprecation warnings; safe to ignore here).
			•	Buckets: arjun-artifacts (for build artifacts), arjun-logs (for app logs/exports if needed).
			•	Messaging path: HTTP POST /notify → app publishes to arjun_notify → subscription forwards to arjun-main-queue → worker polls & prints.

⸻

### Troubleshooting
	•	“S3 bucket tfstate-arjun does not exist”

LocalStack restarted. Re-run:

		./scripts/bootstrap_state_localstack.sh
		make init


“endpoints/endpoints.s3 not expected”

		Your Terraform version expects older backend args. Keep backend.tf with endpoint + force_path_style.

Worker says “no messages”.
Send a new message; the worker polls every few seconds:

		curl -s -X POST http://localhost:8080/notify \
		-H 'Content-Type: application/json' \
		-d '{"message":"hello"}'


GitHub rejects push (>100 MB)
		You committed .terraform/. Fix with:

		# in submodule repo
		echo '**/.terraform/' >> .gitignore
		python3 -m git_filter_repo --force \
		--path-glob '**/.terraform/**' --path-glob '**/*.tfplan' --invert-paths
		python3 -m git_filter_repo --force --strip-blobs-bigger-than 100M
		git remote add origin <your-fork-url>  # filter-repo removes origin
		git push -f origin <branch>


---

# Daily log (append here)

## 2025-08-09 — Day 1
	•	Brought up LocalStack (localstack start -d) and env exports.
	•	Bootstrapped TF backend: S3 tfstate-arjun + DDB tfstate-locks.
	•	Added modules + root wiring:
	•	S3 buckets: arjun-artifacts, arjun-logs (versioning on).
	•	SQS arjun-main-queue + DLQ.
	•	make init/plan/apply → green. Verified via awslocal s3 ls, awslocal sqs list-queues.

## 2025-08-10 — Day 2
	•	Added SNS topic arjun_notify and CloudWatch Logs group /arjun/app.
	•	Created SQS queue policy to allow SNS → SQS, and a subscription to the queue.
	•	Tested end-to-end: sns publish → sqs receive-message → message received.

## 2025-08-11 — Day 3
	•	Built Docker Compose stack:
	•	app (Flask) publishes to SNS (POST /notify),
	•	worker (Python) polls SQS and prints body,
	•	nginx reverse proxy on :8080.
	•	Verified: curl :8080/health OK; posting produces messageId; worker logs show got: ....
	•	Git hygiene: added .gitignore, rewrote history to remove .terraform/**, force-pushed cleaned branch, updated submodule pointer in parent repo.

## 2025-08-14 - Day 4 & 5
	• 	Fixed provider to use LocalStack STS; ‘InvalidClientTokenId’ resolved via endpoints + skips.
	• 	Hardened S3 modules: public-access block, SSE AES256, lifecycle (30d→STANDARD_IA, expire 365d).
	• 	Verified with awslocal: lifecycle/encryption/PAB all present.
	Commands: terraform init -reconfigure, make plan/apply, awslocal s3api get-bucket-*

## 2025-08-16 to 2025-08-19 - Day 6-8
	• Added MySQL to compose, health check added. 
	• Worker + wiring for inserting the message consumed by SQS queue to DB
	• Modified compose to start localstack container and added depends-on on MySQL for localstack.

	• TODO: Issue of localstack being there already started due to detached mode. 


## 2025-08-20 - Day 10
	• Doing Troubleshooting for fixing the MySQL Wiring issue.
	• Troubleshooting: 
		-> Why your bootstrap script failed? 
			- Service 's3' is not enabled.
			- Service 'dynamodb' is not enabled.
		
		Fix: Enable S3 and DynamoDB in compose/docker-compose.yml:

			```
			services:
				localstack:
					image: localstack/localstack:latest
					environment:
					- SERVICES=sns,sqs,logs,cloudwatch,s3,dynamodb   # <-- add s3,dynamodb
					- DEBUG=1
					- DOCKER_HOST=unix:///var/run/docker.sock
					# (healthcheck can stay as-is)
			```

			Then recreate LocalStack:

			```
				# To Start localstack service using compose

				docker compose -f ./compose/docker-compose.yml up -d --build --force-recreate localstack

				# wait a few seconds, then confirm S3 & DynamoDB show "available
				docker compose -f ./compose/docker-compose.yml exec localstack \
				sh -lc 'curl -s http://localhost:4566/_localstack/health | grep -E "\"(sns|sqs|s3|dynamodb)\": \"available\""'
			```

			Re-run the bootstrap script:

			```
				./scripts/bootstrap_state_localstack.sh
			```

## 2025-08-24 - Day 13
### Fix the healthcheck (remove the $H warnings)

```
healthcheck:
	test: ["CMD-SHELL", "set -e; H=$(curl -sf http://localhost:4566/_localstack/health); \
		echo \"$$H\" | egrep -q '\"sns\": \"(available|running)\"'; \
		echo \"$$H\" | egrep -q '\"sqs\": \"(available|running)\"'; \
		echo \"$$H\" | egrep -q '\"s3\": \"(available|running)\"'; \
		echo \"$$H\" | egrep -q '\"dynamodb\": \"(available|running)\"'"]
	interval: 5s
	timeout: 5s
	retries: 60
```

### Fix the healthcheck (remove the $H warnings)
### Fix: SNS → SQS Permission & Policy

	While wiring SNS → SQS in LocalStack, the queue initiallyrejected messages with QueueDoesNotExist or InvalidParameter.

	Root Cause:
		•	SQS queues don’t automatically trust SNS.
		•	You must attach a queue policy explicitly granting the SNS Topic permission to SendMessage.

	Steps we took:
		1.	Created SNS topic & SQS queue.

		```
			TOPIC_ARN=$(awslocal sns create-topic --name arjun_notify --query 'TopicArn' --output text)
			QUEUE_URL=$(awslocal sqs get-queue-url --queue-name arjun-main-queue --query 'QueueUrl' --output text)
			QUEUE_ARN=$(awslocal sqs get-queue-attributes --queue-url "$QUEUE_URL" --attribute-names QueueArn --query 'Attributes.QueueArn' --output text)
		```


		2.	Added queue policy (file-based to avoid CLI quoting issues):

		```
			cat > /tmp/sqs-attrs.json <<EOF
			{
			"Policy": "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Sid\":\"AllowSNSToSend\",\"Effect\":\"Allow\",\"Principal\":\"*\",\"Action\":\"sqs:SendMessage\",\"Resource\":\"$QUEUE_ARN\",\"Condition\":{\"ArnEquals\":{\"aws:SourceArn\":\"$TOPIC_ARN\"}}}]}"
			}
			EOF
			awslocal sqs set-queue-attributes --queue-url "$QUEUE_URL" --attributes file:///tmp/sqs-attrs.json

		```
		3.	Subscribed the queue to the topic:

		```
			awslocal sns subscribe \
			--topic-arn "$TOPIC_ARN" \
			--protocol sqs \
			--notification-endpoint "$QUEUE_ARN" \
			--attributes RawMessageDelivery=true
		```

		4.	Verified end-to-end:

		```
			awslocal sns publish --topic-arn "$TOPIC_ARN" --message '{"hello":"mysql"}'
			awslocal sqs receive-message --queue-url "$QUEUE_URL" --max-number-of-messages 1
		```


		✅ Result: Messages published to SNS now arrive in SQS, and the Worker container can consume them successfully.

	```

## Troubleshooting for Fixes / Common Errors

### Key gotchas we hit (and how we fixed them):

####	1. LocalStack is ephemeral
		•	When LocalStack restarts, topics/queues disappear.
		•	Fix: run the bootstrap script to recreate SNS/SQS, policy, and subscription.

#### 	2.	Race condition: worker starts before resources exist

		•	Worker spammed QueueDoesNotExist.
		•	Fix: wait for LocalStack health (sns/sqs: running) before bootstrapping or starting worker.

####	3.	Two valid queue URLs (host vs container)
		•	Host: http://localhost:4566/... (or http://sqs.us-east-1.localhost.localstack.cloud:4566/...)
		•	Container: http://localstack:4566/...
		•	Fix: In .env for containers use localstack:4566. On host, use localhost:4566.

#### 	4.	AWS CLI region/creds
		•	Missing region caused CLI to return nothing.
		•	Fix: set AWS_ACCESS_KEY_ID/SECRET/DEFAULT_REGION or bake region into the awslocal alias.

#### 	5.	Quoting JSON policies in the shell is painful
		•	Fix: write attributes to a file and pass --attributes file:///path.json.
		6.	“Recreate worker” — what it means
		•	Containers don’t “see” changes to .env or scripts until rebuilt/recreated.
		•	Fix: docker compose up -d --build --force-recreate worker.



License: MIT

Author: Arjun — learning DevOps the practical way with LocalStack + Terraform.
