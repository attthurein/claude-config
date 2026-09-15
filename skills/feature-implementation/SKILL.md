---
name: feature-implementation
description: Workflow for building a new feature or change request — pin the requirement, locate the smallest relevant scope, reuse before abstracting, implement the smallest correct change, and run the project's validation gates. Use when asked to add, build, implement, or extend behavior. For behavior-preserving restructuring use refactoring; for a confirmed defect use bug-fix, and for a failure whose cause is unknown use debugging first.
---

# Feature Implementation

Build the smallest change that fully satisfies the requirement, in the shape the codebase already uses. New code is a last resort, not a starting point.

## Scope

**Use for** adding or extending behavior: a new feature, endpoint, field, command, screen, or a change request against working code.

**Do not use for:**
- Restructuring without changing behavior — use `refactoring`.
- Fixing a confirmed defect — use `bug-fix`.
- A failure whose cause is unknown — use `debugging`, then return here or to `bug-fix` with the cause.
- Deciding whether the system's structure can carry the feature at all — that assessment is `architecture-review`.

**This skill ends at a working, validated change.** Writing the tests that cover it follows `testing`; reviewing the finished diff belongs to `code-quality-review`.

## Workflow

1. **Pin the requirement.** State in one or two sentences what the change must do, and what observable result proves it done. Name the assumptions you are making rather than guessing silently; ask at most one concise clarifying question when the requirement is genuinely ambiguous.
2. **Locate the smallest relevant scope.** Find the module that already owns this concern before opening anything else. Read the nearby pattern — how a sibling feature is wired, named, validated, and tested — and follow it.
3. **Search before creating.** Grep for the function, service method, serializer, component, column, endpoint, or config key you were about to write. A name you would naturally choose is usually a name someone already chose. Reuse it, or move it if it lives in the wrong place — never copy it.
4. **Put the rule in its owning place.** A business rule, permission check, validation, or calculation lives in exactly one module — the domain service that owns it — not in a view, serializer, model hook, admin, command, or client. Configuration is data, not a literal.
5. **Implement minimally.** The smallest correct change that satisfies the pinned requirement. No speculative extensibility, no abstraction without a caller that needs it today, and no unrelated refactoring in the same edit.
6. **Run the project's validation gates** — formatter, linter, type checker, and the smallest relevant test suite — after the change, not at the end of the session. State clearly when a gate could not be run.
7. **Finish the change.** Documentation and changelog move in the same change as the code. A behavior change with no doc change is incomplete.

## Judgment calls

- If an existing mechanism looks half-built, the missing caller is usually the defect, not the mechanism. Connect the existing foundation rather than pouring another one; ask before reshaping architecture that is already there.
- If the requirement cannot be met without a wide restructuring, present the minimal change and the restructuring as separate options — and hand the restructuring to `refactoring` as its own step, before or after, never interleaved.
- If a gate fails for a reason you cannot explain, stop and use `debugging` rather than adjusting code until it passes.
- If the feature touches auth, permissions, secrets, or input handling, apply the `security-audit` checklist to the change as well.
