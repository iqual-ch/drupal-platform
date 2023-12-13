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
* `upgrade`: Upgrade the Drupal site by running the `upgrade.sh` script with a `JSON_INPUT`. See the [upgrade workflow documentation](automation.md#upgrade-drupal-project).
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
* `deploy-dev`: Deploy the development environment (Kubernetes) – _patch operation by default_
* `deploy-stage`: Deploy the staging environment (Kubernetes) – _patch operation by default_
* `deploy-prod`: Deploy the production environment (Kubernetes) – _patch operation by default_
* `deploy-%`: Deploy the `%` environment (replace `%` with name of environment in `./manifests` folder)
* `delete-local`: Delete the local deployment with `docker-compose` permanently

### Tool commands

> These commands can only be run outside of the Drupal container

* `tool-%`: Launch the tool `%` (e.g. `tool-chrome`)

See [Drupal development documentation](drupal-development.md#external-tools) for a list of available external tools.

### PHP commands

> These commands can only be run from within the Drupal container

* `xdebug`: Enable XDebug and restart the web server.
* `xdebug-disable`: Disable XDebug and restart the web server.
* `test`: Run basic tests, but only unit tests with PHPUnit
* `test-all`: Run all available tests, including database and browser tests (requires the `chrome` tool)
* `validate`: Validate the composer lock file
* `lint`: Run linters
* `phplint`: Run a simple PHP syntax lint on custom theme & module files in the repo
* `phpcs`: Run PHPCS on custom theme & module files in the repo according to the Drupal standards
* `phpunit-all`: Run all PHPUnit based tests
* `phpunit`: Run the unit testsuite with PHPUnit
* `phpunit-db`: Run kernel, functional & existingsite testsuites with PHPUnit requiring a database (_Warning: Can modify your DB_)
* `phpunit-browser`: Run functional-javascript & existingsite-javascript testsuites with PHPUnit requiring a browser (_Warning: Can modify your DB_)

## Scripts and aliases

There are also scripts and a bunch of aliases available in the Drupal container. Check the [script documentation of the Drupal image](https://github.com/iqual-ch/dc-drupal/blob/main/docs/scripts.md).