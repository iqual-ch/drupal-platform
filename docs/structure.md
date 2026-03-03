# Project Structure

The project is structured according to the following top-level layout:

```
.
├── Makefile                    # Make targets
├── .ddev                       # DDEV configuration
├── .github                     # GitHub Actions Workflows
├── .platform                   # Platform.sh / Upsun configuration (if enabled)
├── .vscode                     # VS Code IDE configuration
├── app                         # Drupal app directory
└── solr                        # Solr core configuration (optional)
```

## Drupal App Directory

The `app` directory contains everything related to the Drupal website.

```
.
├── ...
├── app
│   ├── composer.json           # Composer config
│   ├── composer.lock           # Composer lock
│   ├── composer.patches.json   # Composer patches
│   ├── config                  # Drupal configuration
│   ├── drush                   # Drush configuration
│   ├── patches                 # Drupal patches
│   ├── phpcs.xml.dist          # PHPCS configuration
│   ├── phpstan.neon            # PHPStan configuration
│   ├── phpunit.xml.dist        # PHPUnit configuration
│   ├── private                 # Private Drupal files (ignored)
│   ├── public                  # Public web root
│   │   ├── core                # Drupal core (ignored)
│   │   ├── modules
│   │   │   ├── contrib         # Contributed modules (ignored)
│   │   │   └── custom          # Custom website modules
│   │   ├── profiles            # Drupal installation profiles
│   │   ├── robots.txt          # Public robots.txt (overwritten)
│   │   ├── sites
│   │   │   └── default         # Drupal settings and files
│   │   └── themes
│   │       ├── contrib         # Contributed themes (ignored)
│   │       └── custom          # Custom website theme
│   ├── resources               # Scripts and assets for the app
│   └── vendor                  # Composer vendor packages (ignored)
└── ...

```

## DDEV Configuration

The `.ddev` directory contains the configuration for the local development environment using [DDEV](https://ddev.com/).

```
.ddev
├── config.yaml                 # DDEV main configuration file
├── config.solr.yaml            # Solr service configuration (if enabled)
├── commands
│   └── web                     # Custom DDEV commands (phpunit, phpcs, etc.)
├── homeadditions               # Local shell customizations and aliases
└── php                         # PHP configuration overrides
```

> Secrets and SSH keys placed in `.ddev/homeadditions/.ssh` and `.ddev/.env` are git-ignored.

## Deployment Configuration

The `.platform` folder and `.platform.app.yaml` contain the remote deployment configuration for Upsun (formerly Platform.sh) if it is enabled.

```
.
├── ...
├── .platform                   # Service and route configuration (Platform.sh / Upsun)
└── .platform.app.yaml          # Deployment configuration (Platform.sh / Upsun)
```

## VS Code Configuration

The `.vscode` directory contains the IDE configuration for Visual Studio Code.

```
.vscode
├── extensions.json             # Recommended VS Code extensions
├── launch.json                 # Debug configurations (XDebug)
├── settings.json               # Editor and tooling settings
└── tasks.json                  # Build and test tasks
```

## Automation Workflows (CI/CD)

The `.github` directory contains the GitHub Actions workflows for continuous integration and delivery functionality. See the [automation documentation](./automation.md) for more information.


```
.github/                               # GitHub Actions Workflows
├── actions
│   ├── install-local
│   │   └── action.yml                 # Composite action for installing Drupal with DDEV
│   └── upgrade
│       ├── rector.php                 # Default/fallback rector config for upgrader.sh
│       └── upgrader.sh                # Upgrade operations script
├── workflows
│   ├── config-pull.yml                # Automated Config Pull from remote
│   ├── phpcs.yml                      # Automated PHPCS Linting
│   ├── phpunit-functional-testing.yml # Automated PHPUnit Functional Testing
│   ├── phpunit-unit-testing.yml       # Automated PHPUnit Unit Testing
│   ├── testing.yml                    # Automated Drupal Testing
│   ├── update.yml                     # Automated Drupal Update
│   ├── upgrade.yml                    # Automated Drupal Upgrades
│   └── visual-regression-testing.yml  # Automated VRT
├── playwright-vrt.config.json         # VRT configuration
└── ...
```
