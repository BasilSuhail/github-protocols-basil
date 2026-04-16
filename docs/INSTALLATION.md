# Installation Guide

## Prerequisites

- Git 2.40+
- GitHub CLI (`gh`): `brew install gh`
- Gitleaks: `brew install gitleaks`
- (Optional) pre-commit framework: `pip install pre-commit`

## Step 1: Global Git Config

```bash
# Set noreply email globally
git config --global user.email "BasilSuhail@users.noreply.github.com"
git config --global user.name "Basil Suhail"

# Set template directory for auto-applying hooks to new repos
git config --global init.templateDir "~/.git-templates"

# Push/pull defaults
git config --global push.default current
git config --global push.autoSetupRemote true
git config --global pull.rebase true
git config --global commit.cleanup strip
git config --global branch.sort -committerdate
```

## Step 2: Install Git Hook Templates

```bash
# Create template directory
mkdir -p ~/.git-templates/hooks

# Copy hook templates
cp hooks/git-templates/pre-commit ~/.git-templates/hooks/pre-commit
cp hooks/git-templates/pre-push ~/.git-templates/hooks/pre-push

# Make executable
chmod +x ~/.git-templates/hooks/pre-commit
chmod +x ~/.git-templates/hooks/pre-push
```

## Step 3: Apply to Existing Repos

```bash
# Safe operation — only copies hooks, doesn't destroy data
cd /path/to/your/repo
git init  # Re-applies templates

# Or bulk-apply to all repos:
find ~ -name ".git" -type d -maxdepth 4 \
  -not -path "*/.claude/*" \
  -not -path "*/node_modules/*" \
  -not -path "*/Library/*" \
  2>/dev/null | sed 's/\/.git$//' | while read dir; do
  cd "$dir" && git init --template="$HOME/.git-templates" >/dev/null 2>&1
done
```

## Step 4: Claude Code Hooks (Claude Code users only)

```bash
# Copy hook scripts
cp hooks/claude-code/git-commit-guard.sh ~/.claude/hooks/
cp hooks/claude-code/git-push-guard.sh ~/.claude/hooks/
cp hooks/claude-code/self-review-gate.sh ~/.claude/hooks/
chmod +x ~/.claude/hooks/git-*.sh ~/.claude/hooks/self-*.sh
```

Then add to `~/.claude/settings.json` under `hooks.PreToolUse`:

```json
{
  "matcher": "Bash",
  "hooks": [{ "type": "command", "command": "bash \"~/.claude/hooks/git-commit-guard.sh\"", "timeout": 3000 }]
},
{
  "matcher": "Bash",
  "hooks": [{ "type": "command", "command": "bash \"~/.claude/hooks/git-push-guard.sh\"", "timeout": 3000 }]
},
{
  "matcher": "Bash",
  "hooks": [{ "type": "command", "command": "bash \"~/.claude/hooks/self-review-gate.sh\"", "timeout": 5000 }]
}
```

## Step 5: Universal Agent Rules

```bash
# For Claude Code, Codex, Cursor, Gemini CLI, OpenCode, Windsurf
mkdir -p ~/.agents/rules
cp rules/*.md ~/.agents/rules/

# For Codex CLI/app specifically
mkdir -p ~/.codex/rules
cp rules/*.md ~/.codex/rules/
cp AGENTS.md ~/.codex/AGENTS.md
```

## Step 6: Per-Repo Setup (New Projects)

```bash
# Copy AGENTS.md to new repo root
cp AGENTS.md /path/to/new/repo/AGENTS.md

# Optional: Add pre-commit framework
cp templates/pre-commit-config.yaml /path/to/new/repo/.pre-commit-config.yaml
cp templates/gitleaks.toml /path/to/new/repo/.gitleaks.toml
cd /path/to/new/repo && pre-commit install
```

## Step 7: Fix Email on Owned Repos

```bash
# Check current email
git config user.email

# Fix if needed
git config user.email "BasilSuhail@users.noreply.github.com"
```
