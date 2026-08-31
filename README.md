# GitHub Protocols

Rules for AI coding tools. They block bad commits instead of asking nicely.
Works with Claude Code, Codex and Cursor.

---

## 1. How To Start

Run in Terminal, or type `!` in front of each line inside Claude Code.

```bash
cd ~/folders/github-protocols-basil
bash install.sh
bash verify.sh
```

`verify.sh` must end with `ALL SYSTEMS OPERATIONAL`. Safe to re-run any time.

Then once, to cover repos you already have and to lock `main` on GitHub:

```bash
bash scripts/refresh-repo-hooks.sh --all ~/folders
bash scripts/apply-github-ruleset.sh
```

Identity is read from `~/.agents/protocol.conf`, which is never pushed.

---

## 2. Protocols and Skills

### Protocols

| Rule | Layer | Blocks? |
|------|-------|---------|
| Noreply email on all commits | All 3 | YES |
| No Co-Authored-By trailers | Hook + Git | YES |
| No AI credited as an author | Hook + Git | YES |
| No `--no-verify` bypass | Hook | YES |
| No force push | Hook + Git | YES |
| No `git add -A` or `git add .` | Hook | YES |
| No `git reset --hard` or `git clean -f` | Hook | YES |
| No upstream repo interaction | Hook + Git | YES |
| `gh` commands must say `--repo` | Hook | YES |
| No committing straight to `main` | Git + CI | YES |
| Agents never merge | Hook | YES |
| No secrets in commits | Git + CI | YES |
| No `.env` files committed | Git + CI | YES |
| Gitleaks clean | Git + CI | YES |
| Conventional commit format | Git + CI | YES |
| Subject 72 characters or fewer | Git + CI | YES |
| No emoji in commits | Git + CI | YES |
| No personal names or institutions | Git + CI | YES |
| No private network addresses | Git + CI | YES |
| No home directory paths | Git + CI | YES |
| No personal email addresses | Git + CI | YES |
| No agent session links | Git + CI | YES |
| Text posted to GitHub is scanned | Hook | YES |

### Skills

| File | Purpose |
|------|---------|
| `AGENTS.md` | global agent contract |
| `rules/agent-style.md` | `caveman`, `1:1:1`, `lesstalk` |
| `rules/git-workflow.md` | branch, commit, PR, push rules |
| `rules/completion-standard.md` | 100% completion rule |
| `rules/code-quality.md` | test, docs, code hygiene |
| `rules/karpathy-guidelines.md` | think first, keep it simple, surgical edits |
| `skills/karpathy-guidelines/` | same rules as a Claude Code skill |
| `lib/rules.sh` | the rule engine, all 23 rules |
| `lib/personal-identifiers.example.sh` | template for the ID-401 term list |
| `hooks/claude-code/pretooluse.sh` | blocks bad commands before they run |
| `hooks/git-templates/pre-commit` | staged file safety |
| `hooks/git-templates/commit-msg` | commit message format |
| `hooks/git-templates/pre-push` | push target and force-push safety |
| `.github/workflows/protocol.yml` | same rules, server side |
| `templates/gitconfig` | git identity template |
| `skills.allowlist` | which skills stay installed |
| `protocol.conf.example` | identity template |

---

## 3. Links

Quick links for everything used here, and who to credit for it.

| Skill | Source | Credit |
|-------|--------|--------|
| Protocol system | [ShaheerKhawaja](https://github.com/ShaheerKhawaja) | [@ShaheerKhawaja](https://github.com/ShaheerKhawaja) |
| `karpathy-guidelines` | [multica-ai/andrej-karpathy-skills](https://github.com/multica-ai/andrej-karpathy-skills) | forrestchang, from Andrej Karpathy's notes — MIT |
| `xlsx` | [anthropics/skills](https://github.com/anthropics/skills/tree/main/skills/xlsx) | Anthropic |
| `docx` | [anthropics/skills](https://github.com/anthropics/skills/tree/main/skills/docx) | Anthropic |
| `pptx` | [anthropics/skills](https://github.com/anthropics/skills/tree/main/skills/pptx) | Anthropic |
| `pdf` | [anthropics/skills](https://github.com/anthropics/skills/tree/main/skills/pdf) | Anthropic |
| `frontend-design` | [anthropics/skills](https://github.com/anthropics/skills/tree/main/skills/frontend-design) | Anthropic |
| `humanizer` | [blader/humanizer](https://github.com/blader/humanizer) | blader |
| `remove-ai-marks` | [haidrrrry/claude-watermark-remover](https://github.com/haidrrrry/claude-watermark-remover/tree/main/skills/remove-claude-marks) | haidrrrry |
| `clean-user-facing-text` | [haidrrrry/claude-watermark-remover](https://github.com/haidrrrry/claude-watermark-remover/tree/main/skills/clean-user-facing-text) | haidrrrry |
| Gitleaks | [gitleaks/gitleaks](https://github.com/gitleaks/gitleaks) | Zachary Rice |
| GitHub CLI | [cli/cli](https://github.com/cli/cli) | GitHub |
| jq | [jqlang/jq](https://github.com/jqlang/jq) | jq maintainers |

Skills not in the setup sit in `~/.claude/skills-archive/`. Bring one back with
`mv ~/.claude/skills-archive/pdf ~/.claude/skills/pdf`.
