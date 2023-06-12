# Automation (CI/CD)

There are multiple GitHub Action workflows for running common automation tasks.

* [Update: Updating Drupal projects](#update-drupal-project)
* [Upgrade: Upgrading Drupal projects with specific operations](#upgrade-drupal-project)
* [Visual Regression Testing: Comparing reference website to local test deployment](#visual-regression-testing)

## Update Drupal Project

* Workflow: `update.yml`
* Runs on:
    * Manual dispatch
* Inputs
    * Token: GitHub Personal Access Token

This workflow will install the project in a GitHub Actions runner environment and run the Drupal update process on it (`make update`). If successful it will create a pull request with the changes. If a token is provided then the pull request created by this workflow will trigger other workflows running on push or pull request triggers.

## Upgrade Drupal Project

* Workflow: `upgrade.yml`
* Runs on:
    * Manual dispatch
* Inputs
    * Token: GitHub Personal Access Token
    * Require: Composer require a module or list of modules
    * Remove: Composer remove a module or list of modules
    * Enable: Enable a module or list of modules with Drush
    * Uninstall: Uninstall a module or list of modules with Drush
    * Payload: JSON encoded operation payload for advanced usage

This workflow will install the project in a GitHub Actions runner environment and run the Drupal upgrade process on it (`make upgrade`) using either the provided `require`, `remove`, `enable` and `uninstall` inputs or the provided `payload` (`payload` always overrides other inputs). If successful it will create a pull request with the changes. If a token is provided then the pull request created by this workflow will trigger other workflows running on push or pull request triggers.

<details><summary>Available actions</summary>

* `remove`: Removing packages with `composer remove`.
* `require`: Requiring new or upgrading existing packages with `composer require`.
* `update`: Updating packages with existing version constraints with `composer update`.
* `bump`: Bumping the version constraints in the requirements according to the installed versions with `composer bump`.
* `config`: Changing the composer config with `composer config` (repositories, platform, or extra like project-scaffold).
* `rector`: Drupal rector for running automated code fixes and upgrades with `rector` (for custom project modules).
* `phpcbf`: PHP code beautifying with `phpcbf` for improving code quality (for custom project modules).
* `updatedb`: Drupal database updates with `drush updatedb`.
* `enable`: Enabling Drupal modules with `drush pm:enable`.
* `uninstall`: Uninstalling/disabling Drupal modules with `drush pm:uninstall`.
* `enable`: Enabling Drupal themes `drush theme:enable`.
* `uninstall`: Uninstalling/disabling Drupal themes `drush theme:uninstall`.
* `export`: Exporting the Drupal configuration `drush config:export`.
* `set`: Setting Drupal configuration with`drush config:set` (e.g. site title).
* `project:scaffold`: Scaffolding project assets with `composer project:scaffold`.
* `drupal:scaffold`: Scaffolding drupal assets with `composer drupal:scaffold`.
* `patch-add`: Adding patches to composer with `composer patch-add`.
* `patch-remove`: Removing patches from composer with `composer patch-remove`.
* `commit`: Committing changes between operation actions with `git commit`.
* `reboot`: Rebooting/restarting the local deployment between operation actions (e.g. when changing images).

</details>

A JSON payload has to follow this structure:

* `operations`: Operations Array (`array`)
    * Operation object
        * `match`: (optional) Matching a requirement (key) in the `require` or `require-dev` of the `composer.json` (`string`)
        * `matchInverse`: (optional) Inverse matching a requirement (key) in the `require` or `require-dev` of the `composer.json` (`string`)
        * `action`: The desired action (e.g. `require`) (`string`)
        * `data`: (optional) The data for the action (e.g. `dompdf/dompdf`) (`string`|`array`)
        * `options`: (optional) Options for the action (e.g. `--dev`) (`string`)

An example operation for removing `dompdf/dompdf` if it is installed and requiring `iqual/iq_barrio` and `drupal/antibot:^2.0` and updating all depedencies would look like this:

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
                "drupal/antibot:^2.0",
            ],
            "options": "--with-all-dependencies"
        },
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
        "action": "rector",
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
          "drupal/antibot:^2.0",
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


## Visual Regression Testing

* Workflow: `visual-regression-testing.yml`
* Runs on:
    * Manual dispatch
    * Pull request (re)open

This workflow will install the project in a GitHub Actions runner environment and run a visual regression test on it ([iqual-ch/ci-pocketknife-installer](https://github.com/iqual-ch/ci-pocketknife-installer) and [iqual-ch/ci-pocketknife](https://github.com/iqual-ch/ci-pocketknife/)). This workflow requires a `.env.visreg` file setting the test and reference website URLs for testing. The workflow will crawl the website for relevant links. If the test fails (when there are visual differences between the two websites), then it will upload a BackstopJS report as a workflow artifact.
