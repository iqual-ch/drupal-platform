# iqual Drupal Platform

This is a project asset composer package to be used with the [iqual/project-scaffold](https://github.com/iqual-ch/project-scaffold) Composer plugin for creating new or updating existing projects with pre-defined assets.

The bundled assets are for the iqual internal developer platform's Drupal integration. It supports a local (and remote) VS Code setup running docker-compose containers, integrations for Drupal deployments on Kubernetes and workflows for automation.

> Disclaimer: This package is not (yet) intended for public usage and depends on iqual's internal developer platform.

## Platform Features

* Local development environment with docker-compose
* VS Code setup with `.devcontainer`
* Workflows for Drupal automation using GitHub Actions
* Kubernetes integration
* Drush configuration for SSH proxy
* `Makefile` commands for project and app tasks

## Package Variables



* `name`: Code name of the project (e.g. `iqual`)
* `title`: Title of the project (e.g. `iqual AG`)
* `url`: URL to the current remote live deployment (e.g. `https://www.iqual.ch`)
* `drupal_spot`: The drupal single point of truth for asset synchronization (e.g. `prod`)
* `runtime.php_version`: PHP version of the platform (e.g. `8.2`)
* `runtime.db_version`: Database version of the platform (e.g. `10.6`)

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
└── @web-root
    └── sites
        └── default
            ├── all.settings.php
            ├── local.services.yml
            └── local.settings.php.twig
```

</details>

### Replaced Assets

Assets that are fully managed by the package and will be created if inexistant or otherwise overwritten in the target destination:

<details>
<summary>Show structure of replaced assets</summary>
<br>

```
assets/replace/
├── .devcontainer
│   └── devcontainer.json
├── .github
│   ├── actions
│   │   ├── install-local
│   │   │   └── action.yml.twig
│   │   └── upgrade
│   │       ├── rector.php
│   │       └── upgrade.sh
│   └── workflows
│       ├── phpcs.yml.twig
│       ├── phpunit-functional-testing.yml.twig
│       ├── phpunit-unit-testing.yml.twig
│       ├── testing.yml.twig
│       ├── upgrade.yml.twig
│       └── visual-regression-testing.yml.twig
├── .vscode
│   ├── launch.json
│   └── settings.json.twig
├── @app-root
│   ├── phpunit.xml.dist.twig
│   ├── drush
│   │   ├── drush.yml
│   │   └── sites
│   │       └── self.site.yml.twig
│   └── resources
│       └── robots.txt.twig
├── @web-root
│   └── sites
│       └── default
│           └── settings.php
├── Makefile
├── README.md.twig
├── manifests
│   ├── dev
│   │   └── patch.yml.twig
│   ├── stage
│   │   └── patch.yml.twig
│   ├── prod
│   │   └── patch.yml.twig
│   └── local
│       └── docker-compose.yml.twig
└── solr
    └── site_search
        └── README.md.twig
```

</details>

### Merged Assets

Assets that will be merged into existing destination files or added if inexstistant:

<details>
<summary>Show structure of merged assets</summary>
<br>

```
assets/merge/
├── .dockerignore
├── .env.twig
├── .env.visreg.twig
├── .gitattributes
└── .gitignore.twig
```

</details>

## Documentation

* Guides
  * [Step-by-step initial setup](https://support-iqual.atlassian.net/wiki/spaces/ID/pages/2532704262/Initial+setup+G)
* Drupal Platform
  * [Concepts](./docs/concepts.md)
  * [Configuration](./docs/configuration.md)
  * [Commands](./docs/commands.md)
  * [Repository Structure](./docs/structure.md)
  * [Drupal Development](./docs/drupal-development.md)
  * [Service Deployment](./docs/deployment.md)
  * [App Installation](./docs/installation.md)
  * [Automation (CI/CD)](./docs/automation.md)
* Docker Images
  * [iqual Drupal Image](https://github.com/iqual-ch/dc-drupal/)
  * [iqual MariaDB Image](https://github.com/iqual-ch/dc-mariadb/)