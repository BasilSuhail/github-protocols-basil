---
name: github-rules
description: Complete GitHub workflow rules for Basil Suhail — feed this file into any agentic coding tool (Claude Code, Codex CLI/app, OpenCode, Cursor, Gemini CLI, Windsurf, Continue.dev) to enforce universal git hygiene
paths: ["**"]
alwaysApply: true
---

# GitHub Rules — Basil Suhail

> Feed this file into any agentic coding tool as AGENTS.md, CLAUDE.md, .cursorrules, GEMINI.md, or equivalent.
> All rules are non-negotiable unless explicitly overridden by the user in conversation.

---

## 1. Identity

**Single author. No exceptions.**

| Field | Value |
|-------|-------|
| Name | `Basil Suhail` |
| Email | `BasilSuhail@users.noreply.github.com` |
| GitHub | `BasilSuhail` |

### Absolute Prohibitions
- NEVER include `Co-Authored-By` trailers in commit messages
- NEVER use `noreply@anthropic.com` or any AI co-author attribution
- NEVER use personal email `[PRIVATE_EMAIL]` in any commit
- NEVER include IP addresses (`192.168.*`, `10.*`) in committed code
- NEVER include machine hostnames or local filesystem paths in commits
- NEVER commit from an account other than `BasilSuhail`

### Pre-Commit Email Check
Before your first commit in any session or repo, verify:
```bash
git config user.email
# Must return: *@users.noreply.github.com
# If not: git config user.email "BasilSuhail@users.noreply.github.com"
```

---

## 2. Commit Messages

### Format: Conventional Commits
```
type(scope): description

[optional body]
[optional footer]
```

### Allowed Types
| Type | When to Use |
|------|------------|
| `feat` | New feature or capability |
| `fix` | Bug fix |
| `refactor` | Code restructuring without behavior change |
| `docs` | Documentation only |
| `test` | Adding or fixing tests |
| `chore` | Maintenance, dependencies, tooling |
| `ci` | CI/CD pipeline changes |
| `security` | Security hardening |
| `audit` | From CEO/Eng review findings |
| `session` | Session artifacts, handoffs |
| `perf` | Performance improvement |
| `build` | Build system changes |
| `revert` | Reverting a previous commit |

### Rules
- Subject line: under 72 characters, imperative mood ("add" not "added")
- Reference issue numbers inline: `fix: #4 migrate HTTPException`
- Multi-line messages: use HEREDOC format or body after blank line
- NO trailing `Co-Authored-By` lines (this is absolute)
- NO emoji in commit messages

### Examples
```
feat(auth): add JWT token refresh endpoint
fix: #12 prevent null pointer in email parser
docs: session 10 handoff with resumption prompt
security: scrub PII from docker config and gitignore
refactor(pipeline): extract scene planner into separate module
```

---

## 3. Staging & File Management

### Rules
- NEVER use `git add -A` or `git add .` — stage only files relevant to the change
- Review staged files before committing: `git diff --cached --name-only`
- NEVER stage `.env`, `.env.*`, `credentials.*`, or files containing secrets
- NEVER stage `package-lock.json` unless dependency changes are intentional
- NEVER stage large binary files (images, videos, compiled artifacts)

### Verification Before Commit
```bash
# Always check what you're about to commit
git diff --cached --name-only
git diff --cached --stat
```

---

## 4. Branch Strategy

### Naming Convention
```
<type>/<slug>
```

| Pattern | Example |
|---------|---------|
| Feature | `feat/user-auth` |
| Bug fix | `fix/email-parser` |
| Documentation | `docs/api-reference` |
| Session work | `session/2026-04-10-report` |
| Audit findings | `audit/security-review` |
| Chore/maintenance | `chore/update-deps` |

### Rules
- NEVER commit directly to `main` or `master`. Always use feature branches + PRs.
- One branch per unique issue. Reuse the same branch for related work on the same issue.
- Squash commits when merging to main. Rebase feature branches before PR.
- Delete branches after merge (locally and remote).
- 1:1:1 rule: 1 issue -> 1 branch -> 1 PR -> 1 commit.
- Basil merges. Agents never merge their own PRs.

---

## 5. Pull Requests

### PR Title
- Under 70 characters
- Descriptive of the change, not the branch name
- Use imperative mood

### PR Body Template
```markdown
## Summary
- [What changed and why, 1-3 bullets]

## Test Plan
- [ ] Unit tests pass
- [ ] Integration tests pass
- [ ] Manual verification done
- [ ] Edge cases checked
```

### Rules
- Review code before creating PR (self-review at minimum)
- Run full test suite before creating PR
- Close stale PRs with an explanatory comment
- NEVER merge without passing tests
- NEVER merge with unresolved review comments
- Agents stop after PR creation unless Basil explicitly asks for more

---

## 5.1 Agent Style

### Caveman (ultra)
- Use short, 3-6 word sentences
- No filler, preamble, or pleasantries
- Drop articles when possible
- Max compression

