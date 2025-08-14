# Interview Prep Tracker (Arjun) — 4 wks focused

> Use this as your single checklist. Tick items as you ship them. Keep hands-on tied to your LocalStack 3-tier project.

- Repo: `DevOps-Projects/localstack-3tier`
- Anchors: [`infra/envs/dev`](infra/envs/dev/) · [`infra/modules`](infra/modules/) · [`compose`](compose/) · [`scripts`](scripts/) · README: [Project Overview](README.md)

---

## Readiness Meter
- [ ] Terraform fundamentals (state, lock, import, modules) — **201**
- [ ] AWS core (IAM, VPC 101, S3, SNS/SQS) — **201**
- [ ] Jenkins CI/CD (design + hardening + speed) — **301**
- [ ] Containers & K8s lite — **201**
- [ ] Observability (logs/metrics/alerts) — **201**
- [ ] Security basics (least privilege, secrets, S3 public access) — **201**
- [ ] 3 STAR stories written (Jenkins win, TF state/lock, SNS→SQS design)

---

## Week 1 — Terraform depth & AWS fundamentals (201)
**Outcomes**
- [ ] S3 **deny-public** + **SSE** + **lifecycle** to logs (in `infra/modules/s3_bucket`)
- [ ] `terraform import` demo for an S3 bucket created with `awslocal`
- [ ] 90-sec **VPC** explanation (public/private, IGW/NAT, SG vs NACL) in README

**Hands-on**
- [ ] Add policy/lifecycle to `s3_bucket` module; `make plan/apply`
- [ ] `awslocal s3 mb s3://demo-import && terraform import aws_s3_bucket.demo_import demo-import`
- [ ] README section: “VPC 101 (90s pitch)”

**Definition of Done**
- [ ] Explain **state vs refresh vs drift vs import** without notes
- [ ] Write an **S3 bucket** with versioning + SSE + deny public from scratch in <10 mins

---

## Week 2 — Jenkins to 301 (design/trade-offs)
**Outcomes**
- [ ] Declarative **Jenkinsfile** (build → test → archive → approval → deploy/notify)
- [ ] **Credentials binding**, **parallel** test stage, and **caching** notes included
- [ ] README: “Pipeline hardening & speed levers”

**Hands-on**
- [ ] Add `Jenkinsfile` at repo root
- [ ] Stage to **publish to SNS** on success (reuse `sns_topic_arn`)
- [ ] Document 3 speedups (parallel, Docker layer cache, dependency cache)

**Definition of Done**
- [ ] Whiteboard a pipeline & **justify** agents, stages, approvals, rollback

---

## Week 3 — Containers/K8s lite + Observability
**Outcomes**
- [ ] Convert Compose app/worker to **K8s** (Deployment, Service, probes, Config/Secret) in `k8s/`
- [ ] **Structured logs** (JSON) in worker with msg id + ts
- [ ] README: 3 **metrics** (queue depth, success %, publish latency) and 2 **alerts**

**Hands-on**
- [ ] `k8s/` manifests; add probes/readiness
- [ ] Update worker to JSON logs
- [ ] README “Observability” with metrics + alert thresholds

**Definition of Done**
- [ ] Explain **readiness vs liveness** and a simple **rollback** in 60s

---

## Week 4 — Security + polish + stories
**Outcomes**
- [ ] S3 **Block Public Access** flags on buckets; confirm in TF
- [ ] **IAM** least-privilege for worker: only `sqs:ReceiveMessage/DeleteMessage` on your queue
- [ ] 3 **STAR stories** (Jenkins speed/hardening, TF state/lock, SNS→SQS design)

**Hands-on**
- [ ] Add bucket public-access blocks + SSE to TF
- [ ] `infra/policies/worker-sqs.json` + README note
- [ ] `stories/` with 3 short STAR write-ups

**Definition of Done**
- [ ] Answer “How do you secure CI/CD and S3?” with **specific** controls in 90s

---

## Daily Micro-Loop (30–45 min)
- [ ] 5 min: skim README “Key concepts” + 3 flashcards
- [ ] 25–30 min: ship **one** hands-on item
- [ ] 5–10 min: append README “Daily log”

---

## Practice Pack (twice/week)
**Terraform/AWS**
- [ ] State/lock/drift/import; quick `import` demo
- [ ] SNS vs SQS; queue **policy** with `SourceArn`
- [ ] Draw 3-tier AWS (SG vs NACL)

**Jenkins**
- [ ] Walk Jenkinsfile; **cache**, **parallel**, **approvals**
- [ ] “Pipeline is slow”—3 concrete levers

**Ops/Sec**
- [ ] 3 metrics + 2 alerts for worker
- [ ] Secrets handling; S3 public access controls

---

## Handy Commands
```bash
terraform -chdir=infra/envs/dev output
TOPIC_ARN=$(terraform -chdir=infra/envs/dev output -raw sns_topic_arn)
QURL=$(awslocal sqs get-queue-url --queue-name arjun-main-queue --query QueueUrl --output text)
awslocal sns publish --topic-arn "$TOPIC_ARN" --message "ping-$(date +%T)"
awslocal sqs receive-message --queue-url "$QURL" --wait-time-seconds 2

make compose-env && make compose-up
docker compose -f compose/docker-compose.yml logs -f worker
make compose-down
