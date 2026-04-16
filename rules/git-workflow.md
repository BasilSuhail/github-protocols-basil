---
name: git-workflow
description: Universal Git workflow rules for Basil Suhail — enforced across all agentic coding tools
paths: ["**"]
alwaysApply: true
---

# Git Workflow Rules (Universal)

These rules apply to ALL repositories, ALL branches, ALL tools.

## Identity

- Author name: `Basil Suhail`
- Author email: `BasilSuhail@users.noreply.github.com`
- NEVER include Co-Authored-By trailers. Single author on every commit.
- NEVER use personal email `[PRIVATE_EMAIL]` in any commit.
- NEVER include IP addresses, machine hostnames, or local paths in committed code.
- Before your first commit in any repo, verify: `git config user.email` returns a noreply.github.com address. If not, set it: `git config user.email "BasilSuhail@users.noreply.github.com"`

## Commit Messages

- Use Conventional Commits format: `type(scope): description`
- Allowed types: `feat`, `fix`, `refactor`, `docs`, `test`, `chore`, `ci`, `security`, `audit`, `session`, `perf`, `build`, `revert`
- Subject line: under 72 characters, imperative mood ("add", not "added")
- Reference issue numbers inline: `fix: #4 migrate HTTPException`
- Multi-line messages: use HEREDOC format or a body after blank line
- NEVER include Co-Authored-By in commit messages

## Staging

- NEVER use `git add -A` or `git add .` — stage only files relevant to the change
- Review staged files before committing: `git diff --cached --name-only`
- NEVER stage `.env`, `credentials.*`, or files containing secrets

## Branching

- NEVER commit directly to `main` or `master`. Use feature branches + PRs.
- Branch naming: `<type>/<slug>` (e.g., `feat/user-auth`, `fix/email-parser`)
- One branch per unique issue. Reuse the same branch for related work.
- Squash commits when merging to main. Rebase feature branches.

## Pull Requests

- PR title: under 70 characters
- PR body must include: Summary (what changed + why) and Test plan
- Review code before creating PR (self-review or `/review`)
- Close stale PRs with an explanatory comment
- NEVER merge without passing tests

## Hooks & Safety

- NEVER use `--no-verify` to skip pre-commit or pre-push hooks
- NEVER use `--force` or `-f` with `git push`
- NEVER use `git reset --hard` without explicit user approval
- If a hook blocks your commit, fix the underlying issue — do not bypass
- Pre-commit checks: email verification, secret scanning, PII detection
- Pre-push checks: force push prevention, upstream protection

## Upstream Protection

- NEVER push to or create PRs on upstream repos
- Only use BasilSuhail forks unless user explicitly overrides
- Always use `--repo BasilSuhail/<repo-name>` with `gh` CLI commands
- Verify target repo before any `gh pr` or `gh issue` command

## Secrets

- NEVER commit API keys, tokens, passwords, or private keys
- Secrets live in `.env.local` (gitignored) or deployment secret manager
- NEVER print, echo, cat, or log secrets to terminal
- Use obviously fake placeholders in sample config files
- If Gitleaks flags your commit, the secret must be removed — no bypass

## Session Protocol

- Start: read open issues, select task, check for session handoff docs
- During: reference issue numbers in commits, post milestone updates
- End: create/update handoff docs, close completed issues
- Handoff docs: `NEXT-SESSION-PROMPT.md`, `SESSION-HANDOFF.md`, `TODOS.md`
