# Claude Code Configuration

My personal [Claude Code](https://claude.com/claude-code) setup — global engineering guidelines, reusable skills, commands, and output styles, versioned so it can be restored on any machine.

It lives at `~/.claude`, where Claude Code also stores runtime state such as sessions, history, caches, and credentials. `.gitignore` therefore uses a whitelist: everything is ignored by default, and only durable configuration is tracked.

## Quick start

If you're new to Claude Code configuration, you only need to understand three things:

- **`CLAUDE.md`** — rules Claude always follows.
- **Skills** — reusable workflows Claude selects when a task matches.
- **Commands** — workflows you explicitly invoke with `/name`.

You usually **do not need to invoke skills manually**. Describe the task naturally and Claude should select the appropriate skill.

For example:

```text
> Our checkout endpoint returns 500 when the cart is empty.
> Reproduce the issue, find the root cause, fix it, and add a regression test.
```

Claude should route the work through the appropriate workflow:

```text
debugging → bug-fix → testing
```

### Which skill should I use?

| If you are... | Use |
|---|---|
| Implementing a new feature or change request | `feature-implementation` |
| Restructuring code without changing behavior | `refactoring` |
| Investigating a failure with an unknown cause | `debugging` |
| Fixing a confirmed bug | `bug-fix` |
| Writing or improving tests | `testing` |
| Reviewing a code change | `code-quality-review` |
| Reviewing system architecture | `architecture-review` |
| Reviewing security | `security-audit` |
| Designing infrastructure | `infra-design` |
| Reviewing Terraform/OpenTofu | `terraform-review` |

Commands are different:

```text
Skills   → Claude decides when to use them.
Commands → You explicitly invoke them.
```

For example:

```text
"Fix this authentication bug"
→ Claude can select the appropriate skill.

"/review-changes"
→ Explicitly invokes the review command.
```

## How it works

The configuration is layered so each rule has one clear owner:

```text
Your task
    ↓
CLAUDE.md
    ↓
Claude matches a skill
    ↓
SKILL.md is loaded
    ↓
The workflow is applied
    ↓
Another skill may take over when its boundary is reached
```

Instructions live in layers; **the narrowest layer that can own a rule, owns it**.

| Layer | Holds | Loaded |
|---|---|---|
| `CLAUDE.md` | Global engineering behavior | Always |
| `skills/` | Reusable workflows for specific tasks | On demand |
| `commands/` | Explicit entry points | When `/name` is invoked |
| `output-styles/` | Response format and tone | When activated |
| `agents/` | Read-only reviewer subagents | When Claude delegates to one |
| `hooks/` | Automation fired by session events | By the harness, on its event |
| `.claude/` in a project | Project-specific knowledge | Always in that project |

Project instructions take precedence over global instructions.

The separation keeps context lean: workflow detail loads only when relevant, and reusable workflows can evolve without changing global engineering behavior.

## Repository structure

```text
~/.claude/
├── .gitignore        # whitelist: ignore everything, track only durable config
├── CLAUDE.md         # global engineering guidelines
├── skills/           # reusable workflows, loaded on demand
│   └── <name>/SKILL.md
├── commands/         # slash commands
│   └── <name>.md
├── output-styles/    # reusable response styles
│   └── <name>.md
├── agents/           # read-only reviewer subagents
│   └── <name>.md
├── hooks/            # session-event automation
│   ├── hooks.json            # Stop hook: configuration drift guard
│   └── check-config-guard.sh # non-blocking wrapper around the drift check
├── .claude-plugin/   # plugin packaging
│   ├── plugin.json           # plugin manifest
│   └── marketplace.json      # self-hosted marketplace serving it
├── scripts/          # repository checks
│   ├── check-config.sh   # deterministic drift audit (runs in CI)
│   └── eval-triggers.sh  # behavioral skill-routing eval (manual)
├── .github/          # CI configuration
├── README.md         # overview and adoption guide
├── CONTRIBUTING.md   # extension and contribution rules
├── CHANGELOG.md      # what changed, per release
└── LICENSE
```

Everything else — including Claude Code runtime state and `settings.json` — is deliberately untracked.

`settings.json` contains personal preferences such as plugins, theme, and model settings, and Claude Code may rewrite it automatically. Versioning it would therefore create noisy, machine-specific changes.

For adding skills, commands, output styles, or other tracked configuration, see [CONTRIBUTING.md](CONTRIBUTING.md).

## Design philosophy

The configuration follows a simple rule:

> **Each rule has exactly one home.**

Global behavior belongs in `CLAUDE.md`.

Reusable task workflows belong in `skills/`.

Explicit entry points belong in `commands/`.

Response formatting belongs in `output-styles/`.

Project-specific behavior belongs in the project's `.claude/`.

Delegated read-only review belongs in `agents/`.

Event-driven automation belongs in `hooks/`.

This avoids duplicated instructions, keeps context smaller, and makes ownership clear.

## Skills

Claude discovers skills by reading each `SKILL.md`'s `description`. The frontmatter description is the skill's routing signal.

| Skill | Reviews / produces | Use when |
|---|---|---|
| `feature-implementation` | new behavior | Adding, building, or extending a feature — smallest correct change, reuse before abstracting |
| `refactoring` | the same behavior, restructured | Renaming, extracting, moving, or deduplicating working code behind a safety net |
| `debugging` | an unknown cause | Investigating intermittent failures, unexplained traces, or failures with no known trigger |
| `bug-fix` | a defect | Fixing a confirmed bug — reproduce, root-cause, fix minimally, add a regression test |
| `testing` | tests | Writing or improving tests, or fixing flaky tests |
| `code-quality-review` | a change | Reviewing a diff or branch for readability and maintainability |
| `architecture-review` | the system | Assessing module boundaries, coupling, layering, and structural debt |
| `security-audit` | trust boundaries | Reviewing security concerns, authentication, authorization, secrets, or input handling |
| `infra-design` | a design | Designing infrastructure — simplest design first, complexity only when a requirement justifies it |
| `terraform-review` | an IaC change | Reviewing Terraform/OpenTofu changes and plans for blast radius, state safety, and drift |

Skills are named after the **work**, not the worker. Review skills use the `<subject>-review` convention.

### Skill boundaries

Skills intentionally have narrow responsibilities.

```mermaid
flowchart TD
    A[Task] --> B{What is the problem?}

    B -->|Building new behavior| K[feature-implementation]
    B -->|Restructuring without changing behavior| L[refactoring]

    K -->|Unexplained failure| C
    K -->|Confirmed defect| D
    K -->|Tests for the new behavior| E
    K -->|Structure must change first| L
    K -->|Reviewing the finished change| F

    L -->|Characterization tests| E
    L -->|What to restructure| G
    L -->|Behavior must change| K

    B -->|Failure, cause unknown| C[debugging]
    C -->|Root cause identified| D[bug-fix]
    D -->|Regression test| E[testing]

    B -->|Writing or improving tests| E
    E -->|Production code is the source of flakiness| C

    B -->|Reviewing code or a change| F[code-quality-review]
    B -->|Reviewing system structure| G[architecture-review]
    B -->|Designing infrastructure| I[infra-design]
    B -->|Reviewing a Terraform change| J[terraform-review]
    B -->|Security concern| H[security-audit]

    F -.->|System-wide structural finding| G
    F -.->|Security finding| H
    D -.->|Security-sensitive fix| H
    I -.->|Security step of the design| H
    I -->|Terraform implementing the design| J
    J -.->|Terraform security checks| H
```

Skills combine where responsibilities overlap.

For example, a security-sensitive bug fix can use both `bug-fix` and `security-audit`, while `bug-fix` can hand the regression-test work to `testing`.

Each skill's `Scope` section defines its exact boundary.

The guiding rule is:

> **When two skills could apply equally, neither reliably does.**

## Commands

Commands are thin entry points, not alternative skill implementations.

A command exists only when it does something a skill cannot — for example, binding a scope up front, running repository-specific setup, or providing a deterministic explicit entry point.

| Command | Does | Invokes |
|---|---|---|
| `/review-changes` | Resolves the diff to review and reviews it read-only | `code-quality-review` |
| `/add-skill` | Scaffolds a skill and updates the required repository documentation | — |
| `/check-config` | Audits the repository for configuration drift | — |
| `/test-skill` | Reports which skill would be loaded for a task, without performing it | — |

Most skills intentionally have no command because their descriptions already provide enough information for Claude to select them automatically.

## Output styles

`output-styles/` contains reusable response styles.

A style controls **how Claude responds**, not how engineering work is performed.

```text
Skills         → what work Claude performs
Commands       → how you explicitly invoke a workflow
Output styles  → how the response is presented
```

`concise` is the preferred style: short, direct responses that lead with the result.

## Agents

`agents/` contains subagents Claude can delegate to. Each runs in its own context, which keeps a
long review out of the main conversation.

Both shipped agents are **read-only**: neither is granted `Edit` or `Write`, so they report
findings and never change code. Each pairs with the skill that owns its method.

| Agent | Pairs with | Does |
|---|---|---|
| `agents/code-quality-reviewer.md` | `code-quality-review` | Reviews a diff, branch, or path for readability, maintainability, duplication, and compatibility |
| `agents/security-auditor.md` | `security-audit` | Reviews trust boundaries, auth, input handling, and secret hygiene |

The agent does not restate the method — it loads the skill and follows it. The skill stays the
single home for the checklist.

## Hooks

`hooks/hooks.json` registers a `Stop` hook — it fires when Claude finishes responding, not on
every tool call — that runs the drift check and prints any findings.

It is deliberately **advisory**: `hooks/check-config-guard.sh` always exits `0`. Drift is
reported, never enforced, and if `scripts/check-config.sh` is absent (someone copied only part of
this configuration) the hook exits quietly instead of breaking the session.

Installing this repository as a plugin registers the hook automatically. To enable it in a plain
`~/.claude` clone instead, add this to `settings.json`:

```json
{
  "hooks": {
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "bash \"$HOME/.claude/hooks/check-config-guard.sh\"",
            "timeout": 60
          }
        ]
      }
    ]
  }
}
```

The plugin form uses `${CLAUDE_PLUGIN_ROOT}` in place of `$HOME/.claude`, so the hook resolves to
wherever the plugin was installed.

## Validation

The repository uses two levels of validation.

### Mechanical validation

`scripts/check-config.sh` checks rules that can be determined reliably without an LLM, including:

- skill whitelist synchronization
- skill frontmatter
- README skill-table membership
- README skill-boundary diagram membership
- README command-table membership
- configuration structure

CI runs this check on every push.

Run it locally:

```bash
bash scripts/check-config.sh
```

### Behavioral validation

`scripts/eval-triggers.sh` evaluates whether skill descriptions route representative tasks to the intended skill — and, just as importantly, whether ordinary work that `CLAUDE.md` already covers correctly loads no skill at all.

It is deliberately **not run in CI** because it:

- requires the Claude CLI
- consumes model tokens
- is non-deterministic
- is intended to catch routing regressions rather than repository structure errors

Run it before a release or after changing skill descriptions:

```bash
bash scripts/eval-triggers.sh
```

For a stricter stability check:

```bash
EVAL_RUNS=3 EVAL_MODEL=haiku bash scripts/eval-triggers.sh
```

## Adopting this config

### As a plugin (recommended)

The repository ships a plugin manifest and a self-hosted marketplace, so Claude Code can install
and update it for you — skills, commands, agents, and the drift-guard hook together:

```text
/plugin marketplace add thixpin/claude-config
/plugin install claude-config@thixpin
```

Update it later with:

```text
/plugin marketplace update thixpin
```

Installing as a plugin leaves your own `~/.claude` untouched, which makes it the safest option if
you already have a configuration there. It does **not** install `CLAUDE.md` — global engineering
guidelines are personal, so copy that file yourself if you want it.

### Just the skills

Each skill is self-contained:

```bash
git clone https://github.com/thixpin/claude-config.git /tmp/claude-config
cp -r /tmp/claude-config/skills/bug-fix ~/.claude/skills/
```

Copy related skills together when their `Scope` sections describe handoffs between them.

For example:

```bash
cp -r /tmp/claude-config/skills/debugging ~/.claude/skills/
cp -r /tmp/claude-config/skills/bug-fix ~/.claude/skills/
cp -r /tmp/claude-config/skills/testing ~/.claude/skills/
```

### Just an output style

An output style is one self-contained file:

```bash
cp /tmp/claude-config/output-styles/concise.md ~/.claude/output-styles/
```

### The whole config

Clone the repository directly:

```bash
git clone https://github.com/thixpin/claude-config.git ~/.claude
```

If `~/.claude` already exists, do not overwrite it blindly. Back up any existing configuration first.

You can initialize the existing directory as a Git repository instead:

```bash
cd ~/.claude
git init -b master
git remote add origin https://github.com/thixpin/claude-config.git
git fetch origin
git checkout -f master
```

> **Warning:** `git checkout -f master` overwrites conflicting tracked files. Back up customized `CLAUDE.md`, skills, commands, or other configuration before running it.

### LSP

The navigation guidelines in `CLAUDE.md` prefer LSP-based navigation when available.

Enable an LSP plugin for the languages you work with — TypeScript, Go, Python, PHP, Rust, and so on.

LSP is not required. The navigation rules fall back to text search when LSP is unavailable.

## Extending the configuration

You do not need to understand the repository internals to start using it.

When you want to extend the configuration:

1. Add a skill, command, or output style according to [CONTRIBUTING.md](CONTRIBUTING.md).
2. Add a [CHANGELOG.md](CHANGELOG.md) entry in the same change.
3. Run the mechanical validation.
4. Run the behavioral trigger evaluation when changing skill descriptions.
5. Review the diff.
6. Commit only when ready.

See [CONTRIBUTING.md](CONTRIBUTING.md) for the detailed rules.

## Third-party skills

Third-party skills are external instruction sources that run with the same trust as your own configuration — review them before installing.

Before installing one:

1. Read its `SKILL.md`.
2. Review what instructions it adds.
3. Prefer a reviewed commit rather than tracking a moving branch.
4. Read `SKILL.md` again after updates.

Third-party skills remain independent projects with their own names and licenses.

## License

[MIT](LICENSE) © Soe Thura

Third-party skills installed under `skills/` remain separate projects under their respective licenses.