### lesstalk
- Run tools first
- Show result
- Stop
- Do not narrate tool use unless user asks

---

## 6. Hooks & Safety

### Non-Negotiable
- NEVER use `--no-verify` to skip pre-commit or pre-push hooks
- NEVER use `--force` or `-f` with `git push`
- NEVER use `git reset --hard` without explicit user approval
- NEVER use `git clean -f` without explicit user approval
- NEVER amend published commits (commits already pushed to remote)
- If a hook blocks your commit, fix the underlying issue — do not bypass

### Enforcement Architecture

Every rule is defined once, in `lib/rules.sh`, with a stable ID. Adapters hold
no rules of their own — they translate their caller's input format and hand it
to the engine. A rule therefore cannot be tightened in one layer and forgotten
in three.

| Adapter | Input contract | Binds |
|---------|----------------|-------|
| `hooks/claude-code/pretooluse.sh` | JSON on stdin (`tool_name`, `tool_input.command`) | Claude Code |
| `hooks/git-templates/pre-commit` | staged file list and content | every tool |
| `hooks/git-templates/commit-msg` | final message file | every tool |
| `hooks/git-templates/pre-push` | remote URL, ref updates on stdin | every tool |

Claude Code does **not** set `CLAUDE_TOOL_NAME` or `CLAUDE_TOOL_INPUT`. Any hook
reading those env vars silently enforces nothing.

Rules judge what a command **invokes**, not text it carries. A pull-request body
or a test fixture that quotes a prohibited command is documentation, not an
action. The engine drops heredoc bodies, splits on shell separators and matches
only real invocation segments, because a guard that fires on prose is a guard
the author turns off.

### Rule IDs

| ID | Rule |
|----|------|
| ID-001 | `user.email` must end in `users.noreply.github.com` |
| ID-002 | No `Co-Authored-By` trailer |
| ID-003 | No AI attribution |
| ID-101 | No `--no-verify` / `--no-gpg-sign` |
| ID-102 | No force push, no non-fast-forward push |
| ID-103 | No `git add -A` / `git add .` |
| ID-104 | No `git reset --hard` / `git clean -f` |
| ID-105 | Target repo must be owned by `BasilSuhail` |
| ID-106 | `gh` write commands require `--repo` |
| ID-107 | No direct commit or push to `main` / `master` |
| ID-108 | Agents never run `gh pr merge` |
| ID-201 | No secret patterns in staged content |
| ID-202 | No `.env`, credential, or key files staged |
| ID-203 | Gitleaks must pass on the staged diff |
| ID-301 | Subject must be a Conventional Commit |
| ID-302 | Subject at most 72 characters |
| ID-303 | No emoji in commit messages |

Every rule blocks. There are no advisory rules — an agent reads a warning and
proceeds anyway, which is indistinguishable from having no rule.

### Overrides

`PROTOCOL_OVERRIDE=<rule-id>` waives one rule for one command, and only from a
human's own shell. It is refused whenever an agent environment marker is
present, so an agent can never unblock itself. Accepted overrides are logged to
`~/.agents/override.log`.

---

## 7. Upstream Protection

### Rules
- NEVER push to or create PRs on upstream repositories
- Only use `BasilSuhail/*` forks for all development unless explicitly overridden
- ALWAYS use `--repo BasilSuhail/<repo-name>` flag with `gh` CLI commands
- NEVER rely on default repo detection from git remotes — always specify explicitly

### Why
Accidental upstream PRs happen when `gh` defaults to upstream remotes. Explicit `--repo` prevents that.

---

## 8. Secrets Management

### Non-Negotiable
- NEVER commit real API keys, tokens, passwords, or private keys
- NEVER hardcode secrets in source code
- Secrets live in `.env.local` (gitignored) or deployment secret manager only
- Sample/example config files MUST use obviously fake placeholders:
  ```
  API_KEY=your_api_key_here
  DATABASE_URL=postgresql://user:password@localhost:5432/dbname
  ```
- NEVER print, echo, cat, or log secrets to terminal output
- NEVER request users paste secrets into the chat
- If Gitleaks pre-commit hook flags your commit, remove the secret — do not bypass

### Secret Scanning
- Gitleaks v8.30.1 is installed and runs in pre-commit and pre-push hooks
- GitHub Push Protection is recommended at repo/org level for additional safety
- Scans for 200+ patterns: AWS, GCP, Stripe, OpenAI, GitHub tokens, SSH keys

---

## 9. Session Protocol

### Start of Session
1. Read open issues: `gh issue list -R BasilSuhail/<repo> -l session-handoff`
2. Check for `NEXT-SESSION-PROMPT.md` in repo root
3. Select a task (P0 > P1 > P2 priority)
4. Self-assign the issue

### During Session
- Reference issue numbers in commit messages: `fix: #4 migrate HTTPException`
- Post brief updates at key milestones on the issue
- Update labels as work progresses

