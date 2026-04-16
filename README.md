# GitHub Protocols

Universal GitHub workflow protocols, git hooks, and agent rules for Basil-first fork-safe development.

## What This Is

A single source of truth for git workflow enforcement across:
- **Claude Code** (direct harness)
- **Codex** (CLI + app)
- **OpenCode**, **Cursor**, **Gemini CLI**, **Windsurf**, **Continue.dev**
- **Any `.agents/`-compatible tool** following the [amplified.dev](https://amplified.dev) standard

## Architecture

```
3-Layer Defense
===============

Layer 1: Global Git Config (~/.gitconfig)
  - Noreply email globally enforced
  - Template dir auto-applies hooks to new repos
  - Push/pull defaults

Layer 2: Claude Code Hooks (~/.claude/settings.json)
  - git-commit-guard.sh — blocks PII, Co-Authored-By, --no-verify
  - git-push-guard.sh — blocks force push, upstream leaks, --no-verify
  - self-review-gate.sh — advisory 100% completion reminder

Layer 3: Git Hook Templates (~/.git-templates/hooks/)
  - pre-commit — email, secrets, PII, Gitleaks, linting
  - pre-push — force push, upstream protection, Gitleaks
```

## Directory Structure

```
github-protocols/
  AGENTS.md                    # Universal rules (auto-loaded by Codex/agents)
  rules/
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

## Quick Install

```bash
# 1. Clone this repo
git clone git@github.com:BasilSuhail/github-protocols-basil.git ~/github-protocols-basil

# 2. Run the installer
bash ~/github-protocols-basil/install.sh

# 3. Verify
bash ~/github-protocols-basil/verify.sh
```

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

## Completion Standard

Every task must be completed to 100%. No 80% work. Self-review is mandatory before every push.
See `rules/completion-standard.md` for the full protocol.
