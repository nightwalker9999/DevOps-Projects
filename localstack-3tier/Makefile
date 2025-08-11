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

// TODO: Makefile:19: *** missing separator.  Stop.
# bootstrap:
# \t./scripts/bootstrap_state_localstack.sh

# init: bootstrap
# \tcd infra/envs/$(ENV) && terraform init -reconfigure
