#!/usr/bin/env bash
# Protocol verification.
#
# Every behaviour test drives an adapter through the SAME contract the real
# caller uses — Claude Code pipes JSON on stdin, git passes a message file,
# git passes ref updates on stdin. A test that fabricates a convenient input
# is worse than no test: the previous version of this script set
# CLAUDE_TOOL_NAME/CLAUDE_TOOL_INPUT itself and therefore reported PASS while
# every hook in production was a no-op.

set -uo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export PROTOCOL_LIB="$REPO_DIR/lib/rules.sh"
PTU="$REPO_DIR/hooks/claude-code/pretooluse.sh"
CMSG="$REPO_DIR/hooks/git-templates/commit-msg"

# The suite must not hardcode an identity either.
[ -f "$HOME/.agents/protocol.conf" ] && . "$HOME/.agents/protocol.conf"
OWNER="${PROTOCOL_OWNER:-$(git config --get protocol.owner 2>/dev/null)}"

# CI runs the rules, not the machine. Installation state, global git config and
# a developer's local screen are meaningless on a runner, and asserting them
# there would make the suite fail for reasons unrelated to the rules.
CI_MODE="${PROTOCOL_CI:-0}"
machine_only() { [ "$CI_MODE" = "1" ] && return 1; return 0; }

# Assembled at runtime: ID-405 matches an AI authorship trailer in any tracked
# file, and the suite must not violate the rule it exists to test.
TRAILER="Co-Authored-$(printf %s By): $(printf %s Claude) <noreply@$(printf %s anthropic).com>"

PASS=0; FAIL=0
ok()   { echo "  PASS: $1"; PASS=$((PASS+1)); }
bad()  { echo "  FAIL: $1"; FAIL=$((FAIL+1)); }

# Strip every agent marker so the harness itself never influences a rule.
clean_env() { env -u CLAUDECODE -u CLAUDE_CODE_ENTRYPOINT -u CODEX_SANDBOX \
                  -u CODEX_HOME -u CURSOR_TRACE_ID -u AIDER_MODEL \
                  -u OPENCODE_SESSION -u GEMINI_CLI -u PROTOCOL_OVERRIDE "$@"; }

# expect_cmd <expected-exit> <description> <command-string>
expect_cmd() {
  local want="$1" desc="$2" cmd="$3" got
  printf '{"tool_name":"Bash","tool_input":{"command":%s}}' "$(printf '%s' "$cmd" | jq -Rs .)" \
    | clean_env bash "$PTU" >/dev/null 2>&1
  got=$?
  [ "$got" -eq "$want" ] && ok "$desc" || bad "$desc (want exit $want, got $got)"
}

# expect_msg <expected-exit> <description> <message>
expect_msg() {
  local want="$1" desc="$2" msg="$3" got tmp
  tmp=$(mktemp); printf '%s\n' "$msg" > "$tmp"
  clean_env bash "$CMSG" "$tmp" >/dev/null 2>&1; got=$?
  rm -f "$tmp"
  [ "$got" -eq "$want" ] && ok "$desc" || bad "$desc (want exit $want, got $got)"
}

echo "Protocol Verification"
echo "====================="
echo ""

echo "Rule engine:"
[ -f "$PROTOCOL_LIB" ] && ok "lib/rules.sh present" || bad "lib/rules.sh present"
bash -n "$PROTOCOL_LIB" 2>/dev/null && ok "lib/rules.sh parses" || bad "lib/rules.sh parses"
echo ""

