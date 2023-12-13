# Project Structure

The project is structured according to the following top-level layout:

```
.
├── Makefile                    # Make targets
├── .devcontainer               # VS Code development container
├── .github                     # GitHub Actions Workflows
├── .platform                   # Platform.sh configuration (if enabled)
├── .vscode                     # VS Code config
├── app                         # Drupal app directory
├── manifests                   # Deployment manifests
└── solr                        # Solr core configuration (optional)
```

## Drupal app directory

The `app` directory contains everything related to the Drupal website.

```
.
├── ...
├── app
│   ├── composer.json           # Composer config
│   ├── composer.lock           # Composer lock
│   ├── composer.patches.json   # Composer patches
│   ├── config                  # Drupal configuration
│   ├── drush                   # Drush configuration
│   ├── patches                 # Drupal patches
│   ├── private                 # Private Drupal files (ignored)
│   ├── public                  # Public web root
│   │   ├── core                # Drupal core (ignored)
│   │   ├── modules
│   │   │   ├── contrib         # Contributed modules (ignored)
│   │   │   └── custom          # Custom website modules
│   │   ├── profiles            # Drupal installation profiles
│   │   ├── robots.txt          # Public robots.txt (overwritten)
│   │   ├── sites
│   │   │   └── default         # Drupal settings and files
│   │   └── themes
│   │       ├── contrib         # Contributed themes (ignored)
│   │       └── custom          # Custom website theme
│   ├── resources               # Scripts and assets for the app
│   └── vendor                  # Composer vendor packages (ignored)
└── ...

```

## Deployment manifests

The `manifests` directory contains all the definitions for a deployment of a environment. Each environment has its own subdirectory. See the [development](./drupal-development.md) and [deployment](./deployment.md) documentation for more information.

```
.
├── ...
├── .platform                   # Service and route confiugration (Platform.sh)
├── .platform.app.yaml          # Deployment confiugration (Platform.sh)
└── manifests
    ├── dev                     # Remote development deployment patch (Kubernetes)
    ├── stage                   # Remote staging deployment patch (Kubernetes)
    ├── prod                    # Remote production deployment patch (Kubernetes)
    └── local                   # Local deployment manifest (Docker Compose)
```


## Automation workflows (CI/CD)

The `.github` directory contains the GitHub Actions workflows for continous integration and delivery functionality. See the [automation documentation](./automation.md) for more information.


```
.github/                               # GitHub Actions Workflows
├── actions
│   ├── install-local
│   │   └── action.yml                 # Composite action for installing Drupal
│   └── upgrade
│       ├── rector.php                 # Default/fallback rector config for upgrade.sh
│       └── upgrade.sh                 # Composite action for installing Drupal
├── workflows
│   ├── phpcs.yml                      # Automated PHPCS Linting
│   ├── phpunit-functional-testing.yml # Automated PHPUnit Functional Testing
│   ├── phpunit-unit-testing.yml       # Automated PHPUnit Unit Testing
│   ├── testing.yml                    # Automated Drupal Testing
│   ├── update.yml                     # Automated Drupal Update
│   ├── upgrade.yml                    # Automated Drupal Upgrades
│   └── visual-regression-testing.yml  # Automated VRT
└── ...
```