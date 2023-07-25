SAKURACLOUD_ZONE=tk1a

.PHONY: init
.ONESHELL:
init: init-env init-ansible init-terraform
	@cd dev
	@if [ ! -e keys ]; then
		chmod +x keys.sh
		./keys.sh
	fi

.PHONY: init-env
.ONESHELL:
init-env:
	@if ! (type direnv >/dev/null 2>&1); then
		echo "下記公式ドキュメントを参考に、direnvをインストールしてください"
		echo "https://github.com/direnv/direnv/blob/master/docs/installation.md"
		exit 0
	fi
	@if [ ! -e .envrc ]; then
		make init-env-file
		direnv allow
	fi

.PHONY: init-env-file
.ONESHELL:
init-env-file:
	@echo "さくらクラウドのアクセストークンを入力してください"
	@read SAKURACLOUD_ACCESS_TOKEN
	@echo "さくらクラウドのアクセスシークレットを入力してください"
	@read SAKURACLOUD_ACCESS_TOKEN_SECRET
	@echo "今年度のcluster_passを入力してください"
	@read CLUSTER_PASS
	@echo "tfstateを保存するバケットを選択してください (default: ictsc-drove)"
	@read TF_STATE_BUCKET
	@if [ -z "$$TF_STATE_BUCKET" ]; then
		TF_STATE_BUCKET=ictsc-drove
	fi
	@echo "さくらのオブジェクトストレージのアクセスキーを入力してください"
	@read TF_STATE_ACCESS_KEY
	@echo "さくらのオブジェクトストレージのシークレットキーを入力してください"
	@read TF_STATE_SECRET_KEY
	@{
		echo "export SAKURACLOUD_ACCESS_TOKEN=$$SAKURACLOUD_ACCESS_TOKEN";
		echo "export SAKURACLOUD_ACCESS_TOKEN_SECRET=$$SAKURACLOUD_ACCESS_TOKEN_SECRET";
		echo "export SAKURACLOUD_ZONE=$(SAKURACLOUD_ZONE)";
		echo "";
		echo "export CLUSTER_PASS=$$CLUSTER_PASS";
		echo "export TF_VAR_cluster_pass=\"\$${CLUSTER_PASS}\"";
		echo "export TF_STATE_BUCKET=$$TF_STATE_BUCKET";
		echo "";
		echo "export TF_STATE_ACCESS_KEY=$$TF_STATE_ACCESS_KEY";
		echo "export TF_STATE_SECRET_KEY=$$TF_STATE_SECRET_KEY";
		echo "export AWS_ACCESS_KEY_ID=\"\$${TF_STATE_ACCESS_KEY}\"";
		echo "export AWS_SECRET_ACCESS_KEY=\"\$${TF_STATE_SECRET_KEY}\"";
	} > .envrc
	@echo ".envrcを作成しました"

.PHONY: delete-env
delete-env:
	@rm -f .envrc
	@echo ".envrcを削除しました"

.PHONY: init-ansible
.ONESHELL:
init-ansible:
	@if ! (type pipenv >/dev/null 2>&1); then
		echo "下記公式ドキュメントを参考に、pipenvをインストールしてください"
		echo "https://pipenv-ja.readthedocs.io/ja/translate-ja/install.html#installing-pipenv"
		exit 0
	fi
	@cd ansible
	@pipenv install -d
	@chmod +x inventory/inventory_handler.py

.PHONY: ansible
.ONESHELL:
ansible:
	@cd ansible
	@pipenv run ansible-playbook router_setup.yml
	@pipenv run ansible-playbook -u ubuntu --private-key=id_rsa setup.yml --extra-vars ansible_sudo_pass=$$CLUSTER_PASS

.PHONY: init-terraform
.ONESHELL:
init-terraform: show-ws
	@if ! (type direnv >/dev/null 2>&1); then
	echo "下記公式ドキュメントを参考に、terraformをインストールしてください"
	echo "https://developer.hashicorp.com/terraform/downloads"
	exit 0
	fi
	@cd terraform
	@terraform init -backend-config="bucket=$$TF_STATE_BUCKET"

.PHONY: show-ws
show-ws:
	@cd terraform && terraform workspace show

.PHONY: select-dev
select-dev:
	@cd terraform && terraform workspace select dev

.PHONY: select-prod
select-prod:
	@cd terraform && terraform workspace select prod

.PHONY: terraform-apply
terraform-apply:
	@cd terraform	&& terraform apply -auto-approve

.PHONY: terraform-destroy
terraform-destroy:
	@cd terraform	&& terraform destroy
