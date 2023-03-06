# Service Deployment

A service deployment sets up the app's runtime environment (e.g. PHP, Nginx, etc.). After deploying the services the app needs to be installed to complete a full deployment. See the [App Installation documentation](./installation.md) for the latter.

## Requirements

The deployment environments generally require a GNU/Linux environment with Docker installed. Authentication to the Docker hub has to be provided in order to retrieve the iqual Docker images from the private image registry.

There are two deployment types available: Docker Compose and Kubernetes. Locally and for automation a Docker Compose deployment provides all services required for the project's Drupal environment. Remotely the project is deployed to a Kubernetes cluster which is managed by the operations team.

The deployment definitions/manifests are kept in the projects repository in the `./manifests` folder.

## Local deployment (Docker Compose)

To deploy the local environment run `make deploy-local`. The command will look for the `docker-compose.yml` file in the `./manifests/local` folder and make sure that the environment is correctly set-up before deploying locally.

### Services

* Drupal container
    * PHP-FPM
    * PHP CLI
    * Nginx
* MariaDB database container

## Remote Deployment (Kubernetes)

The remote deployment into a Kubernetes cluster is currently done using Rancher/Helm. See the [prod deployment](https://support-iqual.atlassian.net/wiki/spaces/ID/pages/1864073238/Prod-Instance+Rancher) and [dev/staging deployment guide](https://support-iqual.atlassian.net/wiki/spaces/ID/pages/1863942165/Dev-Instance+Staging+Rancher) for more details.

### Non-default Kubernetes contexts

If a project is being deployed into a non-default cluster context, then the context variable has to be overriden. The default contexts can be found in the `kubernetes_contexts` variables in the [`composer.json`](../composer.json).

For example if the `prod` Kubernetes cluster context ist `example-cluster-1` then the `kubernetes_contexts.prod` has to be set to that value in the `composer.json`'s `extra.project-scaffold` section.