echo "Claude Code adapter (real stdin JSON contract):"
expect_cmd 2 "blocks Co-Authored-By"        "git commit -m 'feat: x' --trailer '$TRAILER'"
expect_cmd 2 "blocks force push"            'git push --force origin main'
expect_cmd 2 "blocks force-with-lease"      'git push --force-with-lease origin feat/x'
expect_cmd 2 "blocks git add -A"            'git add -A'
expect_cmd 2 "blocks git add ."             'git add .'
expect_cmd 2 "blocks --no-verify"           'git commit --no-verify -m "fix: x"'
expect_cmd 2 "blocks git reset --hard"      'git reset --hard HEAD~3'
expect_cmd 2 "blocks git clean -fd"         'git clean -fd'
expect_cmd 2 "blocks gh pr merge"           'gh pr merge 4 --squash'
expect_cmd 2 "blocks gh create w/o --repo"  'gh issue create --title "x" --body "y"'
expect_cmd 2 "blocks non-owned repo target" 'gh pr create --repo someoneelse/theirrepo --title x'
expect_cmd 0 "allows clean commit"          'git commit -m "feat: add thing"'
expect_cmd 0 "allows gh with --repo"        "gh issue create --repo $OWNER/x --title y --body z"
expect_cmd 0 "allows unrelated command"     'ls -la'
echo ""

echo "Payloads are data, not invocations (regression):"
expect_cmd 0 "allows a force push quoted in a PR body" \
  "gh pr create --repo $OWNER/x --title y --body 'run: git push --force origin main'"
expect_cmd 0 "allows a trailer quoted in a PR body" \
  "gh pr create --repo $OWNER/x --title y --body 'never write Co-Authored-By: Someone'"
expect_cmd 0 "allows reading a file that documents the rules" \
  'cat GITHUB-RULES.md'
expect_cmd 0 "allows a heredoc body naming a blocked command" \
  "$(printf 'cat <<%s\ngit push --force origin main\nEOF' "EOF")"
expect_cmd 2 "still blocks a real force push after a safe one" \
  'git status && git push --force origin main'
echo ""

echo "Published text (ID-405, ID-406):"
# The session-link fixtures are assembled at runtime. Writing one as a literal
# would put a real transcript URL into a tracked file, which is the thing these
# two rules exist to prevent.
SESS="https://claude.%s/code/session_015ruUWtest"
SESS=$(printf "$SESS" "ai")
U="Users"
expect_cmd 2 "blocks a session link in a PR body" \
  "gh pr create --repo $OWNER/x --title y --body '$SESS'"
expect_cmd 2 "blocks a session link in a heredoc body" \
  "$(printf 'gh pr create --repo %s/x --title y --body-file - <<EOF\n%s\nEOF' "$OWNER" "$SESS")"
expect_cmd 2 "blocks a home path in a PR body" \
  "gh pr create --repo $OWNER/x --title y --body 'see /$U/alice/notes'"
expect_cmd 0 "allows a placeholder path in a PR body" \
  "gh pr create --repo $OWNER/x --title y --body 'see /$U/you/notes'"
expect_cmd 0 "allows a PR body quoting a prohibited command" \
  "gh pr create --repo $OWNER/x --title y --body 'never run git push --force'"
expect_cmd 0 "allows a clean PR body" \
  "gh pr create --repo $OWNER/x --title y --body 'Fixes the parser'"
expect_msg 1 "blocks a session link in a commit message" \
  "$(printf 'feat: x\n\n%s' "$SESS")"
expect_msg 0 "allows a commit message without one" 'feat: x'
echo ""

echo "Claude Code adapter (non-Bash and malformed payloads):"
echo '{"tool_name":"Read","tool_input":{"file_path":"/x"}}' | clean_env bash "$PTU" >/dev/null 2>&1 \
  && ok "ignores non-Bash tools" || bad "ignores non-Bash tools"
echo 'not json' | clean_env bash "$PTU" >/dev/null 2>&1 \
  && ok "survives malformed payload" || bad "survives malformed payload"
echo ""

