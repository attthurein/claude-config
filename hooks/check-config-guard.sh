#!/usr/bin/env bash
# Stop-hook guard: report configuration drift once Claude finishes responding.
#
# Non-blocking by design. The check is advisory, and a partial copy of this
# configuration (skills taken without scripts/) must not break a session, so a
# missing script is a silent success rather than an error.
set -u

root="${CLAUDE_PLUGIN_ROOT:-${CLAUDE_PROJECT_DIR:-.}}"
script="$root/scripts/check-config.sh"

[ -f "$script" ] || exit 0
command -v bash >/dev/null 2>&1 || exit 0

# Capture first, then inspect: piping a producer into a short-circuiting reader
# makes pipefail report the reader's SIGPIPE instead of the real status.
output=$(bash "$script" 2>&1)
status=$?

if [ "$status" -ne 0 ]; then
  printf 'check-config reported drift:\n%s\n' "$output" >&2
fi

# Always exit 0: drift is surfaced, never enforced, from a Stop hook.
exit 0
