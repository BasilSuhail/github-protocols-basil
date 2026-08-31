# GitHub Protocols

Rules for agentic coding tools, enforced by hooks and CI rather than by asking
politely. Every rule is defined once in `lib/rules.sh` and applied at four
layers, so an agent cannot read its way around one.

Binds Claude Code, Codex, Cursor, and anything else that runs `git`.

## Protocols

| ID | Rule |
|----|------|
| **Identity** | |
| ID-001 | Commit address must end in `users.noreply.github.com` |
| ID-002 | No `Co-Authored-By` trailer |
| ID-003 | No AI attribution |
| **Safety** | |
| ID-101 | No `--no-verify` or `--no-gpg-sign` |
| ID-102 | No force push, no non-fast-forward push |
| ID-103 | No `git add -A` or `git add .` |
| ID-104 | No `git reset --hard` or `git clean -f` |
| ID-105 | Target repo must be one you own |
| ID-106 | `gh` write commands require `--repo` |
| ID-107 | No direct commit or push to `main` |
| ID-108 | Agents never merge pull requests |
| **Secrets** | |
| ID-201 | No secret patterns in staged content |
| ID-202 | No `.env`, credential or key files staged |
| ID-203 | Gitleaks must pass on the staged diff |
| **Commit format** | |
| ID-301 | Conventional Commit subject |
| ID-302 | Subject at most 72 characters |
| ID-303 | No emoji |
| **Leaks** | |
| ID-401 | No personal or third-party identifiers (local, untracked term list) |
| ID-402 | No private network addresses |
| ID-403 | No home directory paths |
| ID-404 | No personal email addresses |

Every rule blocks. There are no advisory rules: an agent reads a warning and
proceeds anyway, which is indistinguishable from having no rule.

`PROTOCOL_OVERRIDE=<rule-id>` waives one rule for one command, and only from a
human shell — it is refused whenever an agent environment marker is present.

## Enforcement layers

| Layer | Binds | Bypassable |
|-------|-------|------------|
| `hooks/claude-code/pretooluse.sh` | Claude Code, before the command runs | yes, locally |
| `hooks/git-templates/*` | every tool, at commit and push | yes, locally |
| `.github/workflows/protocol.yml` | every push and PR | no |
| GitHub ruleset on `main` | everything | no |

The local layers catch mistakes early. The server-side layers are the ones that
hold when a machine has no hooks installed.

## Working agreement

1 issue → 1 branch → 1 PR. Agents open pull requests; they never merge.

## Install

```bash
git clone https://github.com/BasilSuhail/github-protocols-basil.git
cd github-protocols-basil
bash install.sh
bash verify.sh
```

Identity lives in `~/.agents/protocol.conf`, which is never tracked. See
[docs/INSTALLATION.md](docs/INSTALLATION.md) and
[docs/VERIFICATION.md](docs/VERIFICATION.md).

Existing repos keep their old hooks — `git init` never overwrites. Refresh them
with `bash scripts/refresh-repo-hooks.sh --all ~/folders`.

## Skills

Skill *descriptions* load every session; *bodies* load only when invoked. Check
the split with `claude plugin details <plugin>` — it prints `always-on` against
`on-invoke`. So a 3.4k skill sitting unused costs about 40 tokens, and pruning
skills is worth doing for a shorter list to choose from, not for the tokens.

`skills.allowlist` records what stays in `~/.claude/skills/`. `install.sh` moves
anything else to `~/.claude/skills-archive/` — moved, never deleted. Restore one
with:

```bash
mv ~/.claude/skills-archive/<name> ~/.claude/skills/<name>
```

Plugin skills cannot be pruned individually: `claude plugin disable` takes a
plugin, not a skill, and edits to the plugin cache are wiped on update. The
caveman and superpowers bundles are all-or-nothing, and both are kept.

### Getting an archived skill back from source

| Skill | Source |
|-------|--------|
| `xlsx`, `docx`, `pptx`, `pdf`, `frontend-design` | [anthropics/skills](https://github.com/anthropics/skills) — `skills/<name>/` |
| `humanizer`, `remove-ai-marks`, `clean-user-facing-text` | Upstream unknown — restore from `~/.claude/skills-archive/` |

The Anthropic skills are `© 2025 Anthropic, PBC. All rights reserved.` They are
linked, never vendored here.

The other three record no upstream anywhere on disk, and a search returns
several unrelated projects with the same names. A guessed link would send a
future reinstall to somebody else's skill, so the archive is the only pointer
given.

## Credits

- **[@ShaheerKhawaja](https://github.com/ShaheerKhawaja)** — the original
  protocol system this is adapted from.
- **[forrestchang](https://github.com/multica-ai/andrej-karpathy-skills)** —
  the `karpathy-guidelines` skill, vendored under MIT.
- **Andrej Karpathy** — the observations on LLM coding pitfalls that skill is
  derived from.

Vendored files and their exact upstream revisions are recorded in
[NOTICE](NOTICE). Check for drift with `bash scripts/check-vendor-drift.sh`.
