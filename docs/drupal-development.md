# Drupal Development

[Check the in-depth step-by-step guide on the initial setup](https://support-iqual.atlassian.net/wiki/spaces/BW/pages/3260579957/Initial+setup+G)

## Requirements

* **GNU/Linux environment** (or macOS)
    * Windows: WSL2 is required
* **Docker** installed
* **DDEV** installed ([Installation guide](https://ddev.readthedocs.io/en/stable/users/install/ddev-installation/))
* **GitHub access**
    * SSH authentication with private key
    * SSH key registered in DDEV: `ddev auth ssh`
* **Visual Studio Code** (recommended)

## Workflow

The development workflow is based on the GitHub flow, where features and bugfixes are developed in branches, merged into main via pull request and main is deployed to the currently active environment (e.g. production). Main should always be in a deployable state.

See the [Git Workflow guide](https://support-iqual.atlassian.net/wiki/spaces/ID/pages/2990080011/GIT+workflow+G) for an in-depth documentation on the development git workflow.

## Developing Locally

The recommended development approach is to `git clone` (with SSH) the repository to a local environment and to use DDEV with Visual Studio Code for a fully featured Drupal developer experience.

### Quick Start

1. Clone the repository and navigate to the project root.
2. Run `make install` to start the DDEV runtime, build and deploy Drupal.
3. Run `make launch` to open the project in your browser or `make login` for a one-time login.

### Development with Visual Studio Code

The project repository contains `.vscode` configuration for development using Visual Studio Code, including recommended extensions, editor settings, debug configurations and tasks.

To launch VS Code:

```bash
make code
```

VS Code includes pre-configured tasks (accessible via the Command Palette or `Ctrl+Shift+P`) for common operations like installing the project, building Drupal (`Ctrl+Shift+B`), running tests and toggling XDebug. See the [commands documentation](./commands.md) for all available `make` targets.

> [!TIP]
> VS Code's PHP language support is provided by [Intelephense](https://marketplace.visualstudio.com/items?itemName=bmewburn.vscode-intelephense-client). PHPCS and PHPCBF are integrated for real-time linting and auto-fixing. DDEV shim binaries in the `bin/` directory allow VS Code extensions to transparently call tools inside the DDEV container.

### Development with Other IDEs

Other IDEs can be used by running `make install` to start the DDEV environment and then using the IDE on the project folder. DDEV commands (e.g. `ddev drush`, `ddev composer`) can be used from the host.

## XDebug

XDebug is available but disabled by default for performance. The VS Code setup includes an XDebug launch configuration that will automatically enable and disable XDebug when starting and stopping a debug session.

Check the [official XDebug documentation](https://xdebug.org/docs/) for more advanced configuration.

### Enabling and Disabling XDebug

VS Code will automatically toggle XDebug when using the debug launch configuration (`F5`). XDebug can also be manually toggled:

```bash
ddev xdebug on
ddev xdebug off
```

## PHP Profiling

See the official DDEV docuemtnation for PHP profiling:

* [XHProf Profiling](https://docs.ddev.com/en/stable/users/debugging-profiling/xhprof-profiling/)
* [XDebug Profiling](https://docs.ddev.com/en/stable/users/debugging-profiling/xdebug-profiling/)

## PHPUnit

For running the project specific PHPUnit tests, there are multiple available commands. See the [commands documentation](./commands.md#testing) for a full list.

* `make drupal-test-unit`: Run the unit testsuite
* `make drupal-test-func`: Run functional tests (unit, kernel, functional, functional-javascript)
* `make drupal-test-db`: Run database tests (kernel, functional, existingsite) — _Warning: can modify your DB_
* `make drupal-test-browser`: Run browser tests (requires [Chrome tool](#chrome)) — _Warning: can modify your DB_

It is also possible to run PHPUnit directly using `ddev`, for example running the unit test from the root of the project:

```bash
ddev phpunit -c ./app --testsuite=unit
```

> `phpunit` and Drupal Testing Traits (DTT) have to be required in the project. Javascript tests also require a browser, see [Chrome tool](#chrome).

### Multi-Domain Testing

By default there is a wildcard subdomain available for the primary DDEV hostname (e.g. `*.foo.ddev.site` for the `foo` project). So sites can be tested against different hostnames. If required it is also posibble to add custom `.ddev.site` domains, by adding a `.ddev/config.custom.yaml` with custom `additional_hostnames` (see [additional project hostnames docs on DDEV](https://docs.ddev.com/en/stable/users/extend/additional-hostnames/)).


## PHPCS

For code sniffing there is a make target that runs PHPCS according to the Drupal standard on custom themes and modules: `make drupal-lint`. To run validation, linting, and static analysis together use `make lint`.

> `phpcs` has to be required in the project, including the Drupal and DrupalPractice standards.

## PHPStan

Static analysis is available via PHPStan. Run `make drupal-analysis` to analyse custom themes and modules. The configuration is defined in `app/phpstan.neon`.

## Email

The Mailpit integration of DDEV is enabled by default and automatically catches all emails, if the `sendmail` configuration of the Symfony Mailer is active (for local). See the [email capture and review documentation](https://docs.ddev.com/en/stable/users/usage/developer-tools/#email-capture-and-review-mailpit) of DDEV.

## Database Administration

DDEV includes built-in database management. Use `ddev describe` to see the database connection details. The recommended VS Code extension [DevDB](https://marketplace.visualstudio.com/items?itemName=damms005.devdb) is included in the recommended extensions for database administration directly in VS Code.

## Database Snapshots

DDEV supports database snapshots for quickly saving and restoring database states:

```bash
ddev snapshot --name my-snapshot     # Create a named snapshot
ddev snapshot restore --latest       # Restore the latest snapshot
ddev snapshot restore my-snapshot    # Restore a named snapshot
```

Snapshots can also be used during installation:

```bash
make install DDEV_SNAPSHOT=latest
```

## External Tools

### Chrome

The browser Chrome is available as a DDEV add-on for PHPUnit browser testing. It can be installed using:

```bash
make tool-chrome
```

To remove it, use `make tool-chrome REMOVE=true`. Chrome is required for running `make drupal-test-browser`.
