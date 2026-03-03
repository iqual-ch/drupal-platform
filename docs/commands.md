# Project Commands (Makefile)

The project includes a `Makefile` with predefined targets for common project tasks. All targets can be executed in the project root using `make TARGET`.

> [!TIP]
> Run `make help` for a full list of available commands with descriptions.

## Local Development

* `code`: Launch VS Code for local development
* `cli`: Attach to the local DDEV shell (alias for `cli-local`)
* `cli-local`: Attach to the local DDEV environment shell (`ddev ssh`)

## Project Installation

* `install`: Install the project stack with runtime (starts DDEV, builds and deploys Drupal)
* `install-safe`: Same as `install` but first checks for uncommitted git changes
* `new`: Create a new Drupal project (runs `install` with `NEW_PROJECT=true`, which runs `drush site:install` or imports a database backup from `app/resources`)
* `runtime`: Start the local DDEV runtimes (`ddev start`)

> Use `DDEV_SNAPSHOT=latest` to restore the latest DDEV snapshot during `make runtime`, or specify a named snapshot with `DDEV_SNAPSHOT=<name>`.

## Drupal

* `drupal`: Build and deploy Drupal locally, runs:
    * `drupal-build`: Build the Drupal app (`composer install`, create required directories)
    * `drupal-data`: Import Drupal data (database and filesystem), runs:
        * `drupal-db`: Import the Drupal database from the SPOT (skips if database already exists unless `FORCE=true`)
        * `drupal-fs`: Import the Drupal filesystem (uses `iq_stage_file_proxy` by default, or `drush rsync` if `FS_PULL=true`)
    * `drupal-deploy`: Run Drupal deployment commands (`drush deploy`, skipped if `DRUPAL_NO_DEPLOY=true`)

## Maintenance

* `update`: Update the Drupal site (`composer update`, `drush updb`, `drush cex`)
* `upgrade`: Upgrade the Drupal site by running the `upgrader.sh` script with a `JSON_INPUT`. See the [upgrade workflow documentation](automation.md#upgrade-drupal-project).
* `config-pull`: Pull Drupal configuration from the SPOT (`drush config:pull`)
* `theme`: Compile the current Drupal theme

## Utility

* `launch`: Open the project in the browser
* `login`: Open the browser with a one-time login link
* `log`: Show recent Drupal watchdog and DDEV logs
* `stop`: Stop the local DDEV runtimes
* `destroy`: Permanently delete the local DDEV runtimes

## Services

* `service-solr`: Install and configure the DDEV Solr service

## Tooling

* `tool-chrome`: Install the DDEV Selenium Chrome extension (use `REMOVE=true` to uninstall)

## Testing

* `test`: Run project tests (first runs `drupal-validate`, `drupal-lint`, `drupal-analysis` and then), runs:
    * `drupal-test-unit`: Run the Drupal unit testsuite
* `drupal-test-list`: List all available Drupal tests
* `drupal-test-func`: Run Drupal functional tests (unit, kernel, functional, functional-javascript)
* `drupal-test-db`: Run Drupal database tests (kernel, functional, existingsite) — _Warning: can modify your DB_
* `drupal-test-browser`: Run Drupal browser tests (functional-javascript, existingsite-javascript) — _Warning: requires Chrome tool, can modify your DB_

## Linting

* `lint`: Lint the project, runs:
    * `drupal-validate`: Validate the Composer lock file
    * `drupal-lint`: Lint custom themes and modules (PHP lint + PHPCS)
    * `drupal-analysis`: Run PHPStan static analysis on custom themes and modules

## Beautifying

* `beauty`: Beautify and fix code in the project, runs:
    * `drupal-beauty`: Run PHPCBF on custom themes and modules

## DDEV Commands

In addition to `make` targets, the following DDEV commands are available and can be executed directly with `ddev <command>`:

* `ddev composer`: Run Composer inside the web container
* `ddev drush`: Run Drush inside the web container
* `ddev phpunit`: Run PHPUnit inside the web container
* `ddev phpcs`: Run PHPCS inside the web container
* `ddev phpcbf`: Run PHPCBF inside the web container
* `ddev phpstan`: Run PHPStan inside the web container
* `ddev lint`: Run PHP linting inside the web container

> [!TIP]
> Check the [official DDEV documentation for `ddev` CLI usage](https://docs.ddev.com/en/stable/users/usage/cli/).

## Shell Aliases

There are also shell aliases available inside the DDEV container (via `ddev ssh`) and on the remote Upsun deployment. These include shortcuts for common `git`, `drush` and navigation commands. Notable aliases include:

* `cr`: `drush cache:rebuild`
* `cex`: `drush config:export`
* `cim`: `drush config:import`
* `uli`: `drush user:login`
* `cdd`: Change directory to a Drupal directory (e.g. `cdd %files`)
* `dssh`: SSH into a remote Drush alias (e.g. `dssh @spot`)

> Run `ddev ssh` to access the container shell and use these aliases.
