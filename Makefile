SAKURACLOUD_ZONE=tk1a

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
	@chmod +x inventory_handler.py

.PHONY: ansible
.ONESHELL:
ansible:
	@cd ansible
	@pipenv run ansible-playbook -u ubuntu --private-key=../id_rsa setup.yml --extra-vars ansible_sudo_pass=$$CLUSTER_PASS
