#!/usr/bin/env bash
# Protocol Rule Engine — single source of truth for every enforcement adapter.
#
# Adapters (Claude Code PreToolUse, git hooks, CI) parse their own input format,
# then call the protocol_check_* entrypoints below. A rule is defined exactly
# once here so that no adapter can drift from the documented protocol.
#
# Sourced, never executed directly.
#
# Rule IDs are stable and referenced by GITHUB-RULES.md and AGENTS.md.
#   ID-0xx  identity
#   ID-1xx  safety
#   ID-2xx  secrets
#   ID-3xx  commit format
#   ID-4xx  leak / personal identifiers / PII

# Identity lives in an untracked config, not in this file. The handle is
# unavoidable -- it is the repository URL -- but a real name, a real address and
# a home directory path are not, and this file is public.
PROTOCOL_CONF="${PROTOCOL_CONF:-$HOME/.agents/protocol.conf}"
if [ -f "$PROTOCOL_CONF" ]; then
  # shellcheck source=/dev/null
  . "$PROTOCOL_CONF"
fi

PROTOCOL_EMAIL_SUFFIX="${PROTOCOL_EMAIL_SUFFIX:-users.noreply.github.com}"
# `git config --get` exits 1 when the key is unset. Under `set -e` -- which is
# how GitHub Actions runs every step -- that aborts the shell the moment this
# file is sourced, taking the whole job down before a single rule runs.
PROTOCOL_OWNER="${PROTOCOL_OWNER:-$(git config --get protocol.owner 2>/dev/null || true)}"
PROTOCOL_OVERRIDE_LOG="${PROTOCOL_OVERRIDE_LOG:-$HOME/.agents/override.log}"

# Files that name people on purpose. Attribution is the point of a NOTICE and
# of a credits section, and a licence that requires attribution cannot be
# honoured by a repo whose own rules forbid it. Exempt from the identity rules
# only -- never from the secret rules.
PROTOCOL_ATTRIBUTION_RE="${PROTOCOL_ATTRIBUTION_RE:-(^|/)(NOTICE|LICENSE|LICENCE|AUTHORS|CREDITS)(\\.[a-z]+)?$}"

_protocol_is_attribution() {
  printf '%s' "$1" | grep -qE "$PROTOCOL_ATTRIBUTION_RE"
}

PROTOCOL_VIOLATIONS=0

# --- override machinery -----------------------------------------------------

# An agent must never be able to unblock itself. Overrides are refused whenever
# an agent environment marker is present, so PROTOCOL_OVERRIDE only works from a
# human's own shell.
_protocol_agent_present() {
  [ -n "${CLAUDECODE:-}${CLAUDE_CODE_ENTRYPOINT:-}${CODEX_SANDBOX:-}${CODEX_HOME:-}" ] && return 0
  [ -n "${CURSOR_TRACE_ID:-}${AIDER_MODEL:-}${OPENCODE_SESSION:-}${GEMINI_CLI:-}" ] && return 0
  return 1
}

# _protocol_overridden <rule-id> -> 0 when a human has waived this rule
_protocol_overridden() {
  local id="$1"
  case ",${PROTOCOL_OVERRIDE:-}," in
    *",$id,"*) ;;
    *) return 1 ;;
  esac

  if _protocol_agent_present; then
    echo "REFUSED: PROTOCOL_OVERRIDE=$id ignored — agent session detected." >&2
    echo "         Overrides are human-only. Run the command from your own shell." >&2
    return 1
  fi

  mkdir -p "$(dirname "$PROTOCOL_OVERRIDE_LOG")" 2>/dev/null || true
  printf '%s\t%s\t%s\t%s\n' \
    "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$id" "${PWD}" "${PROTOCOL_CONTEXT:-unknown}" \
    >> "$PROTOCOL_OVERRIDE_LOG" 2>/dev/null || true
  return 0
}

