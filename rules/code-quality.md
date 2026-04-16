---
name: code-quality
description: Code quality standards — clean code, security, testing, documentation
paths: ["**"]
alwaysApply: true
---

# Code Quality Standards

## General

- One responsibility per function/class
- No hardcoded API URLs, model names, or credentials
- Validate at system boundaries (user input, external APIs), trust internal code
- Don't add features, refactoring, or "improvements" beyond what was asked
- Don't add error handling for scenarios that can't happen
- Three similar lines of code is better than a premature abstraction

## Python

- Formatter: ruff (line-length=120, target py312)
- Type checking: mypy strict
- Testing: pytest, minimum 70% coverage
- Package manager: uv
- Import style: absolute imports preferred

## TypeScript / JavaScript

- ESLint + TypeScript strict mode
- Package manager: bun
- Framework: Next.js App Router (when applicable)
- No `any` type without justification

## Security

- Environment variables for all credentials
- Never commit .env files
- Encrypt stored provider keys (SHA-256 minimum)
- JWT auth + SSO where applicable
- No XSS, SQL injection, or command injection — validate inputs

## Testing

- Run tests BEFORE committing — never commit with failures
- Write tests for new functionality — at minimum happy path + one edge case
- Don't mock databases in integration tests (prior incident: mocks passed, prod failed)
- Trust the user's assessment over automated quality scores

## Error Handling

- Do NOT remove error logging catch blocks — they provide observability context
- Keep `logger.error` + `raise`, don't delete the whole try/except
- Operation-specific error context is valuable for debugging

## Documentation

- Update docs when behavior changes — in the same commit
- Don't add docstrings to code you didn't change
- Only add comments where the logic isn't self-evident
- Architecture decisions go in DESIGN.md or ARCHITECTURE.md
