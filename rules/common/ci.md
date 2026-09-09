# Don't Cheat the CI

`push.md` § 7 says you follow the CI to the end and don't rerun hoping. This file says what's behind those two sentences, when the project has a CI.

## A Local Green Proves Nothing About the CI

The CI resolves its own dependencies, its own cache, its own pinned versions, sometimes different from what a work machine has installed. A green local check is a clue, not a proof: it says nothing obvious is wrong, not that the CI will confirm it. `test.md` already asks you to say what you verified and what you couldn't; the CI is the check no local machine replaces.

## A Flaky Check Gets Investigated, Not Worked Around

Two reflexes hide a problem instead of solving it: rerunning the same check in a loop hoping it passes once, and disabling or weakening it because it's in the way. Both leave the defect in place and only remove the signal that showed it. An unstable check gets treated like any other defect, with `debug.md`: you reproduce its instability, isolate what causes it, fix it.

## Pushing on a Red Stays a Decision, Not a Wall

A red check isn't on `push.md`'s list of stops, next to a secret or a generated file: it's a signal, not a wall. Sometimes a known red is already covered by what's coming, a following commit that closes what this one leaves open, or a cause already identified and judged to have no consequence for what's being pushed. When the person pushing has made that call, the request counts as agreement, exactly as `push.md` states in its first section: this file doesn't add a confirmation to ask for where there wasn't one.

What this file forbids, then, isn't pushing on an acknowledged red, it's staying quiet about it: reporting a green you haven't seen, letting people believe a check passed when it was worked around, or pushing on a red without naming it to whoever reads the history later.

## A Hook Doesn't Get Disabled in Silence

`--no-verify` or its equivalent skips the check instead of passing it, and afterward nothing tells a skipped hook apart from one honestly cleared. The same principle as for a CI check applies: skipping it on an explicit, acknowledged request isn't forbidden, skipping it by reflex to move faster or because it's inconvenient that day is.

## What Review Judges

Criterion 5 of `review.md` asks whether what you announce is true, and its veto shuts the door on an unverified claim. Announcing a green CI without having seen it, or staying quiet about a red you already knew about, falls into both at once.
