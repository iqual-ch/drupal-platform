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