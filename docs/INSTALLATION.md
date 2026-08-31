# Installation Guide

## Prerequisites

- Git 2.40+
- GitHub CLI (`gh`): `brew install gh`
- Gitleaks: `brew install gitleaks`
- jq: `brew install jq`

## Install

```bash
bash install.sh
bash verify.sh
```

`install.sh` is the supported path. It writes global git config, installs the
rule engine and every adapter, retires superseded hooks, and registers the
Claude Code adapter in `settings.json` (backing the file up first).

Registration used to be a manual step. That is exactly how three hooks stayed
registered under names that no longer enforced anything, so the installer now
does it.

## What Gets Installed Where

| Path | Purpose |
|------|---------|
| `~/.agents/lib/rules.sh` | Rule engine. Every rule is defined here once. |
| `~/.claude/hooks/pretooluse.sh` | Claude Code adapter (reads stdin JSON) |
| `~/.git-templates/hooks/pre-commit` | Staged-content adapter |
| `~/.git-templates/hooks/commit-msg` | Commit-message adapter |
| `~/.git-templates/hooks/pre-push` | Ref-update adapter |
| `~/.agents/rules/*.md` | Prose rules for any agent tool |
| `~/.codex/rules/*.md`, `~/.codex/AGENTS.md` | Codex CLI/app |
| `~/.agents/lib/personal-identifiers.sh` | Identifier screen. **Untracked, never pushed.** |

Adapters do not contain rules. They translate their caller's input format and
hand it to the engine, so a rule cannot be fixed in one layer and forgotten in
three.

## Apply To Existing Repos

`git init` is **not** enough. It copies a template hook only when no file of
that name already exists, and it never overwrites. A repo set up before a hook
changed keeps running the old hook indefinitely, while the template directory
looks perfectly current.

```bash
bash scripts/refresh-repo-hooks.sh                 # current repo
bash scripts/refresh-repo-hooks.sh ~/code/a ~/code/b
bash scripts/refresh-repo-hooks.sh --all ~/folders # every repo under a root
```

This only replaces hook files. It does not touch history or config.

## Per-Repo Setup (New Projects)

```bash
cp AGENTS.md /path/to/new/repo/AGENTS.md
cp templates/gitleaks.toml /path/to/new/repo/.gitleaks.toml
```

## The Identifier Screen (ID-401)

The list of names, institutions and contact details to block cannot live in
this repository. A blocklist committed to a public repo publishes exactly the
strings it exists to suppress. So the screen is a local file the engine looks
for and calls; the repo ships only a placeholder example.

```bash
cp lib/personal-identifiers.example.sh ~/.agents/lib/personal-identifiers.sh
# then edit it with your real terms — that path is never tracked or pushed
```

Without it, ID-401 is inactive and the rest of the protocol is unaffected.
`install.sh` adopts a screen you already have and never overwrites one.

## Overrides

A blocked rule is meant to stop you. When a block is genuinely wrong, waive one
rule for one command **from your own shell**:

```bash
PROTOCOL_OVERRIDE=ID-102 git push --force-with-lease origin feat/x
```

Overrides are refused whenever an agent environment marker is present, so no
agent can waive a rule on its own. Every accepted override is appended to
`~/.agents/override.log`.

## Uninstall

```bash
rm -rf ~/.agents/lib ~/.git-templates/hooks
rm -f ~/.claude/hooks/pretooluse.sh
# then remove the pretooluse.sh entry from ~/.claude/settings.json
```
