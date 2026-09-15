---
name: refactoring
description: Workflow for behavior-preserving restructuring — establish a characterization-test safety net first, then apply one mechanical change at a time, verifying after each step. Use when extracting, inlining, moving, splitting, or deduplicating code that already works and the change spans several steps or files. A single local edit an editor could make on its own — renaming one variable, reflowing a line — needs no workflow and no safety net. Deciding what to restructure belongs to architecture-review; adding or changing behavior belongs to feature-implementation.
---

# Refactoring

Change the shape, never the behavior. A refactor without a safety net is a rewrite with optimism.

## Scope

**Use for** restructuring working code with identical observable behavior: extracting or inlining a function, renaming, moving code to its owning module, collapsing duplication, splitting an overlarge unit, replacing a pattern with an existing helper.

**Do not use for:**
- Deciding *what* should be restructured, or assessing structural debt, coupling, and layering — that is `architecture-review`, which produces the plan this skill carries out.
- Adding, removing, or changing behavior — use `feature-implementation`. Fixing a defect is `bug-fix`.
- Writing the safety-net tests themselves — those follow `testing`; come back here once they pass on the current code.

**The moment output changes, it is no longer a refactor.** Stop, finish the restructuring, and make the behavior change as a separate step.

## Workflow

1. **State the end shape and the reason.** One sentence: what moves where, and what it buys. A restructuring with no named benefit should not happen.
2. **Establish the safety net first.** Identify the tests that already pin the current behavior and run them — they must pass *before* you touch anything. Where coverage is missing, write characterization tests that assert what the code does today (not what it should do), following `testing`. If the behavior is untestable, say so and treat the work as high risk rather than proceeding silently.
3. **Sequence the work into mechanical steps.** Rename, extract, move, inline — one kind of change per step, each one small enough to describe in a single line and to revert alone.
4. **Apply one step at a time.** Never combine a move with a rename, or an extraction with a signature change. Prefer the tool-assisted transformation (LSP rename, extract) over hand-editing.
5. **Verify after every step,** not at the end: the safety-net tests, then the linter and type checker. A green step is a commit point; a red step is reverted, not debugged forward.
6. **Update every caller in the same step** as the thing they call. Leaving both the old and new shape in place creates two sources of truth that will diverge — no compatibility shim, no deprecated copy kept beside the new one.
7. **Confirm behavior is unchanged at the end.** Full relevant suite green, no test edited to accommodate the new shape except for names and import paths. A test whose *assertion* had to change is evidence behavior moved.

## Rules

- No behavior change, no bug fix, and no new feature rides along. Note anything you find and handle it separately.
- Do not restructure code you cannot run the tests for.
- Do not reshape existing architecture without asking; this skill executes a decision, it does not make one.
- Timebox. If a step will not go green and the cause is unclear, revert to the last green state and use `debugging` rather than pushing through.
