# Project Structure

The project is structured according to the following top-level layout:

```
.
├── Makefile                    # Make targets
├── .devcontainer               # VS Code development container
├── .github                     # GitHub Actions Workflows
├── .vscode                     # VS Code config
├── app                         # Drupal app directory
└── manifests                   # Deployment manifests
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
└── manifests
    └── local                   # Local deployment manifest (compose)
```


## Automation workflows (CI/CD)

The `.github` directory contains the GitHub Actions workflows for continous integration and delivery functionality. See the [automation documentation](./automation.md) for more information.


```
.github/                               # GitHub Actions Workflows
├── actions
│   └── install-local
│       └── action.yml                 # Composite action for installing Drupal
├── workflows
│   ├── update.yml                     # Automated Drupal Update
│   └── visual-regression-testing.yml  # Automated VRT
└── ...
```