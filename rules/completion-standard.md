---
name: completion-standard
description: 100% completion standard — no partial work, mandatory self-review, verified correctness
paths: ["**"]
alwaysApply: true
---

# Completion Standard (100%)

Every task must be completed to 100%. No partial work. No "good enough."

## The Rule

- "Done" means: tests pass, edge cases handled, docs updated, verified working
- 80% completion is NOT acceptable. Either the work is fully complete or it is not done.
- Self-review is mandatory before every push and every PR
- If self-review takes 2 hours for a 10-minute fix, that is acceptable
- Quality is measured by correctness, not by speed

## Self-Review Protocol (Before Every Push)

1. Re-read every changed file line by line — not skimming
2. Verify tests pass — run the actual test suite, do not assume
3. Check edge cases — empty input, null values, boundary conditions
4. Verify the fix works — run it and observe the result
5. Review for security — XSS, injection, secrets, PII exposure
6. Check for regressions — did fixing X break Y?

## What "Done" Means

- All tests pass (the full suite, not just new tests)
- No TODO or FIXME left without a tracked GitHub issue
- Documentation updated if behavior changed
- Edge cases handled, not ignored
- Code reviewed (self-review at minimum)
- Verified working — actually ran it, actually saw it work

## What Is NOT Acceptable

- Scoring work at "8/10" and calling it complete
- Leaving known issues unfixed with "we'll handle it later"
- Pushing code that hasn't been tested
- Trusting automated quality scores without manual verification
- Starting new work while previous work is incomplete
- Making 15 commits of "improvements" that degrade output (Session 5 lesson)

## Surgical Edit Policy

- Make ONE change at a time
- Run the pipeline/tests after EACH change
- Observe the output — watch it, inspect frames, read logs
- If output degrades, REVERT immediately (`git checkout HEAD -- <file>`)
- Never launch parallel agents editing different files simultaneously
- Trust convergence data over assumptions
