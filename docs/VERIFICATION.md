# Verification Guide

## Run It

```bash
bash verify.sh
```

Exit 0 means every rule is enforced and every installed copy matches this repo.
Exit 1 lists what failed.

## Why The Tests Look The Way They Do

Every behaviour test drives an adapter through the **same contract its real
caller uses**:

| Adapter | Contract the test reproduces |
|---------|------------------------------|
| `pretooluse.sh` | `{"tool_name":...,"tool_input":{"command":...}}` piped on stdin |
| `commit-msg` | path to a message file as `$1` |
| `pre-push` | remote name and URL as `$1`/`$2`, ref updates on stdin |

This is not a stylistic preference. The previous suite set
`CLAUDE_TOOL_NAME` / `CLAUDE_TOOL_INPUT` itself, which Claude Code never sets.
It reported PASS on every rule while all three hooks exited at their first line
in production. A test that invents a convenient input is worse than no test —
it converts a total enforcement failure into a green check.

The harness also strips every agent environment marker before each test, so the
suite cannot accidentally pass because it happened to run inside an agent.

## Coverage

- **Blocked**: `Co-Authored-By`, force push, `--force-with-lease`, `git add -A`,
  `git add .`, `--no-verify`, `git reset --hard`, `git clean -f`, `gh pr merge`,
  `gh` write commands without `--repo`, non-owned repo targets,
  non-conventional subjects, subjects over 72 chars, emoji, direct commits to
  `main`.
- **Allowed**: clean conventional commits, `gh` with `--repo`, unrelated shell
  commands, non-Bash tools, malformed payloads.
- **Override guard**: refused inside an agent session, honoured from a human
  shell.
- **Drift**: each installed file is byte-compared against this repo. A stale
  copy fails the suite.

## Manual Spot Checks

```bash
# Should print BLOCKED [ID-102] and exit 2
echo '{"tool_name":"Bash","tool_input":{"command":"git push --force origin main"}}' \
  | bash ~/.claude/hooks/pretooluse.sh; echo "exit=$?"

# Should exit 0
echo '{"tool_name":"Bash","tool_input":{"command":"git commit -m \"feat: x\""}}' \
  | bash ~/.claude/hooks/pretooluse.sh; echo "exit=$?"

# Per-repo hooks present after a templateDir refresh
ls -l /path/to/repo/.git/hooks/{pre-commit,commit-msg,pre-push}
```

## When A Test Fails

Fix the engine or the adapter. Do not relax the test to match current
behaviour, and do not add an override to make the suite green — overrides are
for one command in a human shell, never for CI.