# _protocol_fail <rule-id> <message> [fix-hint]
_protocol_fail() {
  local id="$1" msg="$2" fix="${3:-}"
  _protocol_overridden "$id" && {
    echo "OVERRIDE [$id] $msg (waived by human)" >&2
    return 0
  }
  echo "BLOCKED [$id] $msg" >&2
  [ -n "$fix" ] && echo "         Fix: $fix" >&2
  PROTOCOL_VIOLATIONS=$((PROTOCOL_VIOLATIONS + 1))
  return 1
}

# --- command decomposition --------------------------------------------------

# A rule must judge what a command RUNS, not text the command happens to carry.
# `gh pr create --body "...<a force push example>..."` documents a force push;
# it does not perform one. Matching the raw string flagged prose, tests and PR
# bodies alike, and a guard that fires on documentation gets disabled by the
# person it stops.
#
# So: drop heredoc bodies, split on shell separators, strip leading env
# assignments and wrappers, and keep the segments that actually invoke something.

_protocol_strip_heredocs() {
  printf '%s\n' "$1" | awk '
    {
      line = $0
      if (skip) {
        t = line; sub(/^[[:space:]]+/, "", t)
        if (t == term) skip = 0
        next
      }
      if (match(line, /<<-?[[:space:]]*["\x27]?[A-Za-z_][A-Za-z0-9_]*["\x27]?/)) {
        term = substr(line, RSTART, RLENGTH)
        sub(/^<<-?[[:space:]]*/, "", term)
        gsub(/["\x27]/, "", term)
        skip = 1
      }
      print line
    }'
}

# _protocol_segments <command> -> one invocation per line, payloads removed
_protocol_segments() {
  _protocol_strip_heredocs "$1" \
    | tr ';|&\n' '\n\n\n\n' \
    | sed -e 's/^[[:space:]]*//' -e 's/^\$[[:space:]]*//' \
    | sed -e 's/^\([A-Za-z_][A-Za-z0-9_]*=[^[:space:]]*[[:space:]]*\)*//' \
    | sed -e 's/^\(sudo\|command\|nohup\)[[:space:]]*//'
}

# _protocol_invocations <command> <regex> -> matching segments, or 1 if none
_protocol_invocations() {
  local found
  found=$(_protocol_segments "$1" | grep -E "$2" || true)
  [ -z "$found" ] && return 1
  printf '%s\n' "$found"
}

# --- identity ---------------------------------------------------------------

rule_noreply_email() { # ID-001
  local email
  email=$(git config user.email 2>/dev/null || true)
  [ -z "$email" ] && {
    _protocol_fail "ID-001" "git user.email is not set." \
      "git config user.email '${PROTOCOL_OWNER}@${PROTOCOL_EMAIL_SUFFIX}'"
    return
  }
  case "$email" in
    *"$PROTOCOL_EMAIL_SUFFIX") return 0 ;;
    *) _protocol_fail "ID-001" "git user.email is '$email' — must end in $PROTOCOL_EMAIL_SUFFIX." \
         "git config user.email '${PROTOCOL_OWNER}@${PROTOCOL_EMAIL_SUFFIX}'" ;;
  esac
}

# Scoped to git commit/push invocations. Scanning every command string flagged
# any command that merely contained the phrase, this rule engine included.
rule_no_coauthor() { # ID-002
  local segs
  segs=$(_protocol_invocations "$1" '^git[[:space:]]+(commit|push)') || return 0
  printf '%s' "$segs" | grep -qi 'co-authored-by' || return 0
  _protocol_fail "ID-002" "Co-Authored-By trailer is prohibited. Single author only."
}

rule_no_ai_attribution() { # ID-003
  local segs
  segs=$(_protocol_invocations "$1" '^git[[:space:]]+(commit|push)') || return 0
  printf '%s' "$segs" | grep -qiE 'noreply@anthropic\.com|generated with \[?claude|co-authored-by: *(claude|codex|copilot|cursor)' || return 0
  _protocol_fail "ID-003" "AI attribution detected. Commits carry a single human author."
}

