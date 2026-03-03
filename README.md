# iqual Drupal Platform

This package contains assets for scaffolding configuration files in a Drupal project. It is an "asset package" for the [iqual/project-scaffold](https://github.com/iqual-ch/project-scaffold) Composer plugin that can create new or updating existing projects with pre-defined assets.

The bundled assets are for the iqual internal developer platform's Drupal integration. It supports a DDEV setup using VS Code as IDE. Additionally it contains integrations for a remote deployment to Upsun (formerly Platform.sh) and CI/CD workflows for automation using GitHub Actions.

## Platform Features

* Local development environment with **DDEV**
* **VS Code** IDE setup
* Workflows for Drupal automation using **GitHub Actions**
* Integration for deployment to **Upsun** (formerly Platform.sh)
* `Makefile` **commands** for project and app tasks

## Quick Start

Make sure to set up the [iqual/project-scaffold](https://github.com/iqual-ch/project-scaffold) Composer plugin first:
```bash
composer config --no-plugins allow-plugins.iqual/project-scaffold
composer config extra.project-scaffold --json {"allowed-packages":["iqual/drupal-platform"]}
composer require iqual/project-scaffold
```

Install the asset package, using:

```bash
composer require iqual/drupal-platform
```

## Package Variables

During scaffolding it will prompt for package variables that are used when the files are being templated:

* `name`: Code name of the project (e.g. `iqual`)
* `title`: Title of the project (e.g. `iqual AG`)
* `url`: URL to the current remote live deployment (e.g. `https://www.iqual.ch`)
* `drupal_spot`: The drupal single point of truth for asset synchronization (e.g. `main-bvxea6i`)
* `runtime.php_version`: PHP version of the platform (e.g. `8.3`)
* `runtime.db_version`: Database version of the platform (e.g. `10.6`)
* `deployment`: Remote deployment integration (e.g. `platform.sh`)

> Check the documentation for a [full list of the Drupal Platform's available package variables](./docs/configuration.md#drupal-platform-package-variables).

## Managed Assets

List of files that are going to be managed in the destination project by this package.

### Added Assets

Assets that are only added if it doesn't exist in the target yet:

<details>
<summary>Show structure of added assets</summary>
<br>

```
assets/add/
├── .platform
│   └── routes.yaml.twig
└── @web-root
    └── sites
        └── default
            ├── all.settings.php
            ├── local.services.yml
            └── local.settings.php.twig
```

</details>

### Replaced Assets

Assets that are fully managed by the package and will be created if inexistent or otherwise overwritten in the target destination:

<details>
<summary>Show structure of replaced assets</summary>
<br>

```
assets/replace/
├── @app-root
│   ├── .environment.twig
│   ├── drush
│   │   ├── drush.yml
│   │   ├── platformsh_generate_drush_yml.php.twig
│   │   └── sites
│   │       └── self.site.yml.twig
│   ├── php.ini.twig
│   ├── phpcs.xml.dist
│   ├── phpstan.neon
│   ├── phpunit.xml.dist
│   └── resources
│       ├── build.sh.twig
│       ├── deploy.sh.twig
│       └── robots.txt.twig
├── .ddev
│   ├── .env.solr.twig
│   ├── commands
│   │   └── web
│   │       ├── lint
│   │       ├── phpcbf
│   │       ├── phpcs
│   │       ├── phpstan
│   │       └── phpunit
│   ├── config.solr.yaml.twig
│   ├── config.yaml.twig
│   ├── docker-compose.solr.yaml.twig
│   ├── homeadditions
│   │   └── .bash_aliases.twig
│   └── php
│       └── my-php.ini.twig
├── .editorconfig
├── .github
│   ├── actions
│   │   ├── install-local
│   │   │   └── action.yml.twig
│   │   └── upgrade
│   │       ├── rector.php
│   │       └── upgrader.sh
│   └── workflows
│       ├── config-pull.yml.twig
│       ├── phpcs.yml.twig
│       ├── phpunit-functional-testing.yml.twig
│       ├── phpunit-unit-testing.yml.twig
│       ├── testing.yml.twig
│       ├── update.yml.twig
│       ├── upgrade.yml.twig
│       └── visual-regression-testing.yml.twig
├── Makefile
├── README.md.twig
├── solr
│   └── site_search
│       └── conf
│           └── README.md.twig
├── .vscode
│   ├── extensions.json
│   ├── launch.json
│   ├── settings.json.twig
│   └── tasks.json
└── @web-root
    └── sites
        └── default
            ├── settings.php
            └── settings.platformsh.php.twig
```

</details>

> [!WARNING]
> These files should not be modified in a project anymore, since they will be overwritten by this package.

### Merged Assets

Assets that will be merged into existing destination files or added if inexistent:

<details>
<summary>Show structure of merged assets</summary>
<br>

```
assets/merge/
├── .dockerignore
├── .env.twig
├── .env.visreg.twig
├── .gitattributes
├── .gitignore.twig
├── .platform
│   └── services.yaml.twig
├── .platform.app.yaml.twig
└── playwright-vrt.config.json.twig
```

</details>

## Documentation

* Guides
  * [Step-by-step initial setup](https://support-iqual.atlassian.net/wiki/spaces/BW/pages/3260579957/Initial+setup+G)
  * [DDEV Installation](https://docs.ddev.com/en/stable/users/install/ddev-installation/)
* Drupal Platform
  * [Concepts](./docs/concepts.md)
  * [Configuration](./docs/configuration.md)
  * [Commands](./docs/commands.md)
  * [Repository Structure](./docs/structure.md)
  * [Drupal Development](./docs/drupal-development.md)
  * [Service Deployment](./docs/deployment.md)
  * [App Installation](./docs/installation.md)
  * [Automation (CI/CD)](./docs/automation.md)
* DDEV
  * [DDEV Usage](https://docs.ddev.com/en/stable/users/usage/)
  * [DDEV Configuration](https://docs.ddev.com/en/stable/users/configuration/config/)
  * [DDEV Debugging](https://docs.ddev.com/en/stable/users/debugging-profiling/step-debugging/)
