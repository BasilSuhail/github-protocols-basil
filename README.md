# GitHub Protocols

Rules for AI coding tools. They block bad commits instead of asking nicely.

Works with Claude Code, Codex, Cursor, and anything else that runs `git`.

---

## How to install

You run these in a terminal. You have two options.

**Inside Claude Code** — start your message with `!`, then the command:

```
!bash verify.sh
```

It runs immediately and the output appears in the conversation. Easiest, because
you are already in the right folder.

**Or a normal terminal** — press `Cmd+Space`, type `Terminal`, press Enter.

Two commands are worth knowing. `cd <folder>` moves you into a folder.
`bash <file>` runs a file.

### Install

```bash
cd ~/folders/github-protocols-basil
bash install.sh
bash verify.sh
```

`verify.sh` should end with `ALL SYSTEMS OPERATIONAL`. If it does not, it prints
one line per problem saying what is wrong.

Run `install.sh` again any time. It is safe to repeat — it overwrites its own
files and leaves yours alone.

### Two things to do once

Repositories you already have keep their old hooks. Git only copies a hook into
a repository that does not already have one, and never replaces an existing one,
so old repositories quietly keep running whatever they were set up with:

```bash
bash scripts/refresh-repo-hooks.sh --all ~/folders
```

Then protect `main` on GitHub, so the rules hold even from a machine that has
none of this installed. Needs admin on the repository:

```bash
bash scripts/apply-github-ruleset.sh
```

### Setting up a second machine

```bash
git clone https://github.com/BasilSuhail/github-protocols-basil.git
cd github-protocols-basil
bash install.sh
```

Your name and email are not in this repository. They live in
`~/.agents/protocol.conf`, which is never uploaded. `install.sh` creates it from
whatever git already knows on that machine.

---

## Protocol list

### Identity

| ID | Rule |
|----|------|
| ID-001 | Commit address must end in `users.noreply.github.com` |
| ID-002 | No `Co-Authored-By` line |
| ID-003 | No AI credited as an author |

### Safety

| ID | Rule |
|----|------|
| ID-101 | No `--no-verify` (that flag skips these checks) |
| ID-102 | No force push |
| ID-103 | No `git add -A` or `git add .` — name the files you mean |
| ID-104 | No `git reset --hard` or `git clean -f` |
| ID-105 | Only touch repositories you own |
| ID-106 | `gh` commands must say `--repo`, so they cannot hit the wrong one |
| ID-107 | No committing straight to `main` |
| ID-108 | Agents never merge. You merge |

### Secrets

| ID | Rule |
|----|------|
| ID-201 | No API keys, tokens or passwords in committed files |
| ID-202 | No `.env`, credential or key files |
| ID-203 | Gitleaks must find nothing |

### Commit messages

| ID | Rule |
|----|------|
| ID-301 | Start with a type: `feat:`, `fix:`, `docs:`, `chore:`, and so on |
| ID-302 | First line 72 characters or fewer |
| ID-303 | No emoji |

### Private information

| ID | Rule |
|----|------|
| ID-401 | No personal names, institutions or contact details |
| ID-402 | No private network addresses |
| ID-403 | No `/Users/yourname/...` paths |
| ID-404 | No personal email addresses |

ID-401 reads its list of names from a file on your machine that is never
uploaded. The list cannot live in this repository: publishing a list of things
you want kept private publishes them.

### When a rule blocks you

You see this, and the command does not run:

```
BLOCKED [ID-103] Blanket staging is prohibited — it sweeps in .env, keys, and binaries.
         Fix: Stage explicit paths: git add path/to/file
```

Do what the `Fix:` line says. Every rule blocks; none of them are warnings you
can ignore, because a warning is something an agent reads and then does anyway.

If a block is genuinely wrong, waive that one rule for that one command. This
only works when you type it yourself — it is refused inside an AI session, so an
agent can never switch off a rule that is stopping it:

```bash
PROTOCOL_OVERRIDE=ID-102 git push --force-with-lease origin my-branch
```

### Where the rules are enforced

| Where | Covers | Can it be skipped? |
|-------|--------|--------------------|
| Claude Code, before a command runs | Claude Code only | Yes, on this machine |
| Git, at commit and push | Every tool | Yes, on this machine |
| GitHub Actions, on every push | Everything | No |
| GitHub ruleset on `main` | Everything | No |

The first two catch mistakes early. The last two are the ones that still work on
a machine where nothing is installed.

### Working agreement

One issue, one branch, one pull request. Agents open pull requests. You merge.

---

## Skills

A skill's description loads every session; its instructions only load when it is
actually used. Check with `claude plugin details <plugin>` — it shows `always-on`
next to `on-invoke`. A large skill sitting unused costs very little, so trimming
skills is about having a shorter list to choose from, not about saving space.

`skills.allowlist` lists which skills stay in `~/.claude/skills/`. `install.sh`
moves the rest to `~/.claude/skills-archive/`. Moved, never deleted. To bring
one back:

```bash
mv ~/.claude/skills-archive/pdf ~/.claude/skills/pdf
```

Skills that come from a plugin cannot be removed one at a time — a plugin
installs all of its skills together or none of them.

---

## Links and credits

### The protocol system

**[@ShaheerKhawaja](https://github.com/ShaheerKhawaja)** — the original protocol
system this is adapted from.

### Vendored into this repository

| What | Author | Source |
|------|--------|--------|
| `karpathy-guidelines` skill | forrestchang, MIT | [multica-ai/andrej-karpathy-skills](https://github.com/multica-ai/andrej-karpathy-skills) |

Derived from **Andrej Karpathy's** observations on where AI coding goes wrong.
The exact version copied is recorded in [NOTICE](NOTICE). Check it still matches
upstream with `bash scripts/check-vendor-drift.sh`.

### Archived skills, and where to get them again

| Skill | Source |
|-------|--------|
| `xlsx`, `docx`, `pptx`, `pdf`, `frontend-design` | [anthropics/skills](https://github.com/anthropics/skills) — under `skills/<name>/` |
| `humanizer`, `remove-ai-marks`, `clean-user-facing-text` | Source unknown — restore from `~/.claude/skills-archive/` |

The Anthropic skills are `© 2025 Anthropic, PBC. All rights reserved.` They are
linked here, never copied in.

The other three record no source anywhere on disk, and searching those names
returns several unrelated projects. A guessed link would send you to somebody
else's skill, so only the archive path is given.

### Tools this relies on

| Tool | For |
|------|-----|
| [Gitleaks](https://github.com/gitleaks/gitleaks) | Secret scanning (ID-203) |
| [GitHub CLI](https://cli.github.com) | `gh` commands |
| [jq](https://jqlang.github.io/jq/) | Reading JSON in the hooks |

---

## More detail

- [GITHUB-RULES.md](GITHUB-RULES.md) — every rule in full
- [docs/INSTALLATION.md](docs/INSTALLATION.md) — what gets installed where
- [docs/VERIFICATION.md](docs/VERIFICATION.md) — what the checks cover
