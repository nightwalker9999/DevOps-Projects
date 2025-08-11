awesome—here’s a drop-in README.md you can paste at DevOps-Projects/localstack-3tier/README.md. I included dates for what we completed so far and a simple daily log template you can append to each day.

⸻

LocalStack 3-Tier (Messaging-first) — Terraform + Docker Compose

A compact, interview-ready project that runs AWS-like services locally with LocalStack and Terraform, plus a Docker Compose app stack:
	•	Infra (Terraform → LocalStack): S3 (state + artifacts + logs), DynamoDB (state lock), SQS (with DLQ), SNS (topic), CloudWatch Logs (log group).
	•	App (Docker Compose): app (Flask HTTP API that publishes to SNS) → SNS → SQS → worker (Python consumer) + nginx reverse proxy.

Goal: practice IaC, state/locking, messaging patterns, and CI-friendly local dev without cloud costs.

⸻

Repo layout

localstack-3tier/
├─ infra/
│  ├─ modules/
│  │  ├─ s3_bucket/           # versioned S3 bucket
│  │  ├─ sqs_queue/           # SQS + DLQ
│  │  ├─ sns_topic/           # SNS topic
│  │  └─ cw_log_group/        # CloudWatch log group
│  └─ envs/dev/
│     ├─ main.tf              # root wiring of modules
│     ├─ variables.tf
│     ├─ outputs.tf
│     ├─ versions.tf          # AWS provider + LocalStack endpoints
│     └─ backend.tf           # S3 backend (LocalStack) + DDB lock
├─ compose/
│  ├─ docker-compose.yml
│  ├─ .env                    # generated from TF outputs
│  ├─ app/{Dockerfile,app.py}
│  ├─ worker/{Dockerfile,worker.py}
│  └─ nginx/nginx.conf
├─ scripts/
│  └─ bootstrap_state_localstack.sh
└─ Makefile


⸻

Prereqs
	•	Docker & Docker Compose
	•	Python 3 (for LocalStack CLI install)
	•	Terraform ≥ 1.5
	•	LocalStack CLI & AWS CLI shim:

pipx install localstack awscli-local || pip install --user localstack awscli-local



⸻

Quick start

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

Outputs you should see:
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


⸻

Compose stack (app + worker + nginx)

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


⸻

Make targets

# Terraform
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

Key concepts (plain English)
	•	ARN: unique ID for an AWS resource, used in permissions/subscriptions.
	•	SNS Topic: publish messages once → SNS fans out to subscribers.
	•	SQS Queue: durable mailbox; consumers poll and process.
	•	Subscription: connects a topic to a destination (here: SQS with protocol sqs).
	•	Queue policy: allows sns.amazonaws.com to SendMessage to your queue, restricted to your topic ARN.
	•	Terraform state backend: S3 stores TF’s memory of what exists; DynamoDB provides a lock so applies don’t collide.

⸻

Implementation notes
	•	Provider endpoints: versions.tf points AWS services to http://localhost:4566 (LocalStack).
	•	Backend: backend.tf uses S3 (LocalStack) with endpoint + force_path_style for compatibility on older Terraform installs (you may see deprecation warnings; safe to ignore here).
	•	Buckets: arjun-artifacts (for build artifacts), arjun-logs (for app logs/exports if needed).
	•	Messaging path: HTTP POST /notify → app publishes to arjun_notify → subscription forwards to arjun-main-queue → worker polls & prints.

⸻

Troubleshooting
	•	“S3 bucket tfstate-arjun does not exist”
LocalStack restarted. Re-run:

./scripts/bootstrap_state_localstack.sh
make init


	•	“endpoints/endpoints.s3 not expected”
Your Terraform version expects older backend args. Keep backend.tf with endpoint + force_path_style.
	•	Worker says “no messages”
Send a new message; the worker polls every few seconds:

curl -s -X POST http://localhost:8080/notify \
  -H 'Content-Type: application/json' \
  -d '{"message":"hello"}'


	•	GitHub rejects push (>100 MB)
You committed .terraform/. Fix with:

# in submodule repo
echo '**/.terraform/' >> .gitignore
python3 -m git_filter_repo --force \
  --path-glob '**/.terraform/**' --path-glob '**/*.tfplan' --invert-paths
python3 -m git_filter_repo --force --strip-blobs-bigger-than 100M
git remote add origin <your-fork-url>  # filter-repo removes origin
git push -f origin <branch>


⸻

Daily log (append here)

2025-08-09 — Day 1
	•	Brought up LocalStack (localstack start -d) and env exports.
	•	Bootstrapped TF backend: S3 tfstate-arjun + DDB tfstate-locks.
	•	Added modules + root wiring:
	•	S3 buckets: arjun-artifacts, arjun-logs (versioning on).
	•	SQS arjun-main-queue + DLQ.
	•	make init/plan/apply → green. Verified via awslocal s3 ls, awslocal sqs list-queues.

2025-08-10 — Day 2
	•	Added SNS topic arjun_notify and CloudWatch Logs group /arjun/app.
	•	Created SQS queue policy to allow SNS → SQS, and a subscription to the queue.
	•	Tested end-to-end: sns publish → sqs receive-message → message received.

2025-08-11 — Day 3
	•	Built Docker Compose stack:
	•	app (Flask) publishes to SNS (POST /notify),
	•	worker (Python) polls SQS and prints body,
	•	nginx reverse proxy on :8080.
	•	Verified: curl :8080/health OK; posting produces messageId; worker logs show got: ....
	•	Git hygiene: added .gitignore, rewrote history to remove .terraform/**, force-pushed cleaned branch, updated submodule pointer in parent repo.

Template for tomorrow:
YYYY-MM-DD — Day N
	•	What infra/app change shipped
	•	One pitfall + fix
	•	One command you used and why

⸻

What’s next
	•	Add MySQL service to Compose, seed script, and a small route to write/read to DB.
	•	Optionally push artifacts to S3 and have the app pull them at startup.
	•	Add a CI pipeline (Jenkins/GitHub Actions): fmt/validate/plan on PR, apply on main, plus a simple policy gate.

⸻

License: MIT (or your choice)

Author: Arjun — learning DevOps the practical way with LocalStack + Terraform.