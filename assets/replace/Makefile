
include .env

# Default variables
DUMP_FOLDER:=$(APP_ROOT)
REMOTE_USER?="www-data"
REMOTE_CONTAINER?="web"
DOCKER_NETWORK?="localdev-proxied-webapps"

MAKEFLAGS += --no-print-directory

MSG_ERROR:=\033[41m[ error ]\033[0m
MSG_WARNING:=\033[43m[ warning ]\033[0m
MSG_SUCCESS:=\033[42m[ success ]\033[0m

# Set bash as default shell for all commands
SHELL:=/bin/bash
.ONESHELL:

# Help
# Automatically generate help from target comments
.PHONY: help
help: ## This help.
	@awk 'BEGIN {FS = ":.*##"; printf "make [target]\n\nUsage: \033[36m\033[0m\n"} /^[$$()% 0-9a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

.DEFAULT_GOAL := help

# Utility commands
check-in-container-%:
	@if [[ $* == "true" && ! -f /.dockerenv ]]; then
		echo -e "  $(MSG_ERROR)  You are not running in a container. Tooling is only available in the container"
		exit 1
	elif [[ $* == "false" && -f /.dockerenv ]]; then
		echo -e " $(MSG_ERROR) You are running in a container. Command must be executed locally."
		exit 1
	fi

env: env-local

env-%:
	@if [[ $* == "local" ]]; then
		touch .env.secrets
		echo "USER_UID=$$(id -u)" > .env.local
		echo "USER_GID=$$(id -g)" >> .env.local
		if [[ -n "$$SSH_KEY" ]]; then
			echo "SSH_KEY=\"$$(echo "$$SSH_KEY" | sed -z -e 's/\n/\\n/g')\"" >> .env.local
		fi
		if [[ -n "$$COMPOSER_AUTH" ]]; then
			echo "COMPOSER_AUTH=\"$$COMPOSER_AUTH\"" >> .env.local
		fi
		if [[ -x "$$(command -v docker)" ]]; then
			docker network inspect $(DOCKER_NETWORK) >/dev/null 2>&1 || \
				docker network create $(DOCKER_NETWORK)
		fi
	fi

# Local Dev Commands
code: check-in-container-false ## Launch local dev environment
	@echo "Starting VS Code local development environment"
	code .

cli: cli-local ## Alias for cli-local

cli-%: check-in-container-false ## Attach to environment %
	@echo "Attaching to $* environment"
	EXEC_COMMAND="bash"
	EXEC_FLAG="-it"
	if [[ -n "$$COMMAND" ]]; then
		EXEC_COMMAND="$$COMMAND"
		EXEC_FLAG=
	fi
	if [[ $* == "local" ]]; then
		if [[ "$$(docker-compose --version --short)" == "2."* ]]; then
			docker exec $$EXEC_FLAG --user $(REMOTE_USER) --workdir /project $(COMPOSE_PROJECT_NAME)-$(REMOTE_CONTAINER)-1 bash -l -c "$$EXEC_COMMAND"
		else
			docker exec $$EXEC_FLAG --user $(REMOTE_USER) --workdir /project $(COMPOSE_PROJECT_NAME)_$(REMOTE_CONTAINER)_1 bash -l -c "$$EXEC_COMMAND"
		fi
	else
		K8S_CONTEXT="$(K8S_$(shell echo $* | tr a-z A-Z)_CONTEXT)"
		if [[ -z "$$K8S_CONTEXT" ]]; then
			echo -e " $(MSG_ERROR) Kubectl context K8S_$(shell echo $* | tr a-z A-Z)_CONTEXT does not exist."
			exit 1;
		fi
		kubectl exec --context $$K8S_CONTEXT \
			-n $*-drpl-$(PROJECT_CODE_NAME) \
			deploy/$(PROJECT_CODE_NAME)-drpl $$EXEC_FLAG \
			-- bash -l -c "$$EXEC_COMMAND"
	fi

# Deployment commands
local: deploy-local ## Alias for deploy-local

deploy-%: check-in-container-false ## Deploy environment %
	@echo "Deploying $* environment"
	if [[ ! -d ./manifests/$* ]]; then
		echo -e " $(MSG_ERROR) Environment $* does not exist."
		exit 1;
	fi
	if [[ -f ./manifests/$*/docker-compose.yml ]]; then
		make deploy-$*-compose
	elif [[ -f ./manifests/$*/deployment.yml ]]; then
		make deploy-$*-kubectl
	elif [[ -f ./manifests/$*/patch.yml ]]; then
		make deploy-$*-kubectl-patch
	elif [[ -f ./manifests/$*/kustomization.yml ]]; then
		make deploy-$*-kustomize
	else
		echo -e " $(MSG_ERROR) No manifests found for environment $*."
		exit 1;
	fi

deploy-%-compose: check-in-container-false env-local
	@echo "Deploying $* docker-compose manifests"
	docker-compose -p $(COMPOSE_PROJECT_NAME) -f ./manifests/$*/docker-compose.yml up $(COMPOSE_FLAGS)

deploy-%-kubectl: check-in-container-false
	@echo "Deploying $* kubernetes manifests"
	K8S_CONTEXT="$(K8S_$(shell echo $* | tr a-z A-Z)_CONTEXT)"
	K8S_NAMESPACE="$*-drpl-$(PROJECT_CODE_NAME)"
	kubectl create namespace $$K8S_NAMESPACE --dry-run=client -o yaml | kubectl apply --context $$K8S_CONTEXT -f -
	kubectl apply --context $$K8S_CONTEXT -f ./manifests/$*/ -n $$K8S_NAMESPACE

deploy-%-kubectl-patch: check-in-container-false
	@echo "Patching $* kubernetes manifests"
	K8S_CONTEXT="$(K8S_$(shell echo $* | tr a-z A-Z)_CONTEXT)"
	K8S_NAMESPACE="$*-drpl-$(PROJECT_CODE_NAME)"
	K8S_DEPLOYMENT="$(PROJECT_CODE_NAME)-drpl"
	kubectl patch --context $$K8S_CONTEXT deployment $$K8S_DEPLOYMENT -p "$$(cat ./manifests/$*/patch.yml)" -n $$K8S_NAMESPACE || exit 1
	kubectl rollout status --context $$K8S_CONTEXT -w deployment $$K8S_DEPLOYMENT -n $$K8S_NAMESPACE

delete-local: check-in-container-false
	@echo -e " $(MSG_WARNING) This will irreversible delete your local database's and container's data. This will not affect code in the repo."
	echo -n "Do you want to continue? [n] " && read REPLY && [[ $$REPLY == "y" ]] || exit 1
	docker-compose -p $(COMPOSE_PROJECT_NAME) -f ./manifests/local/docker-compose.yml down -v --remove-orphans || exit 1
	docker volume rm $(COMPOSE_PROJECT_NAME)_{db,web}_storage 2>/dev/null || true

# PHP commands
xdebug: check-in-container-true ## Enable XDebug
	@if [[ "$(DRUPAL_ENVIRONMENT)" == "local" ]]; then
		sudo -E enable_xdebug
	fi

xdebug-disable: check-in-container-true ## Disable XDebug
	@if [[ "$(DRUPAL_ENVIRONMENT)" == "local" ]]; then
		sudo -E disable_xdebug
	fi

# Drupal (Drush) commands
new: check-in-container-true ## Create new Drupal site from repo
	@echo "Creating new Drupal site"
	composer install --working-dir=$(APP_ROOT) $(COMPOSER_FLAGS)
	mkdir -p $(APP_ROOT)/{private,config/sync}
	mkdir -p $(NGINX_ROOT)/sites/default/files/translations
	chmod 755 $(NGINX_ROOT)/sites/default/
	chmod 444 $(NGINX_ROOT)/sites/default/*settings.php
	chmod 444 $(NGINX_ROOT)/sites/default/settings.local.php || :
	if [[ -z $$DRUPAL_HASH_SALT ]]; then
		echo -e " $(MSG_WARNING) DRUPAL_HASH_SALT not available for installation."
	fi
	if compgen -G "$$APP_ROOT/resources/*.sql.gz" > /dev/null; then
		drush sqlq --file=$$(compgen -G "$$APP_ROOT/resources/*.sql.gz" | head -1)
		drush updb || exit 1
	else
		drush si $(DRUSH_FLAGS) || exit 1
	fi
	chown -Rf www-data:www-data .

install: check-in-container-true ## Install existing Drupal site
	@echo "Installing Drupal"
	mkdir -p $(APP_ROOT)/private
	mkdir -p $(NGINX_ROOT)/sites/default/files/translations
	chmod 444 $(NGINX_ROOT)/sites/default/*settings.php
	echo "Installing vendor packages"
	if [[ "$(DRUPAL_ENVIRONMENT)" == "prod" ]]; then
		composer install --working-dir=$(APP_ROOT) --no-dev --optimize-autoloader $(COMPOSER_FLAGS)
	else
		composer install --working-dir=$(APP_ROOT) $(COMPOSER_FLAGS)
	fi
	if [[ -n "$(DRUPAL_SPOT)" && "$(DRUPAL_SPOT)" != "$(DRUPAL_ENVIRONMENT)" ]]; then
		if [[ -z "$$(drush sqlq "SHOW TABLES;")" ]]; then
			make db-sync DRUSH_FLAGS=-y
			make fs-sync DRUSH_FLAGS=-y
		fi
	fi
	echo "Deploying Drupal"
	drush deploy || exit 1
	chown -Rf www-data:www-data .

uninstall: check-in-container-true ## Uninstall/reset Drupal site
	@echo "Uninstalling/resetting Drupal"
	drush sql-drop $(DRUSH_FLAGS)
	rm -rf app/vendor/

update: check-in-container-true ## Update Drupal site
	@echo "Updating Drupal"
	composer update --working-dir=$(APP_ROOT) $(COMPOSER_FLAGS) || exit 1
	drush cr
	drush updb $(DRUSH_FLAGS) || exit 1
	drush cex $(DRUSH_FLAGS)

upgrade: ## Upgrade Drupal site
	@echo "Upgrading Drupal"
	if [[ -z "$$JSON_INPUT" ]]; then
		echo -e " $(MSG_ERROR) Missing upgrade operations JSON_INPUT."
		exit 1
	fi
	if make check-in-container-false >/dev/null 2>&1; then
		RSH="make-cli"
	fi
	bash ./.github/actions/upgrade/upgrade.sh

theme: check-in-container-true ## Compile current Drupal theme
	@echo "Compiling Drupal theme"
	drush iq_barrio_helper:sass-interpolate-config 2>/dev/null || true
	drush iqsc:compile 2>/dev/null || true
	drush cr

db-backup: DUMP_FOLDER=$(APP_ROOT)/backups
db-backup: db-dump ## Alias for db-dump w/ backup folder

db-dump: check-in-container-true ## Dump the Drupal database to PWD
	@echo "Dumping Drupal database to $(DUMP_FOLDER)"
	mkdir -p $(DUMP_FOLDER)
	drush sql-dump --gzip --result-file=$(DUMP_FOLDER)/$$(date +%Y%m%d\T%H%M%S).sql

db-sync: check-in-container-true ## Synchronize Drupal database
	@DB_SOURCE=$${DB_SOURCE-$(DRUPAL_SPOT)}
	if [[ -z "$$DB_SOURCE" ]]; then
		echo -e " $(MSG_ERROR) No database source. DB_SOURCE or DRUPAL_SPOT undefined."
		exit 1
	fi
	echo "Synchronizing Drupal database from $$DB_SOURCE"
	drush sql-sync @$$DB_SOURCE @self $(DRUSH_FLAGS)

fs-sync: check-in-container-true ## Synchronize Drupal public files
	@if [[ "$$DRUPAL_FS_SYNC" == "true" ]]; then
		FS_SOURCE=$${FS_SOURCE-$(DRUPAL_SPOT)}
		if [[ -z "$$FS_SOURCE" ]]; then
			echo -e " $(MSG_ERROR) No database source. FS_SOURCE or DRUPAL_SPOT undefined."
			exit 1
		fi
		echo "Synchronizing Drupal public filesystem from $$FS_SOURCE"
		drush rsync @$$DB_SOURCE:%files @self:%files $(DRUSH_FLAGS)
	else
		drush en iq_stage_file_proxy
	fi

project: check-in-container-true ## Deploy Drupal project in current env
	@echo "Starting automatic project deployment"
	CONTINUE_DEPLOYMENT=true
	if [[ -n "$$(git status --porcelain=v1 2>/dev/null)" ]]; then
		echo -e " $(MSG_ERROR) There are uncommited changes. Aborting deployment."
		exit 1
	fi
	if [[ -n "$$GIT_COMMIT" || -n "$$GIT_BRANCH" ]]; then
		git fetch --tags || exit 1
		if [[ $$(git rev-parse HEAD) == $$(git rev-parse $${GIT_COMMIT:-$${GIT_BRANCH/#/origin/}}) ]]; then
			CONTINUE_DEPLOYMENT=false
			echo -e " $(MSG_WARNING) Git is already up-to-date."
		else
			chmod 644 $(NGINX_ROOT)/sites/default/*settings.php
			git checkout $${GIT_COMMIT:-$${GIT_BRANCH}} || exit 1
			if [[ -n "$$GIT_BRANCH" ]]; then
				git pull --ff-only origin $${GIT_BRANCH} || exit 1
			fi
		fi
	fi
	if [[ ! -d "$$APP_ROOT/vendor" ]]; then
		CONTINUE_DEPLOYMENT=true
		echo -e " $(MSG_WARNING) Vendor folder not found."
	fi
	if [[ $$CONTINUE_DEPLOYMENT == "true" ]]; then
		make install
	fi
