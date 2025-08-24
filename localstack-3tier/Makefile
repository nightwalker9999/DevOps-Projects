ENV ?= dev

fmt:
	terraform fmt -recursive

init:
	cd infra/envs/$(ENV) && terraform init

plan:
	cd infra/envs/$(ENV) && terraform plan -var-file=$(ENV).tfvars -out=plan.tfplan

apply:
	cd infra/envs/$(ENV) && terraform apply -auto-approve plan.tfplan

destroy:
	cd infra/envs/$(ENV) && terraform destroy -var-file=$(ENV).tfvars -auto-approve

compose-up:
	#TODO: Put the file path in var and use it in the below commands
	docker compose -f ./compose/docker-compose.yml up -d --build
	@echo "Waiting for healthchecks..."
	docker compose -f ./compose/docker-compose.yml ps

compose-down:
	docker compose -f ./compose/docker-compose.yml down -v

compose-logs:
	docker compose -f ./compose/docker-compose.yml logs -f

db-shell:
	docker exec -it mysql mysql -u$${MYSQL_USER} -p$${MYSQL_PASSWORD} $${MYSQL_DATABASE}

seed-msg:
	#publish a test message via LocalStack SNS -> your flow should land in SQS and be consumed by worker
	awslocal sns publish --topic-arn "$$(awslocal sns list-topics --query 'Topics[0].TopicArn' --output text)" --message '{"hello": "mysql"}'

ls-state:
	./scripts/bootstrap_state_localstack.sh

ls-msg:
	./scripts/bootstrap_messaging_localstack.sh

e2e:
	curl -s -X POST http://localhost:8000/notify -H 'Content-Type: application/json' -d '{"message":"hello-from-make"}' ; \
	docker compose -f ./compose/docker-compose.yml logs -f worker