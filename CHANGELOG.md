# Changelog

All notable changes to this configuration are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

Entries below are reconstructed from the Git history; each one names the commit it
came from. Sections are cut at the release tags that already exist in the repository.

## [Unreleased]

### Fixed

- `architecture-review` never fired: its description opened as a method
  description rather than a trigger, and routing fell through to no skill on
  every structural-assessment prompt. Rewritten to lead with the triggers and
  to name `refactoring` as the skill that carries the work out.
- `refactoring` over-triggered on trivial edits: its description claimed
  "renaming", which routed a single variable rename to the skill. It now
  scopes itself to changes spanning several steps or files.
- `scripts/eval-triggers.sh` scored every case as a failure when the config was
  installed as a plugin, because plugin skills answer as `<plugin>:<skill>`.
  The matcher strips that namespace.

### Changed

- Plugin manifest version tracks the released tags (1.3.0). Plugin caches are
  version-keyed, so an edited skill never reaches an installed copy unless
  the version advances.
- `scripts/eval-triggers.sh` covers the two new skills: direct-hit and
  boundary cases for `feature-implementation` and `refactoring`.
- Repository re-pointed at this fork: plugin and marketplace manifests, install
  and clone instructions, and changelog compare links now name
  `attthurein/claude-config`. README carries a fork notice crediting upstream,
  and `LICENSE` retains the upstream copyright with a second line for fork
  additions.

### Added

- `feature-implementation` skill — workflow for building a new feature or change
  request: pin the requirement, find the smallest relevant scope, reuse before
  abstracting, and run the project's validation gates.
- `refactoring` skill — workflow for behavior-preserving restructuring behind a
  characterization-test safety net, one mechanical change at a time.
- Plugin packaging: `.claude-plugin/plugin.json` and `.claude-plugin/marketplace.json`,
  so the repository can be installed with `/plugin install` instead of copying
  directories by hand.
- `hooks/` — a `Stop` hook (`hooks/hooks.json`) that runs `scripts/check-config.sh`
  through the non-blocking wrapper `hooks/check-config-guard.sh` as a drift guard.
  A missing script is a silent success, so a partial copy of this configuration
  cannot break a session.
- `agents/` — read-only reviewer subagents: `code-quality-reviewer` (pairs with the
  `code-quality-review` skill) and `security-auditor` (pairs with `security-audit`).
  Neither is granted `Edit` or `Write`.
- This `CHANGELOG.md`.
- `/test-skill` command — reports which skill would be loaded for a task without
  performing the task (d498eae).

### Changed

- `CLAUDE.md` gained an explicit skills policy covering when a skill must be loaded
  before inspecting, changing, or executing anything (d498eae).
- `.gitignore` whitelist extended for the new top-level paths (`.claude-plugin/`,
  `hooks/`, `CHANGELOG.md`) and the two new skills. Without a whitelist line a new
  top-level path is dropped silently.
- `README.md` documents the plugin install method, the hook, and the subagents, and
  lists the new directories in the repository structure and layer table.
- `CONTRIBUTING.md` requires a changelog entry per change, and a whitelist line for
  every new top-level path.
- Hardening of `scripts/check-config.sh` and the CI workflow (landed in parallel).

## [1.2.0] - 2026-08-10

### Added

- Deterministic configuration audit `scripts/check-config.sh`, wired into CI, plus
  the review findings it surfaced (2fa15b7).
- Behavioral skill-trigger evaluation `scripts/eval-triggers.sh` (450ad18).

### Changed

- README compacted; contributor rules extracted into `CONTRIBUTING.md` (96f31d9).
- Commit-convention guidance now prefers a project's own convention over the global
  default (2edee07).

### Fixed

- Review findings in `eval-triggers.sh` and the documentation drift it exposed (12292f7).

## [1.1.0] - 2026-08-09

### Added

- `debugging` skill, and its documented boundary with `bug-fix` (8e927fe).
- `infra-design` and `terraform-review` skills, the `output-styles/` layer, and the
  skill-boundary diagram (710df83).

### Changed

- `CLAUDE.md` gained an efficiency section and the global guidelines were compacted
  (c74be21).
- The `testing` skill now requires an isolated test database (957e962).
- The LSP dependency is stated explicitly for adopters (a189062).

### Fixed

- Terraform state-secrets wording and an `infra-design` typo (c058033).

## [1.0.0] - 2026-08-05

### Added

- Initial configuration: `CLAUDE.md`, the first skills, and the repository layout
  (4b2f0a8).
- `commands/` layer with `/review-changes`, `/add-skill`, and `/check-config` (2aff791).

### Changed

- `CLAUDE.md` simplified; skills guidance that duplicated the skills themselves was
  removed (2aba309).

[Unreleased]: https://github.com/attthurein/claude-config/compare/v1.2.0...HEAD
[1.2.0]: https://github.com/attthurein/claude-config/compare/v1.1.0...v1.2.0
[1.1.0]: https://github.com/attthurein/claude-config/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/attthurein/claude-config/releases/tag/v1.0.0
