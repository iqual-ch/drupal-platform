# Test for make v3.81 (usually macOS)
ifeq ($(MAKE_VERSION),3.81)
    $(error system Make (3.81) is too old and not supported.)
endif

# Log message styles
MSG_ERROR:=\033[41m[ error ]\033[0m
MSG_WARNING:=\033[43m[ warning ]\033[0m
MSG_SUCCESS:=\033[42m[ success ]\033[0m
MSG_INFO:=\033[44m[ info ]\033[0m

# Set bash as default shell for all commands
SHELL:=/bin/bash
.ONESHELL:
.SHELLFLAGS:=-e -o pipefail -c
MAKEFLAGS += --no-print-directory

# Help
# Automatically generate help from target comments
.PHONY: help
help: ## Show this help message
	@awk 'BEGIN {
		FS = ":.*##"
		printf "\033[1mUsage\033[0m: make \033[36m[target]\033[0m\n\n"
	}
	/^## / {
		# Print a heading line, stripping off the leading "## "
		printf "\n\033[1m%s\033[0m:\n", substr($$0, 4)
	}
	/^[0-9A-Za-z_.-]+:.*?##/ {
		# Print a target line with its description
		printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2
	}' $(MAKEFILE_LIST)
	echo -e "\n\033[1mQuick start\033[0m: make \033[36minstall\033[0m"

quickhelp:
	@echo -e "\033[1mDrupal Project CLI\033[0m\n"
	echo -e "\033[1mUsage\033[0m: make \033[36m[target]\033[0m"
	echo -e "\033[1mQuick Start\033[0m: make \033[36minstall\033[0m\n"
	echo -e "Essential Commands:"
	echo -e "  \033[36minstall\033[0m      Setup and install the project"
	echo -e "  \033[36mlaunch\033[0m       Open project in browser"
	echo -e "  \033[36mcode\033[0m         Start coding in VS Code"
	echo -e "  \033[36mhelp\033[0m         Show all available commands"

.DEFAULT_GOAL := quickhelp

## Local Dev
code: ## Launch local dev environment
	@echo "Starting VS Code local development environment"
	code .

cli: cli-local ## Attach shell to local environment

cli-local:
	@ddev ssh

# Legacy
project: install-safe
local: install
deploy-local: runtime
db-sync: drupal-db
fs-sync: drupal-fs
delete-local: destroy
up: runtime
down: stop

## Project Installation
install-safe: git-status install

install: runtime stack ## Install project stack with runtime

new: ## Create new project
	@echo -e " $(MSG_INFO) Creating new project"
	$(MAKE) install NEW_PROJECT=true

runtime: ## Start local runtime
	@echo -e " $(MSG_INFO) Starting DDEV runtimes"
	ddev start
	if [ -n "$(DDEV_SNAPSHOT)" ]; then
		if [ "$(DDEV_SNAPSHOT)" = "latest" ]; then
			ddev snapshot restore --latest
		else
			ddev snapshot restore "$(DDEV_SNAPSHOT)"
		fi
	fi

stack: drupal

drupal: drupal-build drupal-data drupal-deploy ## Build & deploy Drupal locally
	@echo -e " $(MSG_SUCCESS) Drupal is ready"
	ddev drush status

drupal-build: ## Build drupal app
	@echo -e " $(MSG_INFO) Building Drupal app"
	ddev composer install $(COMPOSER_FLAGS)
	mkdir -p app/private
	mkdir -p app/public/sites/default/files/translations

drupal-data: drupal-db drupal-fs ## Import drupal data (fs+db)

drupal-db: ## Import drupal database
	@echo -e " $(MSG_INFO) Importing Drupal database"
	if [ "$(NEW_PROJECT)" = "true" ]; then
		echo -e " $(MSG_INFO) Running Drupal site install"
		if compgen -G "$$DDEV_COMPOSER_ROOT/resources/*.sql.gz" > /dev/null; then
			ddev drush sqlq --file=$$(compgen -G "$$DDEV_COMPOSER_ROOT/resources/*.sql.gz" | head -1)
			ddev drush updb
		else
			ddev drush si --existing-config --yes $(DRUSH_FLAGS)
		fi
		exit 0
	fi
	if [ -z "$$(ddev drush status --fields=bootstrap)" ] || [ "$(FORCE)" = "true" ]; then
		ddev drush sql:sync @spot @self --yes $(DRUSH_FLAGS)
	else
		echo -e " $(MSG_WARNING) Existing database detected. Skipping database import. Use \"FORCE=true\" to force import."
	fi

drupal-fs: ## Import drupal filesystem
	@echo -e " $(MSG_INFO) Importing Drupal filesystem"
	if [ "$(FS_PULL)" = "true" ]; then
		ddev drush rsync @spot:%files @self:%files --yes $(DRUSH_FLAGS)
	else
		ddev drush en --yes stage_file_proxy || echo -e " $(MSG_WARNING) \"stage_file_proxy\" is unavailable. Skipping Drupal filesystem."
	fi

drupal-deploy: ## Run drupal deployment commands
	@echo -e " $(MSG_INFO) Running Drupal deployment commands"
	ddev drush deploy

## Maintenance
update: ## Update Drupal site
	@echo "Updating Drupal"
	composer update $(COMPOSER_FLAGS)
	drush cr
	drush updb $(DRUSH_FLAGS)
	drush cex $(DRUSH_FLAGS)

upgrade: ## Upgrade Drupal site
	@echo "Upgrading Drupal"
	if [ -z "$$JSON_INPUT" ]; then
		echo -e " $(MSG_ERROR) Missing upgrade operations JSON_INPUT."
		exit 1
	fi
	RSH="make-cli"
	bash ./.github/actions/upgrade/upgrade.sh

## Utility
launch: ## Launch project
	@ddev launch

login: ## Login to project
	@ddev launch $$(ddev drush uli)

log: ## Show logs
	@ddev drush ws --count=25
	ddev logs --tail=25

theme: ## Compile Drupal theme
	@echo "Compiling Drupal theme"
	drush iq_barrio_helper:sass-interpolate-config 2>/dev/null || true
	drush iqsc:compile 2>/dev/null || true
	drush cr

stop: ## Stop local runtime
	@echo -e " $(MSG_INFO) Stopping DDEV runtimes"
	ddev stop

destroy: ## Destroy local runtime
	@echo -e " $(MSG_INFO) Destroying DDEV runtimes"
	ddev delete

## Testing
test: drupal-test ## Run project tests

drupal-test: ## Test Drupal
	@echo -e " $(MSG_INFO) Testing Drupal"
	ddev phpunit

## Linting
lint: drupal-validate drupal-analysis drupal-lint ## Lint project

drupal-validate: ## Validate Drupal
	@echo -e " $(MSG_INFO) Validating composer lock file"
	ddev composer validate

drupal-analysis: ## Static analysis of Drupal
	@echo -e " $(MSG_INFO) Static analysis Drupal"
	ddev phpstan

drupal-lint: ## Lint Drupal
	@echo -e " $(MSG_INFO) Linting Drupal"
	REPO_CODE="$$(git ls-tree -d -r $$(git write-tree) --name-only | grep -E '(themes|modules)/custom/[^/]+$$' | paste -s -)"
	ddev parallel-lint $${REPO_CODE/drupal\//} -e php,module,theme,inc,install,profile $(PARALINT_FLAGS)
	ddev phpcs

## Beautifying
beauty: drupal-beauty ## Beautify & fix code in project

drupal-beauty: ## Beautify & fix Drupal
	@echo -e " $(MSG_INFO) Beautify & fixing Drupal"
	ddev phpcbf

# Helper Commands
git-status:
	@echo -e " $(MSG_INFO) Checking if git is clean"
	if [ -n "$$(git status --porcelain=v1 2>/dev/null)" ]; then
		echo -e " $(MSG_ERROR) Git is not clean. Please commit your changes."
		exit 1
	fi