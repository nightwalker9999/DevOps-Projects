# devops-3tier-local (LocalStack-first) — Day 1 Starter

**Goal today:** Bring up Terraform against LocalStack with remote state (S3) and locking (DynamoDB), plus create one S3 bucket and one SQS queue (with DLQ).

## Prereqs
- LocalStack: `pipx install localstack awscli-local` (or `pip install --user ...`)
- Start LocalStack: `localstack start -d`
- Exports (shell rc or current session):
  ```bash
  export AWS_ACCESS_KEY_ID=test
  export AWS_SECRET_ACCESS_KEY=test
  export AWS_DEFAULT_REGION=us-east-1
  export AWS_ENDPOINT_URL=http://localhost:4566
  ```

## Bootstrap backend resources (state bucket + lock table)
```bash
./scripts/bootstrap_state_localstack.sh
```

## Terraform (dev env)
```bash
make init
make plan ENV=dev
make apply ENV=dev
# verify / later
make destroy ENV=dev
```

If `terraform init` fails due to backend options, ensure LocalStack is running and the bootstrap script completed successfully.
