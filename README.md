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

## 2. Protocols

| ID | Rule |
|----|------|
| ID-001 | Commit address must end in `users.noreply.github.com` |
| ID-002 | No `Co-Authored-By` line |
| ID-003 | No AI credited as an author |
| ID-101 | No `--no-verify` — that flag skips these checks |
| ID-102 | No force push |
| ID-103 | No `git add -A` or `git add .` — name the files you mean |
| ID-104 | No `git reset --hard` or `git clean -f` |
| ID-105 | Only touch repos you own |
| ID-106 | `gh` commands must say `--repo` |
| ID-107 | No committing straight to `main` |
| ID-108 | Agents never merge. You merge |
| ID-201 | No API keys, tokens or passwords in committed files |
| ID-202 | No `.env`, credential or key files |
| ID-203 | Gitleaks must find nothing |
| ID-301 | Commit starts with `feat:`, `fix:`, `docs:`, `chore:` etc. |
| ID-302 | First line 72 characters or fewer |
| ID-303 | No emoji |
| ID-401 | No personal names, institutions or contact details |
| ID-402 | No private network addresses |
| ID-403 | No `/Users/yourname/...` paths |
| ID-404 | No personal email addresses |
| ID-405 | No agent session links |
| ID-406 | Text posted to GitHub is checked before it goes up |

Blocked commands print the rule ID and a `Fix:` line. To waive one rule for one
command — only works when you type it yourself, never inside an AI session:

```bash
PROTOCOL_OVERRIDE=ID-102 git push --force-with-lease origin my-branch
```

Full detail in [GITHUB-RULES.md](GITHUB-RULES.md).

---

## 3. Skills

`skills.allowlist` says which skills stay in `~/.claude/skills/`. The rest move
to `~/.claude/skills-archive/` — moved, never deleted. Bring one back with:

```bash
mv ~/.claude/skills-archive/pdf ~/.claude/skills/pdf
```

| Skill | Source | Credit |
|-------|--------|--------|
| Protocol system | [ShaheerKhawaja/github-protocols](https://github.com/ShaheerKhawaja) | [@ShaheerKhawaja](https://github.com/ShaheerKhawaja) |
| `karpathy-guidelines` | [multica-ai/andrej-karpathy-skills](https://github.com/multica-ai/andrej-karpathy-skills) | forrestchang, from Andrej Karpathy's notes — MIT |
| `xlsx` | [anthropics/skills](https://github.com/anthropics/skills/tree/main/skills/xlsx) | Anthropic |
| `docx` | [anthropics/skills](https://github.com/anthropics/skills/tree/main/skills/docx) | Anthropic |
| `pptx` | [anthropics/skills](https://github.com/anthropics/skills/tree/main/skills/pptx) | Anthropic |
| `pdf` | [anthropics/skills](https://github.com/anthropics/skills/tree/main/skills/pdf) | Anthropic |
| `frontend-design` | [anthropics/skills](https://github.com/anthropics/skills/tree/main/skills/frontend-design) | Anthropic |
| `humanizer` | [blader/humanizer](https://github.com/blader/humanizer) | blader |
| `remove-ai-marks` | [haidrrrry/claude-watermark-remover](https://github.com/haidrrrry/claude-watermark-remover/tree/main/skills/remove-claude-marks) | haidrrrry |
| `clean-user-facing-text` | [haidrrrry/claude-watermark-remover](https://github.com/haidrrrry/claude-watermark-remover/tree/main/skills/clean-user-facing-text) | haidrrrry |
