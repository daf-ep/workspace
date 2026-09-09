# How We Work

This folder describes no code and belongs to no project. It says how to write, whatever you write and wherever you write it, and it copies as is from one repo to another.

The description of specific code lives elsewhere, in the internal documentation of the project that hosts it.

## What Every Project Declares

The rules that follow speak of roles, never of names. They say "the internal documentation," "the analysis command," "the commit tags," and it's the project that says what these words mean for it.

A project that adopts this folder declares eight things, once, in its root instructions file:

| What it declares | What it can be |
| --- | --- |
| where the internal documentation lives | a hidden folder, a `docs/` folder, a wiki |
| which files count as code | Dart and TypeScript, say, and nothing else |
| the command that builds or analyzes | whatever the project runs to type-check and lint, defined however it wants |
| the command that runs the tests, absent if the project doesn't have any yet | whatever the project runs to execute its test suite |
| the commit message format and the list of tags | `[TAG]: message`, and the tags allowed |
| the branches, and which one receives commits | push to `dev`, `main` follows |
| the map of scopes | which zones of the repo are separate subjects |
| where the shared code lives | a foundation package, a `common/` folder, a `shared/` root |

As long as these eight lines exist somewhere, the eleven gates apply without adjustment. `test.md` says what the absence of a test command changes for the second check and for the decision to write the project's first test. Nothing in `rules/` needs to be edited to change project, and a file in this folder that named a specific path, repo, or tool would be a defect to fix.

## Fine-Grained Customization, in `customization/`

An eight-line declaration isn't enough everywhere. One aspect of a `common/` subject can have a way of doing things specific to a company. That aspect lives in a `customization/` file that carries the same name as the `common/` file whose aspect it customizes: `push.md` for what `common/push.md` says to write, `code.md` for the sharing threshold that `common/code.md` sets by default at the third use, `review.md` for the passing threshold and the number of reviewers that `common/review.md` sets by default.

Commit tags can therefore end up declared in two places, the project's root instructions file and `customization/push.md`. When both exist and diverge, `customization/push.md` has authority over the tags, exactly as it has authority over everything else it customizes; the root file remains the source for the other seven lines of its declaration.

A `customization/` file never repeats the mechanism, it only says what **this particular project** does differently. It stays minimal by default, a handful of sections that each say "no exception" until someone has filled them in, and a new project only has to replace the lines that matter. The matching `common/` file points to it and keeps all of the mechanism's complexity.

`customization/customization.md` is the only one that stands apart: no `common/` subject talks about it, because it gathers preferences that cut across all the work on the project, like the language the conversation is held in. A single list, under "Global rules to follow": one rule per line, one default line saying that none is imposed until the project has added one.

## The Eleven Gates

They follow in order, and each assumes the previous one has been cleared. Two of them only apply in a specific circumstance, `debug.md` when facing a defect, and `ci.md` when the project has a CI; the others apply every time, including when their content amounts to saying that nothing calls for them this time.

**1. `common/research.md`, before writing.** Where to find the answer depending on the question at hand, and what counts as proof. The file also lists what looks like proof without being one, from sales talk to one's own certainty.

**2. `common/debug.md`, facing a defect.** How to find the cause you're going to fix before touching it: reproduce, form a hypothesis rather than intervening at random, isolate one variable at a time, tell a cause apart from a coincidence.

**3. `common/code.md`, while writing.** What readable code looks like: what gives away machine-written code, the function that does the job its name promises, the class that exposes only what its name justifies, the language mechanisms used instead of reinventing them, and the moment a function used in several places moves into shared code.

**4. `common/performance.md`, also while writing.** Why an optimization that hasn't been measured isn't one, what justifies measuring, what justifies then touching the code, and how to document what stays less readable once the gain is confirmed.

**5. `common/security.md`, also while writing.** Where the trust granted to an input stops, what never gets logged, and why access is granted as narrowly as possible rather than as broadly as convenient.

**6. `common/comments.md`, also while writing.** In which files a comment has the right to exist, what it should say when there is one, what to reach for instead when a passage needs explaining, and where the why that doesn't fit on one line goes. Its last section, "How to write it," spills past comments: it applies to **any text you write**, including a test name, an assertion message, a log line, and a label a command prints. That's where the signs never to use live, arrows and emoji first.

**7. `common/context.md`, in the same motion.** The why that `comments.md` sends out of the source lands there, whether the project writes it by hand, in files, or captures it with a sync command it runs instead. The rule that governs the hand-written form is that documentation describes the present: when a decision changes, the block gets rewritten instead of stacking the new version under the old one with a date. When a project syncs instead, the same file says what counts as a decision worth capturing, the four fields it always carries, why syncing replaces a record instead of appending to it, and what stands in for a diff when nobody reads one.

**8. `common/test.md`, before saying it's done.** The three checks to run, the difference between rereading your diff and actually exercising your code, how to establish what the change touches, and when a test is warranted. It also says what to report, including what you couldn't verify.

**9. `common/review.md`, before committing.** Five criteria scored two points each, and the defects a score never buys back. Below 8 out of 10, you redo it.

**10. `common/push.md`, to commit.** A commit holds one subject. The file explains how to find the real extent of a scope in a messy working directory, how to choose the tag, how to write the message, and in which cases you stop instead of pushing.

**11. `common/ci.md`, after pushing, when the project has a CI.** Why a local green proves nothing about the CI, how to treat a flaky check, and why pushing on an acknowledged red stays a decision you name rather than a wall.

The one it costs the most to skip is the first. Work that's impeccably written, tested, and scored is still work to throw away if it rests on a bad decision. Judging work that has never run doesn't make much more sense either, since the "it runs" criterion would score zero and the total would be capped from the start.

## Form Depends on the Language

`common/` carries the decisions, the language folders carry only the form. Reading a language file without having read `common/comments.md` is like learning how to write a comment without knowing whether one is needed.

There's one folder per language, and a project only opens the ones that concern it. A project written in a language that doesn't have its file yet adds one, built on the same plan: the comment forms the language distinguishes, what its tools read and discard, and what deserves documentation.

`dart/comments.md` covers the three comment forms, the summary and its paragraph, the grammatical form that announces a member's nature, the brackets that turn an identifier into a link, and why there's neither `@param` nor `@returns`. It follows Effective Dart.

`js/comments.md` covers the three forms and the single-star trap, what the compiler reads in a comment and what it discards, the tags that stay useful once you're writing TypeScript, and the comments that drive tooling.

## What Isn't Here

Conventions that fit on one line, like log naming or the language of identifiers, live in the project's instructions file. They apply without needing to open anything, and `rules/` takes over as soon as a rule needs more than one line to be applied correctly.

Commands don't belong here either. `common/test.md` says that you must execute and when a test is warranted, never which one to run nor where test files live. That depends on the project, so it lives with the project.