# Text variants. A commit message is content, so it is scanned whole; a shell
# command is an invocation, so only its git segments are. Same rule ID, two
# contexts -- the message layer is what catches a trailer added by an editor,
# a template, or a HEREDOC the command layer never sees.
rule_no_coauthor_text() { # ID-002
  printf '%s' "$1" | grep -qi 'co-authored-by' || return 0
  _protocol_fail "ID-002" "Co-Authored-By trailer is prohibited. Single author only."
}

rule_no_ai_attribution_text() { # ID-003
  printf '%s' "$1" | grep -qiE 'noreply@anthropic\.com|generated with \[?claude|co-authored-by: *(claude|codex|copilot|cursor)' || return 0
  _protocol_fail "ID-003" "AI attribution detected. Commits carry a single human author."
}

# --- safety -----------------------------------------------------------------

rule_no_verify_bypass() { # ID-101
  local segs
  segs=$(_protocol_invocations "$1" '^git[[:space:]]') || return 0
  printf '%s' "$segs" | grep -qE -- '--no-verify|--no-gpg-sign' || return 0
  _protocol_fail "ID-101" "Hook bypass flag detected. Fix the underlying violation instead."
}

rule_no_force_push() { # ID-102
  local segs
  segs=$(_protocol_invocations "$1" '^git[[:space:]]+push') || return 0
  printf '%s' "$segs" | grep -qE -- '(--force([^-]|$)|--force-with-lease|[[:space:]]-f([[:space:]]|$))' || return 0
  _protocol_fail "ID-102" "Force push is prohibited."
}

rule_no_blanket_add() { # ID-103
  _protocol_invocations "$1" '^git[[:space:]]+add[[:space:]]+(-A([[:space:]]|$)|--all|\.([[:space:]]|$))' >/dev/null || return 0
  _protocol_fail "ID-103" "Blanket staging is prohibited — it sweeps in .env, keys, and binaries." \
    "Stage explicit paths: git add path/to/file"
}

rule_no_destructive_git() { # ID-104
  _protocol_invocations "$1" '^git[[:space:]]+(reset[[:space:]]+--hard|clean[[:space:]]+-[a-z]*f)' >/dev/null || return 0
  _protocol_fail "ID-104" "Destructive git command requires explicit human approval."
}

# Called with a command (cmd context) or a bare remote URL (pre-push context).
rule_upstream_protection() { # ID-105
  local target="$1" segs
  if printf '%s' "$target" | grep -qE '^(https?://|git@|ssh://)'; then
    segs="$target"
  else
    segs=$(_protocol_invocations "$target" '^(git|gh)[[:space:]]') || return 0
  fi
  printf '%s' "$segs" | grep -qiE 'github\.com[:/]|--repo[= ]|git@' || return 0
  if [ -z "$PROTOCOL_OWNER" ]; then
    _protocol_fail "ID-105" "PROTOCOL_OWNER is not set, so no repo can be recognised as yours." \
      "Set it in $PROTOCOL_CONF (see protocol.conf.example)"
    return
  fi
  printf '%s' "$segs" | grep -qi "$PROTOCOL_OWNER" && return 0
  _protocol_fail "ID-105" "Target does not name $PROTOCOL_OWNER — refusing to touch a non-owned repo." \
    "Use $PROTOCOL_OWNER forks only."
}

rule_gh_requires_repo() { # ID-106
  local segs
  segs=$(_protocol_invocations "$1" '^gh[[:space:]]+(pr|issue|release)[[:space:]]+(create|edit|merge|close|comment)') || return 0
  printf '%s' "$segs" | grep -q -- '--repo' && return 0
  _protocol_fail "ID-106" "gh write command without --repo. Default remote detection causes upstream leaks." \
    "Add --repo $PROTOCOL_OWNER/<repo>"
}