echo "commit-msg adapter:"
expect_msg 0 "allows conventional subject"  'feat(auth): add token refresh'
expect_msg 0 "allows issue reference"       'fix: #12 prevent null pointer in parser'
expect_msg 1 "blocks non-conventional"      'added some stuff'
expect_msg 1 "blocks emoji"                 'feat: add sparkles 🚀'
expect_msg 1 "blocks >72 char subject"      "feat: $(printf 'x%.0s' $(seq 1 80))"
expect_msg 1 "blocks Co-Authored-By body"   "$(printf 'feat: x\n\n%s' "$TRAILER")"
echo ""

echo "Override guard (agents must never unblock themselves):"
printf '{"tool_name":"Bash","tool_input":{"command":"git push --force origin main"}}' \
  | CLAUDECODE=1 PROTOCOL_OVERRIDE=ID-102 bash "$PTU" >/dev/null 2>&1
[ $? -eq 2 ] && ok "refuses override inside an agent session" || bad "refuses override inside an agent session"
printf '{"tool_name":"Bash","tool_input":{"command":"git push --force origin feat/x"}}' \
  | clean_env PROTOCOL_OVERRIDE=ID-102 PROTOCOL_OVERRIDE_LOG=/dev/null bash "$PTU" >/dev/null 2>&1
[ $? -eq 0 ] && ok "honours override from a human shell" || bad "honours override from a human shell"
echo ""

if machine_only; then
echo "Installed copies match this repo:"
for pair in \
  "$HOME/.agents/lib/rules.sh:lib/rules.sh" \
  "$HOME/.claude/hooks/pretooluse.sh:hooks/claude-code/pretooluse.sh" \
  "$HOME/.git-templates/hooks/pre-commit:hooks/git-templates/pre-commit" \
  "$HOME/.git-templates/hooks/commit-msg:hooks/git-templates/commit-msg" \
  "$HOME/.git-templates/hooks/pre-push:hooks/git-templates/pre-push"; do
  dst="${pair%%:*}"; src="$REPO_DIR/${pair##*:}"
  if [ ! -f "$dst" ]; then bad "$(basename "$dst") installed"
  elif cmp -s "$dst" "$src"; then ok "$(basename "$dst") installed and current"
  else bad "$(basename "$dst") is STALE — re-run install.sh"; fi
done
fi
echo ""

echo "Identifier screen (ID-401):"
SCREEN_TMP=$(mktemp -d)
cat > "$SCREEN_TMP/screen.sh" <<'SCR'
screen_files() {
  for f in "$@"; do
    grep -q 'ZZ_TEST_IDENTIFIER' "$f" 2>/dev/null && { echo "BLOCKED $f"; return 1; }
  done
  return 0
}
SCR
printf 'contact ZZ_TEST_IDENTIFIER here\n' > "$SCREEN_TMP/dirty.txt"
printf 'nothing to see\n' > "$SCREEN_TMP/clean.txt"
if clean_env bash -c ". '$PROTOCOL_LIB'; PROTOCOL_SCREEN='$SCREEN_TMP/screen.sh' rule_personal_identifiers '$SCREEN_TMP/dirty.txt'" >/dev/null 2>&1; then
  bad "screen blocks a flagged file"
else
  ok "screen blocks a flagged file"
fi
if clean_env bash -c ". '$PROTOCOL_LIB'; PROTOCOL_SCREEN='$SCREEN_TMP/screen.sh' rule_personal_identifiers '$SCREEN_TMP/clean.txt'" >/dev/null 2>&1; then
  ok "screen passes a clean file"
else
  bad "screen passes a clean file"
fi
if clean_env bash -c ". '$PROTOCOL_LIB'; PROTOCOL_SCREEN=/nonexistent HOME='$SCREEN_TMP' rule_personal_identifiers '$SCREEN_TMP/dirty.txt'" >/dev/null 2>&1; then
  ok "absent screen is inactive, not a failure"
else
  bad "absent screen is inactive, not a failure"
fi
rm -rf "$SCREEN_TMP"
if machine_only; then
  if [ -f "$HOME/.agents/lib/personal-identifiers.sh" ]; then
    ok "a real screen is installed on this machine"
  else
    bad "no screen at ~/.agents/lib/personal-identifiers.sh — ID-401 is inactive"
  fi
