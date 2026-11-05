---
name: personal-data
description: On a self-hosted server, app code is open to the agent; every app's data is the owner's and off limits
paths: ["**"]
alwaysApply: true
---

# Personal Data (Self-Hosted Servers)

Apps are not personal. Everything an app holds is.

## Open to the agent

- App code and setup: repos, Dockerfiles, manifests, installers, scripts, configs that hold no data
- Building, changing, breaking or removing an app. An app can be rebuilt.
- GitHub: pushes go to branches and PRs, and the owner merges

## Off limits

Every app's data, wherever it lives:

- Databases (SQLite, Postgres, Redis dumps), and any table in them
- Documents, files, uploads, CVs, resumes, cover letters
- Photos, video and media libraries
- Self-hosted git such as Gitea: its repos, data and backups. Not GitHub.
- Password vaults, backups, browser profiles, archived pages, downloads
- Logs or exports that carry personal content

## The Rule

- Never read, move, delete, recreate or edit app data
- Not directly, and not through the app: no shell inside a container to reach it, no SQL, no app command that writes data
- A change to data is a command the owner runs by hand. Write the exact command, say what it does, and stop.
- Losing an app's code is acceptable. Losing its data is not.
- Unsure whether something is data? Treat it as data and ask.

## When the Rule Is Enforced

A rule the agent sets on itself can be undone by the agent. The real boundary is an
operating-system one: the agent runs as its own user, without sudo, with the data
folders locked for that user. Until that exists, this rule is followed on trust.
