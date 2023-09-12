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

# PHP commands
xdebug: check-in-container-true ## Enable XDebug
	@if [[ "$(DRUPAL_ENVIRONMENT)" == "local" ]]; then
		sudo -E enable_xdebug
	fi

xdebug-disable: check-in-container-true ## Disable XDebug
	@if [[ "$(DRUPAL_ENVIRONMENT)" == "local" ]]; then
		sudo -E disable_xdebug
	fi