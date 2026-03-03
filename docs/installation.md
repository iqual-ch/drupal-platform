# App Installation

To install the app (Drupal) in a running environment use `make install`. This will start the DDEV runtime, build Drupal and deploy it. The detailed steps are documented below.

> An installation will override existing config. Make sure to export the live config to the repository before running an installation, if desired.

## Automated Installation

Running `make install` will:

1. **Start the DDEV runtime** (`make runtime`) — starts all DDEV services. If `DDEV_SNAPSHOT` is set, it will restore the specified database snapshot.
2. **Build and deploy Drupal** (`make stack`) which runs:
   * `make drupal-build`: Runs `ddev composer install` and creates required directories.
   * `make drupal-data`: Imports database and filesystem from the SPOT (only if database is empty, unless `FORCE=true`).
   * `make drupal-deploy`: Runs `drush deploy` to apply database updates and import config from the repository.

To also check for uncommitted git changes before installing, use `make install-safe`.

### New Project Installation

To create a new Drupal site (instead of importing from an existing SPOT), use:

```bash
make new
```

This will either run `drush site:install --existing-config` or import a database backup from the `app/resources` directory if one exists (first `.sql.gz` file).


## Remote Installation (Upsun)

Drupal will be built and deployed automatically on Upsun (formerly Platform.sh). This includes running database updates, config imports and cache rebuilds (i.e. `drush deploy`). See the [deployment documentation](./deployment.md#auto-deployment) for more details.
