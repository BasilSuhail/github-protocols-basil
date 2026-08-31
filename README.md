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

Existing repos keep their old hooks. Refresh them, then lock `main`:

```bash
bash ~/github-protocols-basil/scripts/refresh-repo-hooks.sh --all ~/folders
bash ~/github-protocols-basil/scripts/apply-github-ruleset.sh
```

---

## 2. Protocols and Skills

### Protocols

| Rule | Layer | Blocks? |
|------|-------|---------|
| Noreply email on all commits | All 4 | YES |
| No Co-Authored-By trailers | Layer 2+3 | YES |
| No AI credited as author | Layer 2+3 | YES |
| No `--no-verify` bypass | Layer 2 | YES |
| No force push | Layer 2+3 | YES |
| No `git add -A` | Layer 2 | YES |
| No `git reset --hard` or `git clean -f` | Layer 2 | YES |
| No upstream repo interaction | Layer 2+3 | YES |
| `gh` commands must use `--repo` | Layer 2 | YES |
| No commits straight to `main` | Layer 3+4 | YES |
| Agents never merge | Layer 2 | YES |
| No secrets in commits | Layer 3+4 | YES |
| No `.env` files committed | Layer 3+4 | YES |
| Gitleaks clean | Layer 3+4 | YES |
| Conventional commit format | Layer 3+4 | YES |
| Subject 72 chars or fewer | Layer 3+4 | YES |
| No emoji in commits | Layer 3+4 | YES |
| No personal names or institutions | Layer 3+4 | YES |
| No private IPs | Layer 3+4 | YES |
| No home directory paths | Layer 3+4 | YES |
| No personal email in commits | Layer 3+4 | YES |
| No agent session links | Layer 3+4 | YES |
| Text posted to GitHub is scanned | Layer 2 | YES |
| Caveman / lesstalk / 1:1:1 | Rules | YES |

Layers: 1 global git config · 2 Claude Code hook · 3 git hooks · 4 GitHub CI and ruleset.

### Skills

| File | Purpose |
|------|---------|
| `AGENTS.md` | Global agent contract for Basil workflow |
| `rules/agent-style.md` | `caveman`, `1:1:1`, `lesstalk` |
| `rules/git-workflow.md` | branch, commit, PR, push rules |
| `rules/completion-standard.md` | 100% completion rule |
| `rules/code-quality.md` | test, docs, code hygiene |
| `rules/karpathy-guidelines.md` | think first, simple, surgical, verify |
| `skills/karpathy-guidelines/` | same, as a Claude Code skill |
| `lib/rules.sh` | rule engine, all rules defined once |
| `lib/personal-identifiers.example.sh` | template for the private term list |
| `hooks/claude-code/pretooluse.sh` | blocks bad commands before they run |
| `hooks/git-templates/pre-commit` | staged file safety |
| `hooks/git-templates/commit-msg` | commit message format |
| `hooks/git-templates/pre-push` | push target and force-push safety |
| `.github/workflows/protocol.yml` | same rules, server side |
| `scripts/refresh-repo-hooks.sh` | push hooks into existing repos |
| `scripts/apply-github-ruleset.sh` | lock `main` on GitHub |
| `templates/gitconfig` | git identity template |
| `skills.allowlist` | which skills stay installed |
| `protocol.conf.example` | identity template |
| `docs/INSTALLATION.md` | setup instructions |
| `docs/VERIFICATION.md` | post-install checks |

---

## 3. Links

| Thing | Source | Credit |
|-------|--------|--------|
| Protocol system | [github-protocols](https://github.com/ShaheerKhawaja) | [@ShaheerKhawaja](https://github.com/ShaheerKhawaja) |
| `karpathy-guidelines` | [multica-ai/andrej-karpathy-skills](https://github.com/multica-ai/andrej-karpathy-skills) | forrestchang, from Andrej Karpathy — MIT |
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

Archived skills sit in `~/.claude/skills-archive/`.
Restore with `mv ~/.claude/skills-archive/pdf ~/.claude/skills/pdf`.
