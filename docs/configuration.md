# Configuration

The project setup allows a lot of customization using multiple configuration options. The runtime and Drupal environment can be modified for project needs.

## Drupal Platform Package Variables

Assets and configuration managed by the Drupal Platform have to be customized using the available package variables. These can be set in the `composer.json`'s `extra.project-scaffold` section. To apply the changes run `composer project:scaffold`. By default the package will only prompt for the required variables (marked with a [`*`]) and vanity variables (marked with a [`~`]) on initial installation of the package, during an update or when executing `composer project:update`.

<details>
<summary>List of available package variables</summary>
<br>

* `project_name`: Optional override for default project name (i.e. `{{name}}-sw-project`)
* `name` [`*`]: Code name of the project (e.g. `iqual`)
* `title` [`~`]: Title of the project (e.g. `iqual AG`)
* `url` [`*`]: URL to the current remote live deployment (e.g. `https://www.iqual.ch`)
* `drupal_spot` [`*`]: The Drupal single point of truth for asset synchronization (machine name of the main Platform.sh branch, e.g. `main-123`)
* Runtime configuration
  * `runtime.php_version` [`*`]: PHP version of the platform (e.g. `8.3`)
  * `runtime.db_version` [`*`]: Database version of the platform (e.g. `10.6`)
  * `runtime.solr_version`: Solr version of the platform (e.g. `9.2`, `null` to disable)
  * `runtime.php_memory_limit`: PHP memory limit (e.g. `256M`)
  * `runtime.php_upload_limit`: PHP upload limit (e.g. `100M`)
* CI/CD workflow settings
  * `workflows.update`: Enable/Add the Drupal update workflow
  * `workflows.upgrade`: Enable/Add the Drupal upgrade workflow
  * `workflows.phpunit`: Enable/Add the Drupal testing workflow
  * `workflows.vrt`: Enable/Add the visual regression testing workflow