rule_no_direct_main() { # ID-107
  local branch="$1"
  case "$branch" in
    main|master)
      _protocol_fail "ID-107" "Direct commit or push to '$branch' is prohibited. Branch and open a PR." \
        "git checkout -b <type>/<slug>" ;;
    *) return 0 ;;
  esac
}

rule_never_merge() { # ID-108
  _protocol_invocations "$1" '^gh[[:space:]]+pr[[:space:]]+merge' >/dev/null || return 0
  _protocol_fail "ID-108" "Agents never merge pull requests. $PROTOCOL_OWNER merges."
}

# --- secrets ----------------------------------------------------------------

PROTOCOL_SECRET_RE='AKIA[0-9A-Z]{16}|sk-[a-zA-Z0-9_-]{20,}|ghp_[a-zA-Z0-9]{36}|gho_[a-zA-Z0-9]{36}|github_pat_[a-zA-Z0-9_]{22,}|xox[baprs]-[a-zA-Z0-9-]{10,}|-----BEGIN [A-Z ]*PRIVATE KEY-----|(password|passwd|secret|token)[[:space:]]*[:=][[:space:]]*["\x27][^"\x27]{8,}'

rule_no_secrets_in_files() { # ID-201
  [ "$#" -eq 0 ] && return 0
  local hits
  hits=$(grep -lE "$PROTOCOL_SECRET_RE" "$@" 2>/dev/null || true)
  [ -z "$hits" ] && return 0
  _protocol_fail "ID-201" "Possible secret in: $(echo "$hits" | tr '\n' ' ')" \
    "Move it to .env.local or a secret manager."
}

rule_no_env_files() { # ID-202
  local hits
  hits=$(printf '%s\n' "$@" | grep -E '(^|/)\.env($|\.)|(^|/)credentials(\.|$)|\.pem$|\.p12$|id_rsa' || true)
  [ -z "$hits" ] && return 0
  _protocol_fail "ID-202" "Credential file staged: $(echo "$hits" | tr '\n' ' ')"
}

rule_gitleaks_staged() { # ID-203
  command -v gitleaks >/dev/null 2>&1 || return 0
  gitleaks protect --staged --no-banner >/dev/null 2>&1 && return 0
  _protocol_fail "ID-203" "Gitleaks found a secret in the staged diff." \
    "gitleaks protect --staged --verbose"
}

# --- leak / personal identifiers -------------------------------------------

# The term list is deliberately NOT in this repository. Names of people and
# institutions cannot be published in the file whose job is to stop them being
# published, so the screen is a local, untracked file and this rule only knows
# how to find and call it. See lib/personal-identifiers.example.sh.
rule_personal_identifiers() { # ID-401
  [ "$#" -eq 0 ] && return 0
  local candidate keep=""
  for candidate in "$@"; do
    _protocol_is_attribution "$candidate" || keep="$keep $candidate"
  done
  # shellcheck disable=SC2086
  set -- $keep
  [ "$#" -eq 0 ] && return 0
  for candidate in \
    "${PROTOCOL_SCREEN:-}" \
    "$HOME/.agents/lib/personal-identifiers.sh" \
    "$(git rev-parse --git-path hooks 2>/dev/null)/personal-identifiers.sh" \
    "$HOME/.git-templates/hooks/personal-identifiers.sh"; do
    if [ -n "$candidate" ] && [ -f "$candidate" ]; then
      # shellcheck source=/dev/null
      . "$candidate"
      break
    fi
  done

  # No screen installed is not a violation — the mechanism is opt-in per machine.
  declare -F screen_files >/dev/null 2>&1 || return 0

  screen_files "$@" && return 0
  _protocol_fail "ID-401" "Personal or third-party identifier in staged content."
}

# Generic leak rules. Unlike ID-401 these name no individual, so they can ship
# in a public repository and protect a machine that has no local screen.

