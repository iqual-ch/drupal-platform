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

include app/resources/deploy.mk app/resources/utility.mk app/resources/drupal.mk
