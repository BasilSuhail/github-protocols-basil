# GitHub Protocols Basil

Universal GitHub workflow pack for Basil-first, fork-safe development.
Built from Shaheer's protocol system.
Retargeted for `BasilSuhail/*`.
Extended with Basil agent rules.

---

## Table Of Contents

1. [What This Is](#what-this-is)
2. [Basil Additions](#basil-additions)
3. [Architecture](#architecture)
4. [Directory Structure](#directory-structure)
5. [Quick Install](#quick-install)
6. [Repo Rules](#repo-rules)
7. [Recommended Flow](#recommended-flow)
8. [Rule Files](#rule-files)
9. [What Changed From Shaheer Version](#what-changed-from-shaheer-version)
10. [What Gets Enforced](#what-gets-enforced-autonomously)
11. [Completion Standard](#completion-standard)

---

## What This Is

A single source of truth for git workflow enforcement across:
- **Claude Code** (direct harness)
- **Codex** (CLI + app)
- **OpenCode**, **Cursor**, **Gemini CLI**, **Windsurf**, **Continue.dev**
- **Any `.agents/`-compatible tool** following the [amplified.dev](https://amplified.dev) standard

Use this when goal is:
- keep all work on `BasilSuhail/*`
- block accidental upstream PRs and pushes
- enforce Basil identity
- enforce short caveman-style agent output
- enforce `1:1:1`

---

## Basil Additions

### 1. Caveman
- short, 3-6 word sentences
- low fluff
- drop articles when possible
- compress hard

### 2. 1:1:1
- 1 issue
- 1 branch
- 1 PR
- 1 commit
- always branch
- always PR
- never self-merge
- Basil merges

### 3. lesstalk
- tools first
- result next
- stop
- no narration unless asked

### 4. Fork-Safe GitHub
- default owner = `BasilSuhail`
- explicit `--repo BasilSuhail/<repo>`
- treat non-Basil remotes as upstream unless user overrides
- block upstream push patterns in hooks

---

## Architecture

```
3-Layer Defense
===============

Layer 1: Global Git Config (~/.gitconfig)
  - Basil noreply email globally enforced
  - Template dir auto-applies hooks to new repos
  - Push/pull defaults

Layer 2: Claude Code Hooks (~/.claude/settings.json)
  - git-commit-guard.sh — blocks PII, Co-Authored-By, --no-verify
  - git-push-guard.sh — blocks force push, upstream leaks, --no-verify
  - self-review-gate.sh — advisory 100% completion reminder

Layer 3: Git Hook Templates (~/.git-templates/hooks/)
  - pre-commit — email, secrets, PII, Gitleaks, linting
  - pre-push — force push, upstream protection, Gitleaks

Layer 4: Agent Rules (~/.codex, ~/.agents, repo AGENTS.md)
  - Basil identity
  - Basil fork safety
  - caveman
  - 1:1:1
  - lesstalk
```

---

## Directory Structure

```
github-protocols-basil/
  AGENTS.md                    # Universal rules (auto-loaded by Codex/agents)
  rules/
    agent-style.md             # Caveman, 1:1:1, lesstalk
    git-workflow.md            # Git workflow enforcement rules
    completion-standard.md     # 100% completion standard
    code-quality.md            # Code quality standards
  hooks/
    claude-code/
      git-commit-guard.sh      # Claude Code PreToolUse hook
      git-push-guard.sh        # Claude Code PreToolUse hook
      self-review-gate.sh      # Claude Code PreToolUse hook
    git-templates/
      pre-commit               # Global git pre-commit hook
      pre-push                 # Global git pre-push hook
  templates/
    gitconfig                  # Global git config template
    pre-commit-config.yaml     # Pre-commit framework config
    gitleaks.toml              # Gitleaks configuration
  docs/
    INSTALLATION.md            # Step-by-step setup guide
    VERIFICATION.md            # How to verify everything works
```

---

## Quick Install

```bash
# 1. Clone this repo
git clone git@github.com:BasilSuhail/github-protocols-basil.git ~/github-protocols-basil

# 2. Run the installer
bash ~/github-protocols-basil/install.sh

# 3. Verify
bash ~/github-protocols-basil/verify.sh
```

Install targets:
- `~/.codex/AGENTS.md`
- `~/.codex/rules/*.md`
- `~/.agents/rules/*.md`
- `~/.git-templates/hooks/*`
- optional `~/.claude/hooks/*`

---

## Repo Rules

- Owner: `BasilSuhail`
- Identity: `Basil Suhail <BasilSuhail@users.noreply.github.com>`
- Never push directly to upstream
- Never create PRs on upstream by default
- Always verify target repo before `gh` commands
- Prefer branch naming: `feat/<slug>`, `fix/<slug>`, `docs/<slug>`
- Squash to `main`

---

## Recommended Flow

```bash
# 1. pick issue
gh issue list --repo BasilSuhail/<repo>

# 2. branch
git checkout -b fix/<slug>

# 3. work
# 4. test
# 5. commit once

# 6. push to Basil fork only
git push -u origin fix/<slug>

# 7. open PR on Basil fork only
gh pr create --repo BasilSuhail/<repo> --base main --head fix/<slug>
```

---

## Rule Files

| File | Purpose |
|------|---------|
| `AGENTS.md` | Global agent contract for Basil workflow |
| `rules/agent-style.md` | `caveman`, `1:1:1`, `lesstalk` |
| `rules/git-workflow.md` | branch, commit, PR, push rules |
| `rules/completion-standard.md` | 100% completion rule |
| `rules/code-quality.md` | test, docs, code hygiene |
| `hooks/claude-code/git-commit-guard.sh` | blocks bad commit patterns |
| `hooks/claude-code/git-push-guard.sh` | blocks bad push targets |
| `hooks/git-templates/pre-commit` | repo-local pre-commit safety |
| `hooks/git-templates/pre-push` | repo-local pre-push safety |
| `templates/gitconfig` | Basil git identity template |
| `docs/INSTALLATION.md` | setup instructions |
| `docs/VERIFICATION.md` | post-install checks |

---

## What Changed From Shaheer Version

- owner changed to `BasilSuhail`
- identity changed to Basil noreply
- upstream protection retargeted to Basil-first workflow
- `agent-style.md` added
- `caveman` added
- `1:1:1` added
- `lesstalk` added
- install docs retargeted
- hook messages retargeted
- README retargeted

---

## What Gets Enforced (Autonomously)

| Rule | Layer | Blocks? |
|------|-------|---------|
| Noreply email on all commits | All 3 | YES |
| No Co-Authored-By trailers | Layer 2 | YES |
| No personal email in commits | All 3 | YES |
| No `--no-verify` bypass | Layer 2+3 | YES |
| No force push | Layer 2+3 | YES |
| No upstream repo interaction | Layer 2+3 | YES |
| No secrets in commits | Layer 3 | YES |
| No `.env` files committed | Layer 3 | YES |
| Conventional commit format | Layer 2 | WARNING |
| No `git add -A` | Layer 2 | WARNING |
| Self-review before push | Layer 2 | ADVISORY |
| 100% completion standard | Rules | ADVISORY |
| Spec update with source changes | Layer 3 | ADVISORY |
| Caveman / lesstalk / 1:1:1 | Rules | YES |

---

## Completion Standard

Every task must be completed to 100%. No 80% work. Self-review is mandatory before every push.
See `rules/completion-standard.md` for the full protocol.

---

## Attribution

This repo is adapted from protocol work created by [@ShaheerKhawaja](https://github.com/ShaheerKhawaja).
Base system, structure, and original protocol direction came from his `github-protocols` project.
This Basil version retargets that work for `BasilSuhail/*` workflow, Basil identity, and Basil-specific agent rules.