fi
if git ls-files --error-unmatch lib/personal-identifiers.sh >/dev/null 2>&1; then
  bad "a real screen is TRACKED — it must never be committed"
else
  ok "no real screen is tracked in this repo"
fi
echo ""

if machine_only; then
echo "This repo's own hooks (git init never overwrites):"
RH="$REPO_DIR/$(git -C "$REPO_DIR" rev-parse --git-path hooks)"
for h in pre-commit commit-msg pre-push; do
  if [ ! -f "$RH/$h" ]; then bad "$h present in .git/hooks"
  elif cmp -s "$RH/$h" "$REPO_DIR/hooks/git-templates/$h"; then ok "$h is current"
  else bad "$h is STALE — bash scripts/refresh-repo-hooks.sh"; fi
done
fi
echo ""

echo "Leak rules (ID-402 to ID-404):"
LK=$(mktemp -d)
# Fixtures are assembled at runtime. Writing them as literals would put a
# private IP, a home directory path and a personal address into this tracked
# file -- the exact strings these rules exist to keep out of the repository.
# The suite's own fixtures must not violate the suite.
printf 'host 192.%s.1.44 is the box\n' "168"        > "$LK/ip.txt"
printf 'see /%s/alice/folders/thing\n'  "Users"     > "$LK/path.txt"
printf 'mail me at alice@%s.com\n'      "gmail"     > "$LK/mail.txt"
printf 'credit: alice@%s.com for this\n' "gmail"    > "$LK/NOTICE"
printf 'host 8.8.8.8 and /%s/you/x\n'   "Users"     > "$LK/ok.txt"

leak() { # <rule> <file> <expected 0 pass|1 block> <desc>
  local got
  clean_env bash -c ". '$PROTOCOL_LIB'; $1 '$LK/$2'" >/dev/null 2>&1; got=$?
  [ "$got" -eq "$3" ] && ok "$4" || bad "$4 (want $3, got $got)"
}
leak rule_no_private_ips    ip.txt    1 "blocks a private IP"
leak rule_no_local_paths    path.txt  1 "blocks a home directory path"
leak rule_no_personal_email mail.txt  1 "blocks a personal email"
leak rule_no_personal_email NOTICE    0 "allows a personal email in NOTICE"
leak rule_no_private_ips    ok.txt    0 "allows a public IP"
leak rule_no_local_paths    ok.txt    0 "allows a placeholder path"
rm -rf "$LK"
echo ""

echo "Identity is not hardcoded:"
if grep -rIqE '[A-Za-z0-9._%+-]+@(gmail|outlook|hotmail|yahoo|icloud|proton)\.' \
     --exclude-dir=.git --exclude=NOTICE --exclude=verify.sh "$REPO_DIR"; then
  bad "no personal email address is tracked"
else
  ok "no personal email address is tracked"
fi
[ -n "$OWNER" ] && ok "PROTOCOL_OWNER resolved ($OWNER)" || bad "PROTOCOL_OWNER resolved"
machine_only && { [ -f "$HOME/.agents/protocol.conf" ] \
  && ok "protocol.conf exists" || bad "protocol.conf exists"; }
if git -C "$REPO_DIR" ls-files --error-unmatch protocol.conf >/dev/null 2>&1; then
  bad "protocol.conf is TRACKED — it must never be committed"
else
  ok "protocol.conf is not tracked"
fi
echo ""

