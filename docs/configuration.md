# Configuration

The project setup allows a lot of customization using multiple configuration options. The runtime and Drupal environment can be modified for project needs, even on a per-environment basis.

## Drupal Platform Package Variables

Assets and configuration managed by the Drupal Platform has to be customized using the available package variables. These can be set in the `composer.json`'s `extra.project-scaffold` section. To apply the changes run `composer project:scaffold`. By default the package will only prompt for the required variables (marked with a [`*`]) and vanity variables (market with a [`~`]) on initial installation of the package, during an update or when executing `composer project:update`.

<details>
<summary>List of available package variables</summary>
<br>

* `project_name`: Optional override for default project name (i.e. `{{name}}-sw-project`)
* `name` [`*`]: Code name of the project (e.g. `iqual`)
* `title` [`~`]: Title of the project (e.g. `iqual AG`)
* `url` [`*`]: URL to the current remote live deployment (e.g. `https://www.iqual.ch`)
* `drupal_spot` [`*`]: The drupal single point of truth for asset synchronization
  * Kubernetes: name of the target environment, e.g. `prod`
  * Platform.sh: machine name of the main project branch, e.g. `main-123`
* Runtime configuration
  * `runtime.base_image`: Base docker image for the Drupal container
  * `runtime.base_image_tag`: Base docker image tag for the Drupal container
  * `runtime.db_image`: Database docker image
  * `runtime.db_image_tag`: Database docker image tag
  * `runtime.php_version` [`*`]: PHP version of the platform (e.g. `8.2`)
  * `runtime.db_version` [`*`]: Database version of the platform (e.g. `10.6`)
  * `runtime.php_memory_limit`: PHP memory limit (e.g. `256M`)
  * `runtime.php_upload_limit`: PHP upload limit (e.g. `100M`)
* CI/CD workflow settings
  * `workflows.update`: Enable/Add the Drupal update workflow
  * `workflows.upgrade`: Enable/Add the Drupal upgrade workflow
  * `workflows.vrt`: Enable/Add the visual regression testing workflow
* `local_domain_suffix`: The domain suffix for local development
* Development setup (`development` array)
  * `devcontainer-docker-compose`: Local dev environment with docker-compose and devcontainers
* `deployment`: Deployment integration type, see [available remote deployment options](./deployment.md#remote-deployment)
* Kubernetes contexts
  * `kubernetes_contexts.dev`: Kubernetes development cluster context
  * `kubernetes_contexts.stage`: Kubernetes staging cluster context
  * `kubernetes_contexts.prod`: Kubernetes production cluster context
* Platform.sh config
  * `platformsh_config.region`: Deployment region (e.g. `de-2`)
  * `platformsh_config.project_id`: ID of the project

</details>

## Environment

### Environment files in repository

The general project environment variables are stored in the `.env` file in the root of the project. These variables will be loaded and available for the runtime and CLI and will also be available for the Drupal website (i.e. `php-fpm`).

It contains general configuration like the name of the project but also the SSH proxy endpoint and Kubernetes contexts for remote `drush` commands. Additionally this is where the single point of truth is defined (i.e. `DRUPAL_SPOT`). This is used for automatic database synchronization on non-production deployments without a database (i.e. `make db-sync`). These variables are managed by the Drupal Platform and should not be modified manually. However additional variables are allowed.

The second environment file `.env.local` should not be modified since it is generated dynamically and is consumed by the `local` environment.

### Environment variables in deployment manifest

Additionally to the environment file there are environment variables defined in the deployment manifests (e.g. `docker-compose.yml`). The environment variables in the manifests should not be modified manually since they are managed by the Drupal Platform. Use environment and secret files instead.

## Secrets

Local deployment secrets can be stored in a `.env.secrets` file in the root of the project. The file is git-ignored but will be created on environment creation. This can be useful for storing sensitive API credentials as environment variables that can be loaded into the config in a settings file in Drupal (see Credentials in Config section).

Remote deployment secrets can be injected from Kubernetes Secrets as environment variables.

### SSH Authentication

For `git` authentication and SSH proxy access (e.g. `drush` remote commands) a SSH authentication mechanism has to be provided. This can either be done using VS Code's `ssh-agent` integration or by using the `SSH_KEY` environment variable (e.g. in `.env.secrets`). Check the [Drupal Image environment variable documentation](https://github.com/iqual-ch/dc-drupal/blob/main/docs/environment-variables.md) for more information.

### Composer Authentication

Composer will prompt for authentication if necesseary and when the CLI is in interactive mode. Alternatively the `COMPOSER_AUTH` environment variable can be used (e.g. in `.env.secrets`).

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

So for example for configuring `local` environments, settings can be added to the `local.settings.php` file. For sensitive settings or configuration that should only apply to your local copy of the environment use the `settings.local.php` file.

#### Platform.sh Environment Type

For Platform.sh deployments the environment type (`$PLATFORM_ENVIRONMENT_TYPE`) is mapped to the following Drupal environment (`$DRUPAL_ENVIRONMENT`) equivalents:

* `production`: `prod`
* `staging`: `stage`
* `development`: `dev`

Therefore the Platform.sh environment type `production` will still include the `prod.settings.php` settings file.

### Credentials in Config

Credentials or other sensitive information should not be committed to the project's repository. Instead placeholders should be used in the config and the the config options should then be overriden in a settings file. The settings file can contain the sensitive information if it is git-ignored (i.e. `settings.local.php`) or load the data from an environment variables (e.g. stored in `.env.secrets`).

For example, if you want to store the API key and webhook hash of the Mailchimp module in an environemt variable, you can add the following to the `all.settings.php` (applying to all environments, and committed):

```php
$config['mailchimp.settings'] = [
    "api_key" => (getenv('MAILCHIMP_API_KEY') ?: ""),
    "webhook_hash" => (getenv('MAILCHIMP_WEBHOOK_HASH') ?: ""),
];
```

Then the `MAILCHIMP_API_KEY` and `MAILCHIMP_WEBHOOK_HASH` can be set in the environemnt using the `.env.secrets` file. Alternatively it is still possible to override the variables directly in the `settings.local.php` file.

For more advanced setups use a key management module.

#### Credentials on Platform.sh

Platform.sh allows adding variables to [projects](https://docs.platform.sh/development/variables/set-variables.html#create-project-variables) and [specific environments](https://docs.platform.sh/development/variables/set-variables.html#create-environment-specific-variables). This enables adding sensitive credentials directly for projects or environments. By using specific variable keys, it is also possible to directly override drupal settings or configuration.

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