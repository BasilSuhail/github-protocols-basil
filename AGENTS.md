# AGENTS.md

## Repository Classification
- Visibility: [PUBLIC / PRIVATE]
- Owner: BasilSuhail

## Identity
- Author and email: from `~/.agents/protocol.conf` (untracked). Never hardcode them here.
- No Co-Authored-By lines. No AI attribution. Single author on all commits.

## Commits
- Use Conventional Commits: `type(scope): description`
- Allowed types: feat, fix, refactor, docs, test, chore, ci, security, audit, session, perf, build, revert
- Branch naming: `<type>/<slug>` (e.g. `feat/user-auth`, `fix/email-parser`)
- Keep subject lines under 72 characters, imperative mood
- Never use `git add -A` or `git add .` — stage only files relevant to the change
- Run tests and confirm zero failures before committing
- Never push directly to `main` or `master` — use PR workflow
- Reference issue numbers in commit messages: `fix: #4 migrate HTTPException`
- Use HEREDOC format for multi-line commit messages

## Branch Strategy
- Feature branches: `feat/<slug>`
- Bug fixes: `fix/<slug>`
- Docs/session: `docs/<slug>`, `session/<date>`
- Audit/review: `audit/<slug>`
- One branch per unique issue; reuse same branch for related work
- Squash commits to main, rebase for feature branches

## Pull Requests
- PRs must target the working branch (main unless specified)
- PR title: under 70 characters, descriptive
- PR body must include: Summary (what + why), Test plan (checklist)
- Run `codex review --base origin/main` or equivalent before creating PR
- All PRs require review before merge
- Close stale PRs with explanation

## Worktrees
- One branch per worktree, one agent session per worktree
- Naming: `wt-<issue-number>-<slug>`
- Keep `.worktrees/` in `.gitignore`
- Remove worktrees after merge; run cleanup scan weekly
- Never force-remove dirty worktrees
- Copy `.env*` files from main repo to new worktrees

## Issue Tracking (GitHub Issues)
- Begin session: select issue (P0/P1/P2), self-assign, post session plan
- During: post brief updates at milestones, update labels
- End session: post "What landed" summary with "Next steps", close or update
- Labels: P0-critical, P1-high, P2-medium, P3-low, security, session-handoff, audit-finding
- All issues must be atomic and linked to roadmap items
- Architecture/behavior changes: update docs in the same commit

## Secrets (Non-Negotiable)
- NEVER commit real API keys, tokens, passwords, or private keys
- Real secrets live in .env.local (gitignored) or deployment secret manager
- Sample config files must use obviously fake placeholders
- Never echo, cat, or print .env files
- Never print secrets to terminal output
- If Gitleaks pre-commit hook flags your commit, remove the secret — do not bypass
- NEVER use --no-verify to skip hooks

## Upstream Protection
- NEVER push or PR directly to upstream repos
- Only use BasilSuhail forks with explicit --repo flag
- Always verify target repo before gh pr/issue commands

## Completion Standard
- 100% completion required. No 80% work, no "good enough."
- Every change must be self-reviewed before push
- Self-review includes: re-read every changed file, verify tests pass, check edge cases
- If self-review takes 2 hours for a 10 minute fix, that is acceptable
- No partial implementations. Finish what you start or document what remains as issues.
- Verify the fix actually works — don't trust assumptions

## Session Protocol
- Start: read session handoff issue, review open issues
- During: reference issues in commits, post milestones
- End: create/update handoff docs, close completed issues
- Handoff docs: NEXT-SESSION-PROMPT.md, SESSION-HANDOFF.md, TODOS.md

## Basil Modes
- Caveman (ultra): short, 3-6 word sentences
- No filler, preamble, or pleasantries
- Tools first, show result, stop
- Drop articles when possible
- 1:1:1 rule: 1 issue -> 1 branch -> 1 PR -> 1 commit
- Always branch
- Always PR
- Never merge own PR
- Basil merges
- `lesstalk`: no narration after tool result unless asked
