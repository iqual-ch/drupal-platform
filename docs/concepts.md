# Project Concepts

## Single point of truth

There is always a single point of truth (referred to as "SPOT") for certain elements of the project. In the SPOT the original version of the data is located and all other locations are copies of this controlling (master) version.

There is only one environment that can be the SPOT for non-code data (e.g. `prod`).

### Code

The core codebase's SPOT is the project repository. It contains business logic as custom modules commited to the repository, as well as themes and and configuration. Assets that are part of code dependencies are also co-located in the project repostiory (e.g. stylesheets, assets, etc.).

### Vendor packages

The vendor packages (such as Drupal core, iqual modules or contributed modules) are locked to specific versions using composer in the project repository. The code of the packages is however located in a package repository and tracked in separate code repositories. The code is then downloaded during an installation of Drupal.

### Database & public assets

The SPOT of the database and public asset is always situated on a remote deployment (e.g. `dev`, `stage`, `prod`) unless during the project's initial setup when there is no deployment yet.

## Data synchronization

When running multiple environment (e.g. a `local` environment for development) then data should always be synchronized from the SPOT to these environments too keep up-to-date with the current data.

### Database

The database should always be synchronized from the SPOT if in another environment (e.g. `prod` → `local`). A synchronization will copy the database from the SPOT to the destination environment.

### Filesystem

The filesystem should always be synchronized from the SPOT if in another environment (e.g. `prod` → `local`). A synchronization will either copy the assets from the SPOT to the destination environment or proxy requests from the destination environment to the SPOT environment (e.g. stage file proxy).

### Configuration

The most current configuration should always be committed to the project repositry. If configuration modification is allowed on a live/production deployment make sure to always synchronize the config from this environment back to the repository.