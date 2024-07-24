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

# Tool commands
tool-%: ## Launch tools
	@echo -e "Launching tooling: $*"
	docker-compose -p $(COMPOSE_PROJECT_NAME) --profile $* -f ./manifests/local/docker-compose.yml up -d $*

# PHP commands
xdebug: check-in-container-true ## Enable XDebug
	@if [[ "$(DRUPAL_ENVIRONMENT)" == "local" ]]; then
		sudo -E enable_xdebug
	fi

xdebug-disable: check-in-container-true ## Disable XDebug
	@if [[ "$(DRUPAL_ENVIRONMENT)" == "local" ]]; then
		sudo -E disable_xdebug
	fi

test: validate lint phpunit ## Run tests

test-all: validate lint phpunit-all ## Run all tests (w/ browser)

validate: ## Validate composer file
	@echo "Validating composer lock file"
	composer validate -d $(APP_ROOT) $(COMPOSER_FLAGS)

lint: phplint phpcs ## Run linters

phplint:
	@echo "Running PHP linting"
	REPO_CODE="$$(git ls-tree -d -r $$(git write-tree) --name-only | grep -E '(themes|modules)/custom/[^/]+$$' | paste -s -)"
	if [[ -x "$$(command -v parallel-lint)" ]]; then
		parallel-lint $$REPO_CODE -e php,module,theme,inc,install,profile $(PARALINT_FLAGS)
	else
		find $$REPO_CODE \( -name '*.php' -o -name '*.module' -o -name '*.theme' -o -name '*.inc' -o -name '*.install' -o -name '*.profile' \) -exec php -l {} \;
	fi

phpcs:
	@[ -z "$(PHPCS_FLAGS)" ] && echo "Running PHPCS code sniffer"
	pushd $(APP_ROOT) > /dev/null
	REPO_CODE="$$(git ls-tree -d -r $$(git write-tree) --name-only | grep -E '(themes|modules)/custom/[^/]+$$' | paste -s -)"
	phpcs --standard=Drupal,DrupalPractice \
		--runtime-set ignore_warnings_on_exit 1 \
		--extensions=php,module,inc,install,test,profile,theme,css,info,txt,md,yml \
		--ignore=node_modules,bower_components,vendor,custom.css $(PHPCS_FLAGS) \
		$$REPO_CODE

phpunit-all: phpunit phpunit-db phpunit-browser

phpunit: ## Run PHPUnit PHP only tests
	@echo "Running PHPUnit unit tests"
	PHPUNIT_CONFIG=$${PHPUNIT_CONFIG-$(APP_ROOT)}
	pushd $(APP_ROOT) > /dev/null
	phpunit -c $$PHPUNIT_CONFIG --testsuite=unit $(PHPUNIT_FLAGS)

phpunit-db: ## Run PHPUnit tests relying on a database
	@echo "Running PHPUnit database tests"
	echo -e " $(MSG_WARNING) Some tests could modify your existing database."
	PHPUNIT_CONFIG=$${PHPUNIT_CONFIG-$(APP_ROOT)}
	pushd $(APP_ROOT) > /dev/null
	phpunit -c $$PHPUNIT_CONFIG --testsuite=kernel,functional,existingsite $(PHPUNIT_FLAGS)

phpunit-browser: ## Run PHPUnit tests relying on a browser
	@echo "Running PHPUnit browser tests"
	echo -e " $(MSG_WARNING) Some tests could modify your existing database."
	PHPUNIT_CONFIG=$${PHPUNIT_CONFIG-$(APP_ROOT)}
	pushd $(APP_ROOT) > /dev/null
	phpunit -c $$PHPUNIT_CONFIG --testsuite=functional-javascript,existingsite-javascript $(PHPUNIT_FLAGS)