### End of Session
1. Create/update handoff documents:
   - `NEXT-SESSION-PROMPT.md` — copy-paste prompt for continuation
   - `SESSION-HANDOFF.md` — full context + completed work + known issues
   - `TODOS.md` — task tracking with GitHub issue references
2. Post "What landed" summary with "Next steps" on the issue
3. Close completed issues
4. Update master handoff issue (`Video-Generation#11`)

### Issue Labels
| Label | Color | Meaning |
|-------|-------|---------|
| `P0-critical` | Red | Launch blocker |
| `P1-high` | Orange | Fix this sprint |
| `P2-medium` | Yellow | Next sprint |
| `P3-low` | Green | Nice to have |
| `security` | Purple | Security-related |
| `session-handoff` | Blue | Cross-session context |
| `audit-finding` | Gray | From CEO/Eng review |

---

## 10. Completion Standard (100%)

### The Rule
Every task must be completed to 100%. No 80% work. No "good enough." No partial implementations.

### Self-Review Protocol (Mandatory Before Every Push)
1. **Re-read every changed file** — line by line, not skimming
2. **Verify tests pass** — run the actual test suite, do not assume
3. **Check edge cases** — empty input, null values, boundary conditions
4. **Verify the fix works** — run it and observe the result, don't trust assumptions
5. **Review for security** — XSS, injection, secrets, PII exposure
6. **Check for regressions** — did fixing X break Y?

### Time Investment
- If self-review takes 2 hours for a 10-minute fix, that is acceptable
- Quality is measured by correctness, not by speed
- Rushing creates more work via bugs and regressions

### What "Done" Means
- All tests pass (the full suite, not just new tests)
- No TODO/FIXME left without a tracked GitHub issue
- Documentation updated if behavior changed
- Edge cases handled, not ignored
- Code reviewed (self-review at minimum)
- Verified working — actually ran it, actually saw it work

### What Is NOT Acceptable
- Scoring work at "8/10" and calling it complete
- Leaving known issues unfixed with "we'll handle it later"
- Pushing code that hasn't been tested
- Trusting automated quality gate scores without manual verification
- Starting new work while previous work is incomplete

### Surgical Edit Policy
Learned from BallersBank Session 5 (13 commits degraded output from 7.0/10 to 0/10):
1. Make ONE change at a time
2. Run the pipeline/tests after EACH change
3. Observe the output — watch it, inspect frames, read logs
4. If output degrades, REVERT immediately
5. Never launch parallel agents editing different files simultaneously
6. Trust convergence data over assumptions

---

## 11. Code Quality

### Python
- Formatter: `ruff` (line-length=120, target py312)
- Type checking: `mypy` strict mode
- Testing: `pytest`, minimum 70% coverage
- Package manager: `uv`

### TypeScript / JavaScript
- ESLint + TypeScript strict mode
- Package manager: `bun`
- Framework: Next.js App Router (when applicable)

### Security
- Environment variables for all credentials
- Never commit `.env` files
- No XSS, SQL injection, or command injection — validate inputs at boundaries
- JWT auth + SSO where applicable

### Error Handling
- Do NOT remove error logging catch blocks
- Keep `logger.error` + `raise` — they provide operation-specific observability context
- Don't delete entire try/except blocks during refactoring

### Documentation
- Update docs when behavior changes — in the same commit
- Don't add docstrings to code you didn't change
- Only add comments where the logic isn't self-evident

---

## 12. Versioning

### Semantic Versioning
- Start at `v1.0.0-beta.1` (honest semver)
- Patch (bug fix): `1.0.1`, `1.0.2`
- Minor (new feature): `1.1.0`, `1.2.0`
- Major (breaking rehaul): `2.0.0`
- Pre-release: `-beta.1`, `-beta.2`, `-rc.1`
- NEVER use inflated version numbers

### Changelog
- Maintain `CHANGELOG.md` per release
- Categories: Added, Changed, Fixed, Security, Breaking Changes
- Auto-generate from conventional commit messages where possible
- Write release notes in user-facing language

---

## 13. Worktree Rules

For parallel development with git worktrees:
- One branch per worktree, one agent session per worktree
- Naming: `wt-<issue-number>-<slug>` (e.g., `wt-1234-auth`)
- Keep `.worktrees/` in `.gitignore`
- Copy `.env*` files from main repo to new worktrees
- Remove worktrees after merge; run cleanup scan weekly
- Never force-remove dirty worktrees

---

## Cross-Platform Compatibility

This file works as:

| Tool | File Name | Location |
|------|-----------|----------|
| Claude Code | `CLAUDE.md` | Repo root or `~/CLAUDE.md` |
| Codex CLI/app | `AGENTS.md` | Repo root or `~/.codex/AGENTS.md` |
| Cursor | `.cursorrules` | Repo root |
| Gemini CLI | `GEMINI.md` | Repo root |
| OpenCode | `AGENTS.md` | Repo root |
| Windsurf | `.windsurfrules` | Repo root |
| Continue.dev | `.continuerules` | Repo root |
| Any amplified.dev | `AGENTS.md` | `~/.agents/rules/` |
