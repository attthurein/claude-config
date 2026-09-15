#!/usr/bin/env bash
# Mechanical half of /check-config: deterministic drift checks, runnable
# locally or in CI. Judgment checks (skill overlap, layering) stay in
# commands/check-config.md.
set -u
cd "$(dirname "$0")/.." || exit 1

fail=0
err() { printf 'FAIL: %s\n' "$*"; fail=1; }

# First value of a frontmatter key, or empty if absent. Output is captured into
# a variable by every caller: never pipe a producer into `grep -q` here, because
# grep closes stdin on its first match and the producer dies with SIGPIPE.
fm_value() { sed -n "s/^$2: *//p" "$1" | head -n 1; }

# Claude Code's frontmatter description limit.
DESC_MAX=1024

# name<TAB>description for every skill, checked for duplicates after the loop.
skill_descs=''

# Local skills (no nested .git) must be whitelisted, unignored, complete,
# and documented in the README table and boundaries diagram.
for d in skills/*/; do
  name=${d#skills/}; name=${name%/}
  [ -e "${d}.git" ] && continue # third-party clone: deliberately untracked
  [ -f "${d}SKILL.md" ] || { err "skills/$name has no SKILL.md"; continue; }
  grep -qxF "!/skills/$name/" .gitignore || err "skills/$name not whitelisted in .gitignore"
  git check-ignore -q "${d}SKILL.md" && err "skills/$name/SKILL.md is ignored by git"
  head -n1 "${d}SKILL.md" | grep -qx -- '---' || err "skills/$name/SKILL.md: no frontmatter"
  grep -qx "name: $name" "${d}SKILL.md" || err "skills/$name/SKILL.md: frontmatter name != directory"
  desc=$(fm_value "${d}SKILL.md" description)
  if [ -z "$desc" ]; then
    err "skills/$name/SKILL.md: missing description"
  else
    [ "${#desc}" -le "$DESC_MAX" ] ||
      err "skills/$name/SKILL.md: description is ${#desc} chars, limit is $DESC_MAX"
    skill_descs="$skill_descs$name	$desc
"
  fi
  # Everything after the closing frontmatter delimiter is the instruction body.
  body=$(awk 'NR>1 && /^---$/ {found=1; next} found' "${d}SKILL.md" | tr -d '[:space:]')
  [ -n "$body" ] || err "skills/$name/SKILL.md: body after frontmatter is empty"
  grep -q "| \`$name\`" README.md || err "README skill table: missing $name"
  awk '/^```mermaid/,/^```$/' README.md | grep -q "\[$name\]" || err "README boundaries diagram: missing $name"
done

# Two skills with the same description make routing ambiguous: Claude has
# nothing to choose between them.
dupes=$(printf '%s' "$skill_descs" | awk -F'\t' '
  NF == 2 { if ($2 in seen) print seen[$2] ", " $1 ": " $2; else seen[$2] = $1 }')
[ -z "$dupes" ] || while IFS= read -r line; do
  err "duplicate skill description — $line"
done <<EOF
$dupes
EOF

# Whitelist lines must point at existing skill directories.
while IFS= read -r name; do
  [ -d "skills/$name" ] || err ".gitignore whitelists skills/$name which does not exist"
done < <(sed -n 's|^!/skills/\(.*\)/$|\1|p' .gitignore)

# README skill-table rows must point at existing skill directories.
# The backticks below are literal Markdown table syntax, not command substitution.
# shellcheck disable=SC2016
while IFS= read -r name; do
  [ -d "skills/$name" ] || err "README skill table lists $name but skills/$name does not exist"
done < <(sed -n 's/^| `\([a-z][a-z-]*\)`.*/\1/p' README.md)

# Commands need a description, and must appear in the README command table.
for f in commands/*.md; do
  name=$(basename "$f" .md)
  desc=$(fm_value "$f" description)
  if [ -z "$desc" ]; then
    err "$f: missing description"
  else
    [ "${#desc}" -le "$DESC_MAX" ] ||
      err "$f: description is ${#desc} chars, limit is $DESC_MAX"
  fi
  # A command is named by its filename; a `name:` key is a second source of
  # truth that will drift from it.
  name_key=$(grep -c '^name:' "$f")
  [ "$name_key" -eq 0 ] || err "$f: declares a name: key — the filename is the command name"
  # `allowed-tools:` is optional, but a declared-and-empty one silently grants
  # nothing rather than what the author meant.
  tools_lines=$(grep -c '^allowed-tools:' "$f")
  if [ "$tools_lines" -gt 1 ]; then
    err "$f: $tools_lines allowed-tools: lines — must be a single line"
  elif [ "$tools_lines" -eq 1 ]; then
    tools=$(fm_value "$f" allowed-tools)
    [ -n "$tools" ] || err "$f: allowed-tools: is declared with no value"
  fi
  grep -q "| \`/$name\`" README.md || err "README command table: missing /$name"
done

# README command-table rows must point at existing command files.
# The backticks below are literal Markdown table syntax, not command substitution.
# shellcheck disable=SC2016
while IFS= read -r name; do
  [ -f "commands/$name.md" ] || err "README command table lists /$name but commands/$name.md does not exist"
done < <(sed -n 's/^| `\/\([a-z][a-z-]*\)`.*/\1/p' README.md)
for f in output-styles/*.md; do
  grep -q '^name: .' "$f" || err "$f: missing name"
  grep -q '^description: .' "$f" || err "$f: missing description"
done

[ "$fail" -eq 0 ] && echo "OK: config is consistent"
exit "$fail"
