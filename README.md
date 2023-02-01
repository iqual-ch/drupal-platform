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
* Runtime configuration
  * `runtime.base_image`: Base docker image for the Drupal container
  * `runtime.base_image_tag`: Base docker image tag for the Drupal container
  * `runtime.db_image`: Database docker image
  * `runtime.db_image_tag`: Database docker image tag
  * `runtime.php_version`: PHP version of the platform (e.g. `8.2`)
  * `runtime.db_version`: Database version of the platform (e.g. `10.6`)
  * `runtime.php_memory_limit`: PHP memory limit (e.g. `256M`)
* CI/CD workflow settings
  * `workflows.update`: Enable/Add the Drupal update workflow
  * `workflows.vrt`: Enable/Add the visual regression testing workflow
* `local_domain_suffix`: The domain suffix for local development
* Development setup (`development` array)
  * `devcontainer-docker-compose`: Local dev environment with docker-compose and devcontainers
* `deployment`: Deployment integration type
* Kubernetes contexts
  * `kubernetes_contexts.dev`: Kubernetes development cluster context
  * `kubernetes_contexts.stage`: Kubernetes staging cluster context
  * `kubernetes_contexts.prod`: Kubernetes production cluster context

## Managed Assets

List of files that are going to be managed in the destination project by this package:

### Added Assets

Assets that are only added if it doesn't exist in the target yet:

```
assets/add/
└── @web-root
    └── sites
        └── default
            ├── all.settings.php
            ├── local.services.yml
            └── local.settings.php.twig
```

### Replaced Assets

Assets that are fully managed by the package and will be created if inexistant or otherwise overwritten in the target destination:

```
assets/replace/
├── .devcontainer
│   └── devcontainer.json
├── .github
│   ├── actions
│   │   └── install-local
│   │       └── action.yml.twig
│   └── workflows
│       ├── update.yml.twig
│       └── visual-regression-testing.yml.twig
├── .vscode
│   ├── launch.json
│   └── settings.json.twig
├── @app-root
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
└── manifests
    └── local
        └── docker-compose.yml.twig
```

### Merged Assets

Assets that will be merged into existing destination files or added if inexstistant:

```
assets/merge/
├── .dockerignore
├── .env.twig
├── .env.visreg.twig
├── .gitattributes
└── .gitignore.twig
```

## Documentation

_WIP_
