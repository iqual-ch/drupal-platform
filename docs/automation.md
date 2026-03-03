# Automation (CI/CD)

There are multiple GitHub Action workflows for running common automation tasks.

* [Update: Updating Drupal projects](#update-drupal-project)
* [Upgrade: Upgrading Drupal projects with specific operations](#upgrade-drupal-project)
* [Config: Pull remote config](#config-pull)
* [Testing: Test the Drupal project](#testing)
   * [PHPCS: Linting](#phpcs)
   * [PHPUnit: Unit Testing](#phpunit-unit-testing)
   * [PHPUnit: Functional Testing](#phpunit-functional-testing)
   * [Visual Regression Testing: Comparing reference website to local test deployment](#visual-regression-testing)

## Update Drupal Project

* Workflow: `update.yml`
* Config variable: `workflows.update`
* Runs on:
   * Manual dispatch

* Inputs
   * Token: GitHub Personal Access Token
   * Labels: Comma-separated list of labels to apply to the pull request
   * ID: Optional identifier (e.g. Jira ID) to distinguish this workflow run in the commit message and pull request title (default: timestamp)
   * Branch: Optional branch name for the pull request (default: `misc/update-<timestamp>`).

This workflow will install the project in a GitHub Actions runner environment and run the Drupal update process on it (`make update`). If successful it will create a pull request with the changes. If a token is provided then the pull request created by this workflow will trigger other workflows running on push or pull request triggers.

## Upgrade Drupal Project

* Workflow: `upgrade.yml`
* Config variable: `workflows.upgrade`
* Runs on:
   * Manual dispatch

* Inputs
   * Token: GitHub Personal Access Token
   * Require: Composer require a module or list of modules
   * Remove: Composer remove a module or list of modules
   * Enable: Enable a module or list of modules with Drush
   * Uninstall: Uninstall a module or list of modules with Drush
   * Payload: JSON encoded operation payload for advanced usage
   * Labels: Comma-separated list of labels to apply to the pull request
   * ID: Optional identifier (e.g. Jira ID) to distinguish this workflow run in the commit message and pull request title (default: timestamp)
   * Branch: Optional branch name for the pull request (default: `misc/upgrade-<timestamp>`).

This workflow will install the project in a GitHub Actions runner environment and run the Drupal upgrade process on it (`make upgrade`) using either the provided `require`, `remove`, `enable` and `uninstall` inputs or the provided `payload` (`payload` always overrides other inputs). If successful it will create a pull request with the changes. If a token is provided then the pull request created by this workflow will trigger other workflows running on push or pull request triggers.

<details><summary>Available actions</summary>

* `remove`: Removing packages with `composer remove`.
* `require`: Requiring new or upgrading existing packages with `composer require`.
* `update`: Updating packages with existing version constraints with `composer update`.
* `bump`: Bumping the version constraints in the requirements according to the installed versions with `composer bump`.
* `config`: Changing the composer config with `composer config` (repositories, platform, or extra like project-scaffold). Requires `key` field.
* `rector`: Drupal rector for running automated code fixes and upgrades with `rector` (for custom project modules).
* `phpcbf`: PHP code beautifying with `phpcbf` for improving code quality (for custom project modules).
* `updatedb`: Drupal database updates with `drush updatedb`.
* `cache:rebuild`: Drupal cache rebuild with `drush cache:rebuild`.
* `pm:enable`: Enabling Drupal modules with `drush pm:enable`.
* `pm:uninstall`: Uninstalling/disabling Drupal modules with `drush pm:uninstall`.
* `theme:enable`: Enabling Drupal themes with `drush theme:enable`.
* `theme:uninstall`: Uninstalling/disabling Drupal themes with `drush theme:uninstall`.
* `config:export`: Exporting the Drupal configuration with `drush config:export`.
* `config:set`: Setting Drupal configuration with `drush config:set` (e.g. site title). Requires `key` field.
* `project:scaffold`: Scaffolding project assets with `composer project:scaffold`.
* `drupal:scaffold`: Scaffolding drupal assets with `composer drupal:scaffold`.
* `patch-add`: Adding patches to composer with `composer patch-add`.
* `patch-remove`: Removing patches from composer with `composer patch-remove`.
* `patch-remove-all`: Removing all patches from a single composer packages by looping `composer patch-remove`.
* `patch-remote-to-local`: Download all remote patches and store them in the given directory.
* `patch-migrate-config`: Migrate the composer patches configuration from 1 to 2.
* `commit`: Committing changes between operation actions with `git commit`.
* `reboot`: Rebooting/restarting the local deployment between operation actions (e.g. when changing images).

</details>

A JSON payload has to follow this structure:

* `operations`: Operations Array (`array`)
   * Operation object
      * `action`: The desired action (e.g. `require`) (`string`)
      * `data`: (optional) The data for the action (e.g. `dompdf/dompdf`) (`string`|`array`)
      * `options`: (optional) Options for the action (e.g. `--dev`) (`string`)
      * `key`: (required for `config` and `config:set` actions) The configuration key to set (e.g. `platform.php`) (`string`)
      * `match`: (optional) Matching a requirement (key) in the `require` or `require-dev` of the `composer.json` (`string`)
      * `matchInverse`: (optional) Inverse matching a requirement (key) in the `require` or `require-dev` of the `composer.json` (`string`)
      * `matchLock`: (optional) Matching a installed package in the `composer.lock` (`string`)
      * `matchLockInverse`: (optional) Inverse matching a installed package in the `composer.lock` (`string`)
      * `matchName`: (optional) Matching the `name` (key) in the `composer.json` (`string`)
      * `matchNameInverse`: (optional) Inverse matching the `name` (key) in the `composer.json` (`string`)
      * `matchExtension`: (optional) Matching the name of a module or theme in the `core.extension.yml` of the Drupal config (`string`)
      * `matchExtensionInverse`: (optional) Inverse matching the name of a module or theme in the `core.extension.yml` of the Drupal config (`string`)

An example operation for removing `dompdf/dompdf` if it is installed and requiring `iqual/iq_barrio` and `drupal/antibot:^2.0` and updating all dependencies would look like this:

```json
{
    "operations": [
        {
            "match": "dompdf/dompdf",
            "action": "remove",
            "data": "dompdf/dompdf"
        },
        {
            "match": "iqual/iq_barrio",
            "action": "require",
            "data": [
                "iqual/iq_barrio",
                "drupal/antibot:^2.0"
            ],
            "options": "--with-all-dependencies"
        }
    ]
}
```

<details><summary>Example JSON payload for a complex migration</summary>

```JSON
{
    "operations": [
      {
        "match": "dompdf/dompdf",
        "action": "remove",
        "data": "dompdf/dompdf"
      },
      {
        "match": "zaporylie/composer-drupal-optimizations",
        "action": "remove",
        "data": "zaporylie/composer-drupal-optimizations"
      },
      {
        "match": "webflo/drupal-finder",
        "action": "remove",
        "data": "webflo/drupal-finder",
        "options": "--no-update"
      },
      {
        "action": "update",
        "options": "--lock"
      },
      {
        "action": "commit",
        "data": "Removed legacy root requirements"
      },
      {
        "action": "rector"
      },
      {
        "action": "phpcbf",
        "options": "--standard=Drupal,DrupalPractice --extensions='php,module,inc,install,test,profile,theme,css,info,txt,md,yml'"
      },
      {
        "action": "commit",
        "data": "Ran rector and code beautifier"
      },
      {
        "action": "config",
        "key": "extra.project-scaffold.runtime",
        "data": {
          "php_version": "8.1"
        },
        "options": "--merge"
      },
      {
        "action": "config",
        "key": "platform.php",
        "data": "8.1.17"
      },
      {
        "action": "project:scaffold"
      },
      {
        "action": "reboot"
      },
      {
        "match": "iqual/iq_barrio",
        "action": "require",
        "data": [
          "iqual/iq_barrio",
          "drupal/antibot:^2.0"
        ],
        "options": "--with-all-dependencies"
      },
      {
        "action": "update",
        "options": "--with-all-dependencies"
      },
      {
        "action": "updatedb"
      },
      {
        "action": "config:export"
      },
      {
        "action": "config",
        "key": "platform",
        "options": "--unset"
      }
    ]
}
```

</details>

> In the GitHub web UI you have to make sure to escape double-quotes (e.g. `{\"operations\": [{\"action\": \"config:export\"}]}`).

## Config Pull

Pulls the remote environments' Drupal configuration without fully deploying a environment locally. This works by running a `drush config:pull` and commiting directly to the branch that the workflow was triggered on.

* Workflow: `config-pull.yml`
* Runs on:
   * Manual dispatch
   * Call from other workflow

* Inputs
  * Environment: Config pull source (Default: SPOT)

> [!WARNING]
> This workflow will lead to deployments since it pulls configuration from the specified source of truth and commit it to the selected branch (e.g. `main` and thus production).

## Testing

* Workflow: `testing.yml`
* Config variable: `workflows.phpunit`
* Runs on:
   * Manual dispatch
   * Pull request (re)open

* Calls:
   * PHPCS
   * PHPUnit Unit Testing
   * PHPUnit Functional Testing
   * Visual Regression Testing

This workflow runs extensive Drupal testing by running a full build, linting and PHPUnit unit test in parallel. If the build succeeds it will also run PHPUnit database and browser test, as well as visual regression testing. The workflow can be dispatched manually, but will also run on PR creation. When it is run against a PR it will also directly annotate the files that are throwing errors or warnings.

## PHPCS

* Workflow: `phpcs.yml`
* Config variable: `workflows.phpunit`
* Runs on:
   * Manual dispatch
   * Call from other workflow

This workflow will first run `parallel-lint` to check the syntax of all custom themes & modules in the repository. Afterwards it will run `phpcs` to code sniff according to the Drupal standards.

## PHPUnit Unit Testing

* Workflow: `phpunit-unit-testing.yml`
* Config variable: `workflows.phpunit`
* Runs on:
   * Manual dispatch
   * Call from other workflow

This workflow will run the "unit" testsuite according to the `phpunit.xml` (fallback to `phpunit.xml.dist`) in the repository. This type of testing doesn't require a full Drupal build.

## PHPUnit Functional Testing

* Workflow: `phpunit-functional-testing.yml`
* Config variable: `workflows.phpunit`
* Runs on:
   * Manual dispatch
   * Call from other workflow

* Inputs
   * Testing Type: The type of test to run (database or browser)

This workflow will run different testsuites according to the `phpunit.xml` (fallback to `phpunit.xml.dist`) in the repository depending on the input type of test:

* `database`: Run kernel, functional & existingsite testsuite with PHPUnit requiring a database
* `browser`: Run functional-javascript & existingsite-javascript testsuite with PHPUnit requiring a browser

This workflow requires a full build of Drupal.

## Visual Regression Testing

* Workflow: `visual-regression-testing.yml`
* Config variable: `workflows.vrt`
* Runs on:
   * Manual dispatch
   * Pull request (re)open (`workflows.phpunit` disabled)
   * Call from other workflow (`workflows.phpunit` enabled)

This workflow will install the project in a GitHub Actions runner environment and run a visual regression test on it ([iqual-ch/ci-pocketknife-installer](https://github.com/iqual-ch/ci-pocketknife-installer) and [iqual-ch/ci-pocketknife](https://github.com/iqual-ch/ci-pocketknife/)). This workflow requires a `.env.visreg` file setting the test and reference website URLs for testing. The workflow will crawl the website for relevant links. If the test fails (when there are visual differences between the two websites), then it will upload a BackstopJS report as a workflow artifact.
