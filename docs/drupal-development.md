# Drupal Development

[Check the in-depth step-by-step guide on the initial setup](https://support-iqual.atlassian.net/wiki/spaces/ID/pages/2532704262/Initial+setup+G)

## Requirements

* GNU/Linux environment
    * Recommendation: Ubuntu 20.04/22.04 (WSL2 for Windows)
    * `ssh`, `socat`, `git`, `make` installed
    * Mac OS X support is limited
* GitHub access
    * SSH authentication with private key
    * Key added to the `ssh-agent`
* Docker installed
    * Authenticated to iqual Docker registry
    * iqual reverse proxy installed
* Visual Studio Code
    * Remote-Containers
    * Remote-WSL (Windows)


## Workflow

To start developing a project's a repository can either be cloned to work on locally, or a remote Codespace can be launched. The development workflow is based on the GitHub flow, where features and bugfixes are developed in branches, merged into main via PR and main is deployed to the currently active environment (e.g. production). Main should always be in a deployable state.

See the [Git Workflow guide](https://support-iqual.atlassian.net/wiki/spaces/ID/pages/2990080011/GIT+workflow+G) for an in-depth documentation on the development git workflow.

## Developing locally

The recommended development approach is to `git` clone (with SSH) the repository to a local GNU/Linux environment and to launch Visual Studio Code for a fully featured Drupal developer experience.

### Development with Visual Studio Code

The project repository contains a `.devcontainer`, `.vscode` and depending on the setup a workspace configuration for development using Visual Studio Code.

When starting VS Code with `make code` (or `code .`) within the project repository it will automatically prepare the local environment and deploy it. Once the container start-up has succeeded VS Code will install itself inside of the container and use the `Remote Containers` feature to communicate with the window on the desktop. It also makes sure that the SSH authentication provided in the linux environment through the `ssh-agent` is propagated to the container.

After VS Code completed its installation it will execute `make project` within the container to automatically set-up the Drupal project. This command will try to install all vendor packages using `composer`, sync the database and filesystem from the single point of truth using `drush`, run database updates and import the config with a `drush deploy`.

The start-up might soft-fail due to multiple reasons, since it tries to automatically set-up the desired environment but aborts if anomalies are detected. Check the [project commands](./commands.md) and [project concepts](./concepts.md) documentation for further explanations on how these commands work.

### Development with other IDEs

Other IDEs apart from Visual Studio Code are currently not actively supported. However it is possible to only deploy the local environment (with `make deploy-local`) and then use a different code editor on the project workfolder. In order to use `git` and remote `drush` commands within the environment SSH credentials need to be provided.

## Developing remotely

Alternatively to local development there is the option to run a development environment with a code editor remotely. This can be useful for quick access to a new environment without requring local compute resources.

### Development on GitHub Codespaces

Currently the only supported remote development environment is GitHub Codespaces. This basically provides a hosted solution to the Visual Studio Code editor setup. The same launch operations are executed on GitHub Codespaces as on a local VS Code setup. It can be directly launched on a GitHub repository in the "Code" dropdown at the top (feature has to be enabled by administrator).

In order for GitHub Codespaces to work a few environment variables are needed for proper authentication:

* `DOCKERHUB_CONTAINER_REGISTRY_USER`: The Docker Hub container registry user to access the private container images (read access)
* `DOCKERHUB_CONTAINER_REGISTRY_PASSWORD`: The Docker Hub container registry password to access the private container images (read access)
* `DOCKERHUB_CONTAINER_REGISTRY_SERVER`: The Docker Hub container registry server, i.e. `https://index.docker.io/v1/`
* `SSH_KEY`: A private SSH key for drush remote access. The public key has to be added to the SSH-to-kubectl proxy
* `COMPOSER_AUTH`: (Optional) The composer authentication string for access to a private packagist repo
    * e.g. `{\"http-basic\":{\"repo.packagist.com\":{\"username\":\"USER\",\"password\":\"TOKEN\"}}}`

## XDebug

XDebug is disabled by default in the image for debugging PHP (`trigger` mode). The VS Code setup includes the XDebug debugger for adding break-points. It will automatically enable XDebug once a debugging session is launched (i.e. when pressing F5) by running the `xdebug` `make` target as a background task.

Check the [official XDebug documentation](https://xdebug.org/docs/) for further more advanced documentation.

Below are some common configurations for XDebug. To add a environment variable it can be added as a separate line in `.env.secrets`. Whenever a environment variable is changed the deployment has to re-deployed. In the case of VS Code this can be simply done by doing a `Rebuild Container`.

### Enabling and Disabling XDebug

VS Code will automatically enable XDebug when a debugging session is started. However XDebug can also be manually enabled by running the `make xdebug` target. For disabling there is a `make xdebug-disable` target.

```bash
make xdebug
```

To completely disable XDebug it can also be turned off by setting the following environment variable:

```bash
XDEBUG_MODE=off
```

### PHP Profiling

A useful tool for identifing performance bottlenecks is the profiling mode of XDebug. To switch XDebug into profiling mode, a few configuration changes need to take place. The mode has to be set to `profile` and a sensible `output_dir` should be defined. The following configuration generates a `cachegrind` file in the root of the project.

```bash
XDEBUG_MODE=profile
XDEBUG_CONFIG="output_dir=/project"
```

The profiler can then be triggered by either enabling xdebug with `make xdebug` or by using the trigger variable `XDEBUG_TRIGGER` (in `ENV`, `GET` or `COOKIE`). For example to profile a drush command `XDEBUG_TRIGGER= drush status` can be run.

To analyze the generated `cachegrind` files there are a few available tools. Check the [profiling documentation on the official XDebug page](https://xdebug.org/docs/profiler). For a very simple overview it is possible to use [Webgrind](https://github.com/jokkedk/webgrind) to display a weighted table or graph of the called function.

> Make sure to not commit the cachegrind files.

### Using XDebug in a external IDE

If you are trying to reach a non-default debugger outside of the local deployment's network (i.e. VS Code) then it is also possible to set a different client host. The default port ist `9003` ond client host `localhost`. For example to set the client host to the localhost of the host machine the following environment variable can be added to `.env.secrets`:

```bash
XDEBUG_CONFIG="client_host=host.docker.internal"
```

> On Windows (WSL2) you have to use `host.docker.internal` for the localhost, however on Linux you can use `172.17.0.1`.

## PHPUnit

For running the project specific PHPUnit tests, there are multiple avaiable PHPUnit commands. To run simple unit tests, there is `make phpunit` which will only run the unit testsuite defined in the project's `phpunit.xml` (falls back to `phpunit.xml.dist`). There is also the option to run database test including Drupal Testing Traits (DTT) tests, that could modify your database, with `make phpunit-db`. If [Chrome has been launched as an external tool](#chrome), the browser testing can be executed using `make phpunit-browser`. This will also require DTT and could also modify your existing database.

> `phpunit` has to be required in the project, including DTT.

## PHPCS

For code sniffing there is a make target that will run sniffing according to the Drupal standard on the custom themes & modules in the repository called `make phpcs`. To run both PHPCS and some basic PHP linting first, there is also `make lint`.

> `phpcs` has to be required in the project, including the Drupal and DrupalPractice standards.

## Email

For debugging emails it is advised to enable the mailtrap integration. This can either be enabled by using the `EMAIL_MAILTRAP_AUTH` environment variable (see [Drupal image variables](https://github.com/iqual-ch/dc-drupal/blob/main/docs/environment-variables.md)) or by using a SMTP Drupal module and setting the SMTP credentials to Mailtrap.

Using the environment variable, you can add it to the `.env.secrets` like this (replace credentials):

```bash
EMAIL_MAILTRAP_AUTH=INSERT_USERNAME:INSERT_PASSWORD
```

For example using the `swiftmailer` module, the config overrides in the `settings.local.php` should look like this (replace credentials):

```php
$config['swiftmailer.transport']['transport'] = 'smtp';
$config['swiftmailer.transport']['smtp_host'] = 'smtp.mailtrap.io';
$config['swiftmailer.transport']['smtp_port'] = 2525;
$config['swiftmailer.transport']['smtp_encryption'] = 'tls';
$config['swiftmailer.transport']['smtp_credential_provider'] = 'swiftmailer';
$config['swiftmailer.transport']['smtp_credentials']['swiftmailer']['username'] = 'INSERT_USERNAME';
$config['swiftmailer.transport']['smtp_credentials']['swiftmailer']['password'] = 'INSERT_PASSWORD';
```

## Multiple local deployments

It is possible to run multiple environments of the same project in parallel. To enable this, the `project_name` of the project needs to be changed. This variable has to be updated or added in the `extra.project-scaffold` section of the project's `composer.json`. After modifying or adding the variable make sure to run `composer project:scaffold`. Once the change has been applied the container has to be re-opened in VS Code. In this case it possible to have different databases per git branch. For example a project by the name `example-sw-project` can be changed to `example-feature-sw-project` on a `feature-x` branch. In that case the database can be kept completely separate from the main branch.

If multiple environments should be running simultaneously then the repository (i.e. the filesystem/codebase) also has to exist multiple times. This can be achieved by creating a copy of the existing repository or by cloning to a different secondary folder.

> Make sure to not commit a modified `project_name` to main, since the modification is tracked in multiple files and could break other developer's setup.

## Database Administration

For database administration during development there is an included VS Code extension called `SQLTools`. It provides basic capability like viewing tables and running queries on the database directly in the sidebar of VS Code.


## External Tools

### Chrome

The browser Chrome is available as external tool. It can be launched by using `make tool-chrome`. Chrome can be used for local PHPUnit testing that requires a browser.