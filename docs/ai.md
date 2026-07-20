# AI Integration

The Drupal Platform scaffolds an AI/agent integration into every project so that coding agents (Claude Code, GitHub Copilot coding agent, and other AGENTS.md-compatible tools) get project context, shared skills and a working environment out of the box.

The integration consists of three managed assets, each of which can be disabled individually with a [package variable](./configuration.md#drupal-platform-package-variables):

| Asset | Variable | Purpose |
|---|---|---|
| `AGENTS.md` | `ai.agents` | Generated agent instruction file with project facts, commands and conventions. |
| `.claude/settings.json` | `ai.claude` | Recommends the `iqual-developer` Claude Code plugin (marketplace: [iqual-ch/claude-plugins](https://github.com/iqual-ch/claude-plugins)). |
| `CLAUDE.md` | `ai.claude` | Claude Code entry point that imports `AGENTS.md`. |
| `.github/workflows/copilot-setup-steps.yml` | `ai.copilot` | Prepares the GitHub Copilot coding agent's cloud environment. |

## AGENTS.md

`AGENTS.md` is a **replaced** (fully managed) asset: it is templated from the package variables (PHP/DB versions, deployment type, enabled workflows, URLs, …) and overwritten on every scaffold run. Do not edit it in the project.

Project-specific knowledge belongs next to it instead:

* **`docs/`** — project-specific documentation. If the directory exists, `AGENTS.md` automatically points agents to it (re-run `composer project:scaffold` after creating it).
* **`.agents/skills/`** — project-specific [Agent Skills](https://agentskills.io) committed to the repository.

## Shared skills

Reusable Drupal engineering knowledge (skills such as `drupal-expert`, `drupal-testing`, `drupal-contrib`) is **not** committed to projects. It is maintained centrally in [iqual-ch/claude-plugins](https://github.com/iqual-ch/claude-plugins) and distributed per agent:

* **Claude Code**: the scaffolded `.claude/settings.json` registers the `iqual` marketplace and enables the `iqual-developer` plugin — developers are prompted once to install it when they open the repository.
* **GitHub Copilot coding agent**: `copilot-setup-steps.yml` installs the plugin's skills into `.agents/skills/` (excluded from git via `.git/info/exclude`) before the agent starts.
* **Other agents/CI**: use the reusable [`install-skills` action](https://github.com/iqual-ch/claude-plugins#readme).

This keeps skills versioned and updated in one place, instead of drifting copies in every project repository.

## Copilot coding agent environment

The Copilot cloud agent runs `.github/workflows/copilot-setup-steps.yml` before it starts working (the job must be named exactly `copilot-setup-steps`). The scaffolded workflow:

1. Installs the shared agent skills.
2. Installs the project locally (DDEV runtime + Drupal, using the `SSH_KEY` secret to sync from the SPOT) — `platform.sh` deployments only.
3. **Removes the SSH key** and verifies the remote environment is unreachable, so the agent has a full local site and toolchain but no access to remote environments.

For `local-only` deployments only the skills are installed.

The workflow respects the `workflows.runner` variable for custom runner labels and can be disabled entirely with `ai.copilot: false`.

## Claude Code settings

`.claude/settings.json` is a **merged** asset: the plugin recommendation keys are merged into the file, while any additional project-specific settings (e.g. `permissions`) are preserved. Local per-developer overrides belong in `.claude/settings.local.json` (git-ignored by the scaffolded `.gitignore`).

`CLAUDE.md` is a **replaced** (fully managed) asset that imports `AGENTS.md` (`@AGENTS.md`), so Claude Code picks up the same instructions as other agents — do not add project-specific content to it.