* `deployment`: Deployment integration type, see [available remote deployment options](./deployment.md#remote-deployment)
* Platform.sh config
  * `platformsh_config.region`: Deployment region (e.g. `ch-1`)
  * `platformsh_config.project_id`: ID of the project

</details>

## Environment

## Environment Variables

General project environment variables for the local environment are configured in `.ddev/config.yaml` under `web_environment`. This includes the `DRUPAL_ENVIRONMENT`, `DRUPAL_SPOT`, `DRUPAL_SPOT_ORIGIN`, and testing-related variables (`SIMPLETEST_DB`, `SIMPLETEST_BASE_URL`, etc.).  To add non-sensistive environment variables, create a `.ddev/config.custom.yaml` file with custom entries under `web_environment`. After running `ddev start` these will be merged into the base configuration and become available in the runtime environment.

> [!CAUTION]
> The `.ddev/config.yaml` is managed by the Drupal Platform and should not be modified manually.

> [!WARNING]
> The `.env` file in the root of the project is not supported by default. Neither DDEV nor the remote deployment on Upsun will pick up the file's contents by default.

## Secrets

Local development secrets can be stored in `.ddev/.env` (git-ignored). This can be useful for storing sensitive API credentials as environment variables that can be loaded into the config in a settings file in Drupal (see Credentials in Config section).

Remote deployment secrets on Platform.sh can be injected using [project or environment variables](#credentials-on-platformsh).

### SSH Authentication

For remote `drush` commands (e.g. `drush sql:sync @spot @self`), SSH authentication must be available in DDEV. Register your SSH key with:

```bash
ddev auth ssh
```

> [!TIP]
> In order to only add a single key, use `ddev auth ssh -f $HOME/.ssh/YOUR_SSH_KEY`.

This makes your host `ssh-agent` keys available inside the DDEV container.

## Drupal Settings and Services

### Settings

Currently Drupal's `settings.php` file (in `./app/public/sites/default`) is being managed by the Drupal Platform package. The settings file will
look for environment variables to configure Drupal (e.g. database settings) and then load environment specific files in the following order:

1. `all.settings.php`
2. `all.services.yml`
3. `${DRUPAL_ENVIRONMENT}.settings.php`
4. `${DRUPAL_ENVIRONMENT}.services.yml`
5. `settings.local.php` (ignored by git)
6. `services.local.yml` (ignored by git)

So for example for configuring `local` environments, settings can be added to the `local.settings.php` file.

> [!TIP]
> For sensitive settings or configuration that should only apply to your local copy of the environment use the `settings.local.php` file. This file is git ignored by default and won't be committed and therefore configuration won't apply to other developers' environments.

#### Platform.sh Environment Type

For Platform.sh deployments the environment type (`$PLATFORM_ENVIRONMENT_TYPE`) is mapped to the following Drupal environment (`$DRUPAL_ENVIRONMENT`) equivalents:

* `production`: `prod`
* `staging`: `stage`
* `development`: `dev`

Therefore the Platform.sh environment type `production` will still include the `prod.settings.php` settings file.

### Credentials in Config

Credentials or other sensitive information should not be committed to the project's repository. Instead placeholders should be used in the config and the config options should then be overridden in a settings file. The settings file can load the data from environment variables (e.g. stored in `.ddev/.env`) or (not recommended) contain the sensitive information if it is git-ignored (i.e. `settings.local.php`) .

For example, if you want to store the API key and webhook hash of the Mailchimp module in an environment variable, you can add the following to the `all.settings.php` (applying to all environments, and committed):

```php
$config['mailchimp.settings'] = [
    "api_key" => (getenv('MAILCHIMP_API_KEY') ?: ""),
    "webhook_hash" => (getenv('MAILCHIMP_WEBHOOK_HASH') ?: ""),
];
```

Then the `MAILCHIMP_API_KEY` and `MAILCHIMP_WEBHOOK_HASH` can be set in the environment using the `.ddev/.env` file. Alternatively it is still possible to override the variables directly in the `settings.local.php` file.

For more advanced setups use a key management module.

#### Credentials on Upsun

Upsun (formerly Platform.sh) allows adding variables to [projects](https://fixed.docs.upsun.com/development/variables/set-variables.html#create-project-variables) and [specific environments](https://fixed.docs.upsun.com/development/variables/set-variables.html#create-environment-specific-variables). This enables adding sensitive credentials directly for projects or environments. By using specific variable keys, it is also possible to directly override Drupal settings or configuration.

Variables that begin with `drupalsettings` or `drupal` get mapped to the $settings array verbatim, even if the value is an array. For example, a variable named `drupalsettings:example-setting` with value `foo` becomes `$settings['example-setting'] = 'foo';`.

Variables that begin with `drupalconfig` get mapped to the `$config` array. Deeply nested variable names, with colon delimiters, get mapped to deeply nested array elements. Array values get added to the end just like a scalar. Variables without both a config object name and property are skipped. Examples:

* Variable `drupalconfig:conf_file:prop` with value `foo` becomes `$config['conf_file']['prop'] = 'foo';`
* Variable `drupalconfig:conf_file:prop:subprop` with value `foo` becomes `$config['conf_file']['prop']['subprop'] = 'foo';`
* Variable `drupalconfig:conf_file:prop:subprop` with value `['foo' => 'bar']` becomes `$config['conf_file']['prop']['subprop']['foo'] = 'bar';`
* Variable `drupalconfig:prop` is ignored.

### Caching

Caching is enabled by default on all environments, except for the `render` cache, which is disabled on `local` environments. To enable or disable a cache bin add (or create) the configuration to the `settings.local.php` of your local copy of the project.

For example to enable the `render` cache, the following can be set in the  `settings.local.php`:

```php
$settings['cache']['bins']['render'] = 'cache.backend.database';
```

For example to disable the `dynamic_page_cache` cache, the following can be set in the  `settings.local.php`:

```php
$settings['cache']['bins']['dynamic_page_cache'] = 'cache.backend.null';
```

### Twig

Twig debugging is disabled by default. To enable it on your local copy of the project, add (or create) the following to your `services.local.yml`:

```yml
parameters:
  twig.config:
    debug: true
    auto_reload: true
    cache: false
```

## Solr

If a `runtime.solr_version` is defined (e.g. `9.2` instead of `null`) then an additional Solr service will be deployed. This Solr integration only supports a single core with the name `site_search`. Unless a `solrconfig.xml` exists in the `/solr/site_search/conf/` directory, it will not create a core on start-up.

### Set-up a new Solr core with Search API

In order to create a new Solr core for use with the search API, the following steps have to be followed:

> [!WARNING]
> The `solr` setup has only been tested with `solr` version `8.11` and `9.2`.

1. Install the Search API Solr module:

```bash
ddev composer require drupal/search_api_solr
ddev drush en search_api_solr
```

2. Enable the Solr integration in the Drupal Platform, and set a version (e.g. Solr version `9.2`, including minor):

```bash
make service-solr
```

3. Add a server in the administration backend of the Drupal Search API module (`/admin/config/search/search-api/add-server`). Use `solr` as server (and system) name, as well as host. Use `site_search` as Solr core name.

4. Download the core configuration and add it to the project repository (e.g. including major version `9.2`):

```bash
ddev drush solr-gsc solr config.zip 9.2
unzip ./app/public/config.zip -d ./solr/site_search/conf
rm ./app/public/config.zip
ddev composer project:scaffold
```

5. Make sure to restart DDEV. This will create the core as configured.

```bash
ddev restart
```

You should now have a running Solr service with a core created from the configuration in the `solr` directory. Follow the Search API module's documentation on how to create indexes.
