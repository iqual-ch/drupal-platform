# Automation (CI/CD)

There are multiple GitHub Action workflows for running common automation tasks.

## Update Drupal Project

* Workflow: `update.yml`
* Runs on:
    * Manual dispatch
* Inputs
    * Token: GitHub Personal Access Token

This workflow will install the project in a GitHub Actions runner environment and run the Drupal update process on it (`make update`). If successful it will create a pull request with the changes. If a token is provided then the pull request created by this workflow will trigger other workflows running on push or pull request triggers.

## Visual Regression Testing

* Workflow: `visual-regression-testing.yml`
* Runs on:
    * Manual dispatch
    * Pull request (re)open

This workflow will install the project in a GitHub Actions runner environment and run a visual regression test on it ([iqual-ch/ci-pocketknife-installer](https://github.com/iqual-ch/ci-pocketknife-installer) and [iqual-ch/ci-pocketknife](https://github.com/iqual-ch/ci-pocketknife/)). This workflow requires a `.env.visreg` file setting the test and reference website URLs for testing. The workflow will crawl the website for relevant links. If the test fails (when there are visual differences between the two websites), then it will upload a BackstopJS report as a workflow artifact.