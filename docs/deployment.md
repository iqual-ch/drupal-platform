# Service Deployment

A service deployment sets up the app's runtime environment (e.g. PHP, database, etc.). After deploying the services the app needs to be installed to complete a full deployment. See the [App Installation documentation](./installation.md) for the latter.

## Local Deployment (DDEV)

The local development environment is powered by [DDEV](https://ddev.com/). To start the local environment run `make runtime` (or `ddev start`). This will start all required services for the project's Drupal environment.

To fully install the project (runtime + Drupal), run `make install`.

### Services

* **Web container** (DDEV web)
    * PHP-FPM
    * Nginx
    * Composer, Drush, Node.js (via Corepack)
* **MariaDB database container**
* **Solr search API container** (optional, see [Solr configuration](./configuration.md#solr))

## Remote Deployment

Currently there are two remote deployment options available:

* **Upsun** (formerly Platform.sh): `platform.sh`
* **No remote deployment**: `local-only`

The deployment option is set via the `deployment` package variable in the `composer.json`'s `extra.project-scaffold` section.

### Upsun Deployment

> The Upsun (formerly Platform.sh) integration requires the `platformsh/config-reader` package. This needs to be required in the project.

The project can be deployed to [Upsun](https://upsun.com/) (formerly Platform.sh). In this case a `project_id` is required, as well as setting the `drupal_spot` to the machine name of the main, production branch of the Upsun project (i.e. `platform environment:info machine_name`).

> [!INFO]
> To enable auto-deployment when changes are pushed to the repository make sure to set up the [GitHub source integration](https://fixed.docs.upsun.com/integrations/source/github.html) on the Upsun project.

#### Customization

The `platform.app.yaml` configuration file can be customized, e.g. to add cronjobs or increase disk size. For a go-live the `routes.yaml` in the `.platform` folder can be modified, to e.g. add redirects or customize the `www` handling.


#### Multi-Domain Setup

##### Routing

For multi-domain setups the additional domains need to defined in the `.platform/routes.yaml` file. To enable automatic hostname overrides for development environments a `domain.record` can be set in the `attributes` section of the corresponding route. This will be automatically converted into a configuration override in the `settings.platformsh.php` when on a non-production branch.

Example route for an additional domain `www.example.ch` that will override the `hostname` in the `domain.record.example_ch` config to `www.example.ch`:

```yaml
"https://www.example.ch/":
    type: upstream
    upstream: "drupal:http"
    cache:
      enabled: true
      cookies: ['/^SS?ESS/', '/^Drupal.visitor/']
    tls:
      strict_transport_security:
          enabled: true
          include_subdomains: true
          preload: true
    attributes:
      "domain.record": "example_ch"
```

> Make sure to also add the respective domain record attributes to the default route.

##### Robots.txt

If the `robots.txt` should be routed through PHP/Drupal then the drupal scaffold's file mapping for the `robots.txt` file has to be disabled and then the file has to be removed from the repository. This is usually required in a multi-domain setup, as there should be different versions of the `robots.txt` per domain.

For example the drupal scaffold file mapping in the `composer.json` could look like this:

```json
    "drupal-scaffold": {
        "locations": {
            "project-root": ".",
            "web-root": "public"
        },
        "file-mapping": {
            "[web-root]/robots.txt": false
        }
    },
```

#### Auto-Deployment

Drupal will be built and deployed automatically by default on Upsun. This includes running database updates, config imports and cache rebuilds (i.e. `drush deploy`) as well as copying repository assets (e.g. `fontyourface` fonts). On deployment the state from the repository will be deployed. Config changes will be overridden.

> If this is not the desired behavior, set the `DRUPAL_NO_DEPLOY` environment variable in Upsun (env/project) so the deployment script doesn't run. If only `drush deploy` should be disabled, use `DRUPAL_NO_DRUSH_DEPLOY`. This can be helpful for restoring backups or automation. There is also an option for manual deployments on Upsun, if a push to the repository should automatically deploy.