# RFC1918 and link-local. Public addresses are not flagged: a documentation
# example or a DNS root server is not a disclosure, and flagging every dotted
# quad trains you to ignore the rule.
PROTOCOL_PRIVATE_IP_RE='(^|[^0-9.])(192\.168\.[0-9]{1,3}\.[0-9]{1,3}|10\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}|172\.(1[6-9]|2[0-9]|3[01])\.[0-9]{1,3}\.[0-9]{1,3}|169\.254\.[0-9]{1,3}\.[0-9]{1,3})([^0-9]|$)'

rule_no_private_ips() { # ID-402
  [ "$#" -eq 0 ] && return 0
  local hits
  hits=$(grep -lE "$PROTOCOL_PRIVATE_IP_RE" "$@" 2>/dev/null || true)
  [ -z "$hits" ] && return 0
  _protocol_fail "ID-402" "Private network address in: $(echo "$hits" | tr '\n' ' ')" \
    "Use a hostname such as db.example.com, or describe the range in words."
}

# A home directory path leaks the account name and the machine's layout, and it
# is never portable, so it is a defect on its own terms.
PROTOCOL_LOCAL_PATH_RE='(/Users/[A-Za-z0-9._-]+|/home/[A-Za-z0-9._-]+|C:\\\\Users\\\\[A-Za-z0-9._-]+)'

rule_no_local_paths() { # ID-403
  [ "$#" -eq 0 ] && return 0
  local f hits found=""
  for f in "$@"; do
    [ -f "$f" ] || continue
    # A generic example path names nobody.
    hits=$(grep -nE "$PROTOCOL_LOCAL_PATH_RE" "$f" 2>/dev/null \
           | grep -vE '/(Users|home)/(you|user|username|me|example|<[a-z]+>)' | head -3 || true)
    [ -n "$hits" ] && found="$found$f: $hits
"
  done
  [ -z "$found" ] && return 0
  _protocol_fail "ID-403" "Local filesystem path:
$found" "Write \$HOME or ~ instead."
}

PROTOCOL_PERSONAL_EMAIL_RE='[A-Za-z0-9._%+-]+@(gmail|googlemail|outlook|hotmail|live|yahoo|icloud|me|proton|protonmail|pm)\.[a-z.]{2,}'

rule_no_personal_email() { # ID-404
  [ "$#" -eq 0 ] && return 0
  local f hits found=""
  for f in "$@"; do
    [ -f "$f" ] || continue
    _protocol_is_attribution "$f" && continue
    hits=$(grep -nEi "$PROTOCOL_PERSONAL_EMAIL_RE" "$f" 2>/dev/null \
           | grep -vEi '(you|user|username|someone|example|name)@' | head -3 || true)
    [ -n "$hits" ] && found="$found$f: $hits
"
  done
  [ -z "$found" ] && return 0
  _protocol_fail "ID-404" "Personal email address:
$found" "Commit under the noreply address only."
}

# Agent harnesses append a session identifier to commit messages and pull
# request bodies by default. That URL points at a private transcript. It is the
# single most common way a private link reaches a public repository, and it
# arrives without anyone deciding to put it there.
PROTOCOL_SESSION_RE='(claude\.ai/code/session[_-][A-Za-z0-9]|chatgpt\.com/(c|share)/[A-Za-z0-9]|Claude-Session:[[:space:]]*http|Generated with \[?(Claude|Codex|Copilot|Cursor)|Co-Authored-By:[[:space:]]*(Claude|Codex|Copilot|Cursor))'

rule_no_session_links() { # ID-405
  local text="$1"
  printf '%s' "$text" | grep -qiE "$PROTOCOL_SESSION_RE" || return 0
  _protocol_fail "ID-405" "Agent session link or AI attribution." \
    "Commits and pull requests carry a single human author and no transcript link."
}