if machine_only; then
echo "Skill allowlist:"
if [ -f "$REPO_DIR/skills.allowlist" ]; then
  extra=""
  for dir in "$HOME"/.claude/skills/*/; do
    [ -d "$dir" ] || continue
    n=$(basename "$dir")
    grep -qE "^[[:space:]]*${n}[[:space:]]*$" "$REPO_DIR/skills.allowlist" || extra="$extra $n"
  done
  [ -z "$extra" ] && ok "no unlisted skills installed" \
                  || bad "unlisted skills present:$extra — re-run install.sh"
  while read -r want; do
    case "$want" in ''|\#*) continue ;; esac
    [ -d "$HOME/.claude/skills/$want" ] && ok "allowlisted skill present: $want" \
      || bad "allowlisted skill missing: $want"
  done < "$REPO_DIR/skills.allowlist"
fi
echo ""

echo "Vendored skills:"
for sk in "$REPO_DIR"/skills/*/; do
  [ -d "$sk" ] || continue
  n=$(basename "$sk")
  d="$HOME/.claude/skills/$n/SKILL.md"
  if [ ! -f "$d" ]; then bad "skill $n installed"
  elif cmp -s "$d" "$sk/SKILL.md"; then ok "skill $n installed and current"
  else bad "skill $n is STALE — re-run install.sh"; fi
  head -5 "$sk/SKILL.md" | grep -q '^name:' && ok "skill $n has frontmatter" || bad "skill $n has frontmatter"
done
grep -q '^Revision:' "$REPO_DIR/NOTICE" 2>/dev/null \
  && ok "NOTICE records an upstream revision" || bad "NOTICE records an upstream revision"
fi
echo ""

if machine_only; then
echo "Global git config:"
git config --global user.email 2>/dev/null | grep -q noreply.github.com \
  && ok "email is noreply" || bad "email is noreply"
git config --global init.templateDir 2>/dev/null | grep -q git-templates \
  && ok "template dir set" || bad "template dir set"
fi
echo ""

if machine_only; then
echo "Global config is deduplicated:"
S="$HOME/.claude/settings.json"
if grep -qE 'CAVEMAN|1:1:1 PROTOCOL' "$S" 2>/dev/null; then
  bad "no hand-rolled style hooks (the caveman plugin owns response style)"
else
  ok "no hand-rolled style hooks (the caveman plugin owns response style)"
fi
if grep -q 'any-buddy' "$S" 2>/dev/null; then
  bad "no SessionStart hook pointing at an uninstalled binary"
else
  ok "no SessionStart hook pointing at an uninstalled binary"
fi
CMD_FILE="$HOME/.claude/CLAUDE.md"
N=$(grep -c 'BEGIN protocol (generated' "$CMD_FILE" 2>/dev/null || echo 0)
[ "$N" = "1" ] && ok "CLAUDE.md has exactly one generated block" \
                || bad "CLAUDE.md has $N generated blocks, expected 1"
if [ -f "$CMD_FILE" ]; then
  EXPECT=$(sed "s/@OWNER@/$OWNER/g" "$REPO_DIR/templates/claude-md-block.tmpl")
  GOT=$(awk '/BEGIN protocol \(generated/{f=1;next} /END protocol/{f=0} f' "$CMD_FILE")
  [ "$EXPECT" = "$GOT" ] && ok "generated block is current" || bad "generated block is STALE — re-run install.sh"
fi
echo ""

echo "Claude Code registration:"
if grep -q 'pretooluse.sh' "$HOME/.claude/settings.json" 2>/dev/null; then
  ok "pretooluse.sh registered in settings.json"
else
  bad "pretooluse.sh registered in settings.json"
fi
if grep -qE 'git-commit-guard|git-push-guard|self-review-gate' "$HOME/.claude/settings.json" 2>/dev/null; then
  bad "stale guard hooks still registered — remove them from settings.json"
else
  ok "no stale guard hooks registered"
fi
fi
echo ""

echo "Tooling:"
command -v gitleaks >/dev/null 2>&1 && ok "gitleaks installed" || bad "gitleaks installed"
command -v jq >/dev/null 2>&1 && ok "jq installed" || bad "jq installed"
echo ""

echo "====================="
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] && { echo "ALL SYSTEMS OPERATIONAL"; exit 0; }
echo "ISSUES FOUND — review failures above"
exit 1
