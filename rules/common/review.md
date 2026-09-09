# Judge: the Last Gate Before the Commit

The work is written, it has run. What's left is the question almost always skipped: **is it actually good?** Not "does it work," that's `test.md`, and it's already answered.

A commit is hard to undo; a judgment made three minutes earlier costs nothing.

**A project can demand more.** When `../customization/review.md` exists, it says the passing threshold this project requires and whether a peer has to judge on top of the self-assessment; the threshold of "8" that comes up in this file is the one that applies by default. The rest, the five criteria and the vetoes, doesn't get customized and stays defined here.

## The Posture: Look for the Defect, Not the Confirmation

You reread looking for what's wrong, as if the work came from someone else and had to be rejected. Two habits keep it honest:

- **score before summarizing.** Once you've written an affirmative account, you'll defend it;
- **name the work's weakest point.** There's always one. Not being able to name it means you haven't looked.

## Five Criteria, Two Points Each

Each one scores **0, 1, or 2**. No half points: that's a way of not deciding.

### 1. It Answers What Was Asked

- Am I delivering what was asked, or what I felt like doing instead?
- Did I quietly shrink the request because a part was unpleasant? Widen it on my own? Leave a part hanging without saying so?
- Does the approach rest on something verified, or on what I thought I knew going in?

`2` everything's there, the approach is grounded, what was left out is named · `1` a piece was trimmed or added without saying so · `0` I'm answering a different question.

### 2. It Runs, and I Watched It Run

- Did I execute what I just wrote, or am I inferring it from the code?
- Refusal cases, empty input, absence: tried?
- Is the blast radius covered, callers, outputs produced, whatever already exercised it?
- Was a test needed, and did I write it?

`2` executed, edge cases covered, impact verified · `1` the happy path only · `0` nothing ran.

### 3. It Fits the Repo

- Are conventions respected, including the ones nothing checks automatically?
- Is the why written where it should live, rather than left in the source?
- Does the documentation describing this code still tell the truth?
- Does it look like the neighboring code: naming, structure, how errors are named?

`2` indistinguishable from the rest, docs current · `1` compliant but docs lagging · `0` it clashes, or it breaks an explicit rule.

### 4. It's the Simplest Form That Works

- What can I remove without losing anything?
- Does a function do the job it's named for, and does a class expose only what its name justifies? `code.md` details what gets judged here.
- An abstraction for a single use, an option nobody will pass, a layer that only forwards?
- Did I duplicate something that already existed?
- Is there leftover scaffolding: dead code, a forgotten trial, a temp file, a test folder?

`2` nothing to remove without breaking something · `1` identifiable fat · `0` the solution is more complicated than the problem.

### 5. What I Say About It Is True

- Everything I claim to have verified, did I actually run it?
- Am I announcing green on something I haven't seen green?
- Are the limits and what's left to do stated, or buried?
- Did I use "it should work" anywhere?

`2` the account and reality match · `1` accurate but optimistic, missing a caveat · `0` I'm announcing a check I didn't do.

## The Vetoes: a Score Never Buys Them Back

An average can hide a fatal defect. These cases force a rewrite even at 9:

- something was never executed;
- a claim is unverified, or false;
- work was destroyed, or a file deleted without being looked at first;
- a secret, a binary, or a derived file is about to leave in a commit;
- the change does something that wasn't asked for, without warning;
- an explicit rule of the repo is knowingly broken.

## Making the Score Honest

A score you give yourself climbs on its own. Three rules keep it in check:

**A point lost, a defect named.** You don't take off a point "for form": you write down which one and why. Conversely, a point lost with no nameable defect isn't lost.

**A `2` is earned by what you did**, not by what you believe. "It runs" only scores `2` if you can say which command ran and what it returned.

**Rounding up is the score below.** A hesitant 8 is a 7: doubt counts against the work.

## Below 8, You Rewrite

No patch on the symptom: you identify **which criterion** cost the points, redo that part, then rescore the whole thing, since a rewrite can damage a criterion that was fine.

Three passes below 8 on **the same criterion** are no longer an execution problem: the approach, or the request, is wrong. You stop and say so.

`8` is a floor, not a target. A `10` exists: it's work where you seriously tried to find the defect and didn't.

## At 8 or Above

You move on to `push.md`. The score goes nowhere, it doesn't have to survive the gate it just opened. What survives is what it made you fix.
