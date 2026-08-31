# GitHub Protocols

Rules for AI coding tools. They block bad commits instead of asking nicely.

Works with Claude Code, Codex and Cursor.

---

## 1. Setup

Run these in Terminal, or type `!` in front of each one inside Claude Code.

```bash
cd ~/folders/github-protocols-basil
bash install.sh
bash verify.sh
```

`verify.sh` should end with `ALL SYSTEMS OPERATIONAL`. Safe to re-run any time.

Then once, to cover repos you already have and to protect `main` on GitHub:

```bash
bash scripts/refresh-repo-hooks.sh --all ~/folders
bash scripts/apply-github-ruleset.sh
```

---

## 2. Protocols

| ID | Rule |
|----|------|
| ID-001 | Commit address must end in `users.noreply.github.com` |
| ID-002 | No `Co-Authored-By` line |
| ID-003 | No AI credited as an author |
| ID-101 | No `--no-verify` (that flag skips these checks) |
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
| ID-301 | Commit message starts with `feat:`, `fix:`, `docs:`, `chore:` etc. |
| ID-302 | First line 72 characters or fewer |
| ID-303 | No emoji |
| ID-401 | No personal names, institutions or contact details |
| ID-402 | No private network addresses |
| ID-403 | No `/Users/yourname/...` paths |
| ID-404 | No personal email addresses |
| ID-405 | No agent session links |
| ID-406 | Text posted to GitHub is checked before it goes up |

When something is blocked you get the rule ID and a `Fix:` line saying what to do.

To waive one rule for one command — only works when you type it yourself, never
inside an AI session:

```bash
PROTOCOL_OVERRIDE=ID-102 git push --force-with-lease origin my-branch
```

Full detail: [GITHUB-RULES.md](GITHUB-RULES.md) ·
[install](docs/INSTALLATION.md) · [checks](docs/VERIFICATION.md)

---

## 3. Links

**Credits**

- [@ShaheerKhawaja](https://github.com/ShaheerKhawaja) — the original protocol system this is adapted from
- [forrestchang](https://github.com/multica-ai/andrej-karpathy-skills) — the `karpathy-guidelines` skill, MIT, vendored here
- Andrej Karpathy — the observations that skill comes from

**Skills**

`skills.allowlist` says which stay installed. The rest move to
`~/.claude/skills-archive/` — moved, never deleted. Bring one back with
`mv ~/.claude/skills-archive/pdf ~/.claude/skills/pdf`.

| Skill | Where to get it |
|-------|-----------------|
| `xlsx` | [anthropics/skills](https://github.com/anthropics/skills/tree/main/skills/xlsx) |
| `docx` | [anthropics/skills](https://github.com/anthropics/skills/tree/main/skills/docx) |
| `pptx` | [anthropics/skills](https://github.com/anthropics/skills/tree/main/skills/pptx) |
| `pdf` | [anthropics/skills](https://github.com/anthropics/skills/tree/main/skills/pdf) |
| `frontend-design` | [anthropics/skills](https://github.com/anthropics/skills/tree/main/skills/frontend-design) |
| `humanizer` | [blader/humanizer](https://github.com/blader/humanizer) |
| `remove-ai-marks` | [haidrrrry/claude-watermark-remover](https://github.com/haidrrrry/claude-watermark-remover/tree/main/skills/remove-claude-marks) |
| `clean-user-facing-text` | [haidrrrry/claude-watermark-remover](https://github.com/haidrrrry/claude-watermark-remover/tree/main/skills/clean-user-facing-text) |
| `karpathy-guidelines` | Installed by this repo — [source](https://github.com/multica-ai/andrej-karpathy-skills) |

**Tools**

[Gitleaks](https://github.com/gitleaks/gitleaks) ·
[GitHub CLI](https://cli.github.com) ·
[jq](https://jqlang.github.io/jq/)