rule_no_session_links_in_files() { # ID-405
  [ "$#" -eq 0 ] && return 0
  local f keep=""
  for f in "$@"; do
    [ -f "$f" ] || continue
    _protocol_is_attribution "$f" && continue
    keep="$keep $f"
  done
  [ -z "$keep" ] && return 0
  local hits
  # shellcheck disable=SC2086
  hits=$(grep -lEi "$PROTOCOL_SESSION_RE" $keep 2>/dev/null || true)
  [ -z "$hits" ] && return 0
  _protocol_fail "ID-405" "Agent session link in: $(echo "$hits" | tr '\n' ' ')"
}

# Text an agent publishes to GitHub. This is the most public surface in the
# workflow and had no rule attached to it.
#
# Unlike every other command rule, this one reads the RAW command, heredocs
# included, because a body is routinely supplied on standard input. It is
# looking for what the text CONTAINS, not for what the command RUNS -- so a body
# quoting a prohibited command stays allowed, which is the distinction #3
# established and this must not undo.
rule_gh_published_text() { # ID-406
  local raw="$1"
  _protocol_invocations "$raw" '^gh[[:space:]]+(pr|issue|release|gist)[[:space:]]+(create|edit|comment)' >/dev/null || return 0

  local what=""
  printf '%s' "$raw" | grep -qiE "$PROTOCOL_SESSION_RE"        && what="$what session-link"
  printf '%s' "$raw" | grep -qEi "$PROTOCOL_PERSONAL_EMAIL_RE" && what="$what personal-email"
  printf '%s' "$raw" | grep -qE  "$PROTOCOL_PRIVATE_IP_RE"     && what="$what private-ip"
  printf '%s' "$raw" | grep -qE  "$PROTOCOL_LOCAL_PATH_RE" \
    && ! printf '%s' "$raw" | grep -qE '/(Users|home)/(you|user|username|me|example)' \
    && what="$what local-path"
  printf '%s' "$raw" | grep -qE  "$PROTOCOL_SECRET_RE"         && what="$what secret"

  [ -z "$what" ] && return 0
  _protocol_fail "ID-406" "Publishing to GitHub with:$what" \
    "Anything posted to a public repo is copied beyond recall. Remove it from the body."
}

# --- commit format ----------------------------------------------------------

PROTOCOL_COMMIT_TYPES='feat|fix|refactor|docs|test|chore|ci|security|audit|session|perf|build|style|revert'

rule_conventional_subject() { # ID-301
  local subject="$1"
  echo "$subject" | grep -qE "^($PROTOCOL_COMMIT_TYPES)(\(.+\))?!?: .+" && return 0
  echo "$subject" | grep -qE '^(Merge|Revert) ' && return 0
  # GitHub's web editor writes the subject itself -- "Update README.md" and the
  # like -- and the person editing never sees a prompt for one. Rejecting those
  # makes editing a file on github.com impossible, which is too high a price for
  # a naming convention.
  echo "$subject" | grep -qE '^(Update|Create|Delete|Rename) .+|^Add files via upload$' && return 0
  _protocol_fail "ID-301" "Subject is not a Conventional Commit: '$subject'" \
    "type(scope): description   types: $PROTOCOL_COMMIT_TYPES"
}

rule_subject_length() { # ID-302
  local subject="$1"
  [ "${#subject}" -le 72 ] && return 0
  # Merge and revert subjects are generated by git, and CI hosts fabricate
  # their own ("Merge <sha> into <sha>") to test a PR. Their length is not the
  # author's choice, so holding an author to it fails builds for no reason.
  echo "$subject" | grep -qE '^(Merge|Revert) ' && return 0
  _protocol_fail "ID-302" "Subject is ${#subject} chars, limit is 72."
}

rule_no_emoji() { # ID-303
  printf '%s' "$1" | LC_ALL=C grep -q $'\xf0\x9f' || return 0
  _protocol_fail "ID-303" "Emoji are prohibited in commit messages."
}

# --- entrypoints ------------------------------------------------------------

