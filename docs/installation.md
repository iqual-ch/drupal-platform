# App Installation

To install the app (Drupal) in a running environment it is possible to use `make project`. This will do some checks and then run `make install` installing Drupal. The detailed steps are documented below.

> An installation will override existing config. Make sure to export the live config to the repository before running an installation, if desired.

## Automated Installation

When running `make project` the script will first make sure, that there are no uncomitted changes and abort if detected. If the git environment variables are set (`$GIT_COMMIT` or `$GIT_BRANCH`) it will then pull the newest commits from git. It will check if the vendor folder exists. If all checks pass it will then run `make install`.

The `make install` command will run `composer install` in the app root (with `--no-dev` on `prod` `DRUPAL_ENVIRONMENT`). After installing the vendor packages it will then execute a `make db-sync` and `make fs-sync` if the database is empty. This will grab the newest database and assets from the `DRUPAL_SPOT`. Afterwards it runs `drush deploy`, making sure the database is up-to-date and to import the config from the repository. This will override any config present on the database but not on the filesystem.

## Manual Installation

For a manual installation, the following commands can be run (for a `prod` installation):

```bash
git pull
maintenance on
composer install --no-dev --optimize-autoloader
drush deploy
chown -R www-data:www-data /project/app
maintenance off
```