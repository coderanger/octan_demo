all: plan

frontend.tgz:
	chef update policies/frontend.rb
	chef export --force policies/frontend.rb policy_export/frontend
	tar czvf policy_export/frontend.tgz -C policy_export/frontend .

backend.tgz:
	chef update policies/backend.rb
	chef export --force policies/backend.rb policy_export/backend
	tar czvf policy_export/backend.tgz -C policy_export/backend .

policies: frontend.tgz backend.tgz

get:
	terraform get tf/

plan:
	terraform plan tf/

apply:
	terraform apply tf/

.PHONY: all frontend.tgz backend.tgz plan apply policies