# protocol_check_cmd <command-string>
# Rules that can be judged from a shell command an agent is about to run.
protocol_check_cmd() {
  local cmd="$1"
  PROTOCOL_VIOLATIONS=0
  PROTOCOL_CONTEXT="cmd"

  rule_no_verify_bypass "$cmd"
  rule_no_force_push "$cmd"
  rule_no_blanket_add "$cmd"
  rule_no_destructive_git "$cmd"
  rule_gh_requires_repo "$cmd"
  rule_never_merge "$cmd"
  rule_upstream_protection "$cmd"
  rule_gh_published_text "$cmd"

  rule_no_coauthor "$cmd"
  rule_no_ai_attribution "$cmd"
  if _protocol_invocations "$cmd" '^git[[:space:]]+(commit|push)' >/dev/null; then
    rule_noreply_email
  fi

  return "$PROTOCOL_VIOLATIONS"
}

# protocol_check_msg <commit-message-file-or-text>
protocol_check_msg() {
  local text="$1" subject
  [ -f "$text" ] && text=$(cat "$text")
  PROTOCOL_VIOLATIONS=0
  PROTOCOL_CONTEXT="msg"

  subject=$(printf '%s\n' "$text" | grep -v '^#' | sed '/^[[:space:]]*$/d' | head -1)

  rule_conventional_subject "$subject"
  rule_subject_length "$subject"
  rule_no_emoji "$text"
  rule_no_coauthor_text "$text"
  rule_no_ai_attribution_text "$text"
  rule_no_session_links "$text"

  return "$PROTOCOL_VIOLATIONS"
}

# protocol_check_staged
# Content rules over the staged tree. Reads the staged file list itself.
protocol_check_staged() {
  local files existing
  PROTOCOL_VIOLATIONS=0
  PROTOCOL_CONTEXT="staged"

  rule_noreply_email
  rule_no_direct_main "$(git symbolic-ref --short HEAD 2>/dev/null || echo detached)"

  files=$(git diff --cached --name-only --diff-filter=ACMR 2>/dev/null || true)
  if [ -n "$files" ]; then
    # shellcheck disable=SC2046
    rule_no_env_files $files
    existing=$(printf '%s\n' "$files" | while read -r f; do [ -f "$f" ] && printf '%s\n' "$f"; done)
    # shellcheck disable=SC2086
    rule_no_secrets_in_files $existing
    # shellcheck disable=SC2086
    rule_personal_identifiers $existing
    # shellcheck disable=SC2086
    rule_no_private_ips $existing
    # shellcheck disable=SC2086
    rule_no_local_paths $existing
    # shellcheck disable=SC2086
    rule_no_personal_email $existing
    # shellcheck disable=SC2086
    rule_no_session_links_in_files $existing
  fi
  rule_gitleaks_staged

  return "$PROTOCOL_VIOLATIONS"
}

# protocol_check_refs <remote-url>   (ref updates arrive on stdin, git pre-push format)
protocol_check_refs() {
  local url="$1" local_ref local_sha remote_ref remote_sha branch
  PROTOCOL_VIOLATIONS=0
  PROTOCOL_CONTEXT="refs"

  rule_noreply_email
  rule_upstream_protection "$url"

  while read -r local_ref local_sha remote_ref remote_sha; do
    [ -z "$remote_ref" ] && continue
    branch="${remote_ref#refs/heads/}"
    rule_no_direct_main "$branch"
    # Non-fast-forward to an existing remote ref is a force push.
    if [ "$remote_sha" != "0000000000000000000000000000000000000000" ] \
       && [ "$local_sha" != "0000000000000000000000000000000000000000" ]; then
      git merge-base --is-ancestor "$remote_sha" "$local_sha" 2>/dev/null \
        || _protocol_fail "ID-102" "Non-fast-forward push to '$branch' — this is a force push."
    fi
  done

  return "$PROTOCOL_VIOLATIONS"
}
