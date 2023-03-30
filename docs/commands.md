# Project Commands (Makefile)

## Make targets

The following `make` targets are available in the project's `Makefile`. They can be executed in the project root using `make TARGET`.

### Help

* `help`: Display help

### Drupal commands

> These commands can only be run from within the Drupal container

* `project`: Auto-install the Drupal project into the current environment (requires a running container environment)
    * Checks if there are uncommited changes and aborts if detected
    * Pulls new commits from git if set (`$GIT_COMMIT` or `$GIT_BRANCH`)
    * Checks if `vendor` folder exists
    * Runs `make install` if checks passed
* `install`: Install the existing Drupal site
    * Runs `composer install` (with `--no-dev` on `prod`)
    * Execute `make db-sync` and `make fs-sync` if the database is empty
    * Runs `drush deploy` (WARNING: This will override config)
* `update`: Update the Drupal site (`composer` and `drush`) and export the new config
* `theme`: Compile the current Drupal theme (`iq_barrio`)
* `db-backup`: Alias for db-dump wth `$APP_ROOT/backups` as backup folder
* `db-dump`: Dump the Drupal database to `$DUMP_FOLDER` (or if not set to `$APP_ROOT`)
* `db-sync`: Synchronize Drupal database from `$DB_SOURCE` (if not set from `$DRUPAL_SPOT`)
* `fs-sync`: Synchronize Drupal public files if `$DRUPAL_FS_SYNC` is set to `true` (`rsync`), otherwise enables `iq_stage_file_proxy`.
* `uninstall`: Uninstall/reset the Drupal site
* `new`: Create a new Drupal site form repo (`drush site:install` with profile or from a backup in the `app/resources` folder)

### Development commands

> These commands can only be run outside of the Drupal container

* `code`: Open Visual Studio Code for code development
* `cli`: Alias for `cli-local`
* `cli-local`: Attach to the local environment shell
* `cli-prod`: Attach to the production environment shell
* `cli-%`: Attach to the `%` environment shell (replace `%` with name of environment in `./manifests` folder)

### Deployment commands

> These commands can only be run outside of the Drupal container

* `local`: Alias for `deploy-local`
* `deploy-local`: Deploy the local environment (`docker-compose`)
* `deploy-prod`: Deploy the production environment (Kubernetes) – _not yet supported_
* `deploy-%`: Deploy the `%` environment (replace `%` with name of environment in `./manifests` folder)
* `delete-local`: Delete the local deployment with `docker-compose` permanently

### PHP commands

> These commands can only be run from within the Drupal container

* `xdebug`: Enable XDebug and restart the web server.
* `xdebug-disable`: Disable XDebug and restart the web server.

## Scripts and aliases

There are also scripts and a bunch of aliases available in the Drupal container. Check the [script documentation of the Drupal image](https://github.com/iqual-ch/dc-drupal/blob/main/docs/scripts.md).