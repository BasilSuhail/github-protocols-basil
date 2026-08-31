# GitHub Protocols Basil

Universal GitHub workflow pack for Basil-first, fork-safe development.
Built from Shaheer's protocol system.
Retargeted for `BasilSuhail/*`.
Extended with Basil agent rules.

---

## 1. Quick Install

```bash
# 1. Clone this repo
gh repo clone BasilSuhail/github-protocols-basil ~/github-protocols-basil

# 2. Run the installer
bash ~/github-protocols-basil/install.sh

# 3. Verify
bash ~/github-protocols-basil/verify.sh
```

Then once:

```bash
# push hooks into repos you already have
bash ~/github-protocols-basil/scripts/refresh-repo-hooks.sh --all ~/folders

# lock main on GitHub
bash ~/github-protocols-basil/scripts/apply-github-ruleset.sh
```

Install targets:
- `~/.agents/lib/rules.sh`
- `~/.agents/rules/*.md`
- `~/.agents/protocol.conf`
- `~/.codex/AGENTS.md`
- `~/.codex/rules/*.md`
- `~/.cursor/rules/*.mdc`
- `~/.git-templates/hooks/*`
- `~/.claude/hooks/pretooluse.sh`
- `~/.claude/skills/*`

---

## 2. Protocols and Skills

### 1. Identity
- noreply email on all commits
- no Co-Authored-By trailers
- no AI credited as author
- no personal email in commits

### 2. Safety
- no `--no-verify` bypass
- no force push
- no `git add -A` or `git add .`
- no `git reset --hard` or `git clean -f`
- no upstream repo interaction
- `gh` commands use `--repo`
- no commits straight to `main`
- agents never merge

### 3. Secrets
- no API keys, tokens, passwords
- no `.env` or credential files
- gitleaks clean

### 4. Commits
- conventional format
- subject 72 chars or fewer
- no emoji

### 5. Privacy
- no personal names or institutions
- no private IPs
- no home directory paths
- no personal emails
- no agent session links
- text posted to GitHub is scanned

### 6. Skills

- **A. `karpathy-guidelines`**
  - i) think before coding — state assumptions, ask when unclear
  - ii) simplicity first — minimum code, nothing speculative
  - iii) surgical changes — touch only what you must
  - iv) goal-driven — define success, loop until verified

- **B. `agent-style`**
  - i) caveman — short 3-6 word sentences, max compression
  - ii) 1:1:1 — 1 issue, 1 branch, 1 PR, 1 commit
  - iii) lesstalk — tools first, result next, stop

- **C. `git-workflow`**
  - i) identity from `~/.agents/protocol.conf`
  - ii) conventional commits, `type(scope): description`
  - iii) branch naming `feat/<slug>`, `fix/<slug>`, `docs/<slug>`
  - iv) never merge own PR

- **D. `completion-standard`**
  - i) done means tests pass, edge cases handled, docs updated
  - ii) 80% is not done
  - iii) self-review before every push and PR
  - iv) 2 hours of review on a 10-minute fix is acceptable

- **E. `code-quality`**
  - i) one responsibility per function
  - ii) no hardcoded URLs, model names or credentials
  - iii) validate at boundaries, trust internal code
  - iv) no features or refactors beyond what was asked
  - v) three similar lines beat a premature abstraction

### 7. Enforcement
- Layer 1 — global git config
- Layer 2 — Claude Code hook, blocks before commands run
- Layer 3 — git hooks, blocks at commit and push
- Layer 4 — GitHub CI and ruleset, cannot be skipped
- every rule blocks, none are warnings
- override is human-only: `PROTOCOL_OVERRIDE=<id>`

---

## 3. Links

### 1. Protocol
- [@ShaheerKhawaja](https://github.com/ShaheerKhawaja) — original protocol system

### 2. Installed Skills
- [`karpathy-guidelines`](https://github.com/multica-ai/andrej-karpathy-skills) — forrestchang, from Andrej Karpathy — MIT

### 3. Archived Skills
- [`xlsx`](https://github.com/anthropics/skills/tree/main/skills/xlsx) — Anthropic
- [`docx`](https://github.com/anthropics/skills/tree/main/skills/docx) — Anthropic
- [`pptx`](https://github.com/anthropics/skills/tree/main/skills/pptx) — Anthropic
- [`pdf`](https://github.com/anthropics/skills/tree/main/skills/pdf) — Anthropic
- [`frontend-design`](https://github.com/anthropics/skills/tree/main/skills/frontend-design) — Anthropic
- [`humanizer`](https://github.com/blader/humanizer) — blader
- [`remove-ai-marks`](https://github.com/haidrrrry/claude-watermark-remover/tree/main/skills/remove-claude-marks) — haidrrrry
- [`clean-user-facing-text`](https://github.com/haidrrrry/claude-watermark-remover/tree/main/skills/clean-user-facing-text) — haidrrrry

Restore one:
```bash
mv ~/.claude/skills-archive/pdf ~/.claude/skills/pdf
```

### 4. Tools
- [Gitleaks](https://github.com/gitleaks/gitleaks) — Zachary Rice
- [GitHub CLI](https://github.com/cli/cli) — GitHub
- [jq](https://github.com/jqlang/jq) — jq maintainers
