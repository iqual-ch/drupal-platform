# Service Deployment

A service deployment sets up the app's runtime environment (e.g. PHP, Nginx, etc.). After deploying the services the app needs to be installed to complete a full deployment. See the [App Installation documentation](./installation.md) for the latter.

## Requirements

The deployment environments generally require a GNU/Linux environment with Docker installed. Authentication to the Docker hub has to be provided in order to retrieve the iqual Docker images from the private image registry.

There are three deployment types available: Docker Compose, Kubernetes and Platform.sh. Locally and for automation a Docker Compose deployment provides all services required for the project's Drupal environment. Remotely the project is deployed to either a Kubernetes cluster which is managed by the operations team or to managed service by Platform.sh.

The deployment definitions/manifests are kept in the projects repository in the `./manifests` folder for Docker Compose and Kubernetes. Platform.sh confiugration is in the `.platform.app.yaml` file and `.platform` folder.

## Local deployment (Docker Compose)

To deploy the local environment run `make deploy-local`. The command will look for the `docker-compose.yml` file in the `./manifests/local` folder and make sure that the environment is correctly set-up before deploying locally.

### Services

* Drupal container
    * PHP-FPM
    * PHP CLI
    * Nginx
* MariaDB database container
* Solr search API container (Optional)

## Remote Deployment

Currently there are two remote deployment options available, additionally to not deploying to remote at all. The deployment options are:

* Kubernetes: `kubernetes`
* Platform.sh: `platform.sh`
* No deployment: `local-only`

### Kubernetes Deployment

The default remote deployment into a Kubernetes cluster is currently done using Rancher/Helm. See the [prod deployment](https://support-iqual.atlassian.net/wiki/spaces/ID/pages/1864073238/Prod-Instance+Rancher) and [dev/staging deployment guide](https://support-iqual.atlassian.net/wiki/spaces/ID/pages/1863942165/Dev-Instance+Staging+Rancher) for more details.

#### Patching existing deployments

A patch to an existing deployment can be applied using the `make deploy-%` targets (e.g. `make deploy-prod` for a production patch). The patch includes the currently set image and environment variables (`DRUPAL_ENVIRONMENT` and optionally PHP configuration variables).

> The command will re-deploy existing pods and wait for a successful roll-out.

#### Non-default Kubernetes contexts

If a project is being deployed into a non-default cluster context, then the context variable has to be overriden. The default contexts can be found in the `kubernetes_contexts` variables in the [`composer.json`](../composer.json).

For example if the `prod` Kubernetes cluster context ist `example-cluster-1` then the `kubernetes_contexts.prod` has to be set to that value in the `composer.json`'s `extra.project-scaffold` section.

### Platform.sh Deployment

> The Platform.sh integration requires the `platformsh/config-reader` package. This needs to be required in the project.

Alternatively to the deployment into Kubernetes there is also the option to deploy the repository to [Platform.sh](https://platform.sh/). In this case a `project_id` is required, as well as setting the `drupal_spot` to the machine name of the main, production branch of the Platform.sh project (i.e. `platform environment:info machine_name`).


#### Customization

The `platform.app.yaml` configuration file can be customized, e.g. to add cronjobs or increase disk size. For a go-live the `routes.yaml` in the `.platform` folder can be modified, to e.g. add redirects or customize the `www` handling.


#### Multi-Domain Setup

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