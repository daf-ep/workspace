# Test

Writing isn't finishing. A change is done when it has run, not when it looks right, and "it should work" isn't a state, it's a hypothesis.

This rule comes before writing tests and doesn't replace it. Running it is mandatory, writing a test is a decision.

## The Three Checks

They go from cheapest to slowest, and you don't skip the third one just because the first two are green.

The first is that it compiles and analyzes cleanly. It's the dumbest, most rewarding check there is, because a strict analyzer catches what no careful rereading ever does.

The second is that the existing suite passes. It says nothing about what you just wrote, it only says you haven't broken anything else.

The third is that the path you just wrote gets exercised for real. It's the one that gets skipped, and the only one that speaks to today's work.

## Exercising Isn't Rereading

Rereading your own diff proves nothing, because you're rereading what you meant to write. You have to go through the real entry point, with real inputs.

For a command, you run it, with and without its options, and on the cases where it should refuse. A refusal that doesn't refuse is a complete bug. For a function, you call it, from a test or from an entry point. For a fix, you reproduce the defect, confirm it's really there, apply the fix, and confirm it goes away, in that order: a fix applied to a bug never reproduced fixes a hypothesis. For an output, whether it's a generated file, a render, or a message, you look at the result produced, not the code that produces it.

The failing case counts as much as the passing one. Empty input, missing file, incompatible option, an unresponsive terminal: that's where new code breaks, and never on the example you had in mind while writing it.

## Everything the Change Touches Has to Answer

The question isn't whether the new thing works, it's whether everything that depended on what you changed still works. The two have different answers.

The blast radius gets established, it doesn't get guessed. You have to look at who calls the modified symbol, what gets produced from it, what reads it without calling it, like a config, a template, or a contract between two components, and what already exercised it without having been rerun since.

Renaming, moving, and extracting are the trickiest cases. The compiler catches part of it and lets through everything that travels through a string, a file path, or reflection.

## When to Write a Test

When its absence would let the problem come back.

A defect you found calls for one, and it's written before the fix, failing without it. A rule, a refusal, or a limit call for one too, because those paths never get walked by normal use, and nothing will signal the day they stop working. A pure function with branches offers the best return there is, plenty of cases for very little setup. And a behavior you just decided on deserves a test, one that keeps the decision from being undone by accident.

You don't need one when running it says everything: a rename the compiler checks in full, a text change, a move with no behavior change, a tooling setting.

When in doubt, the question is what will catch it if it breaks in six months. When the answer is nobody, the test is warranted.

## When the Project Doesn't Have Tests Yet

The eight-line declaration in `rules.md` assumes a command that runs the tests. When it doesn't exist yet, the second check has nothing to check, and that isn't a break in the rule: a suite that doesn't exist can neither pass nor fail. The first and third stay mandatory exactly as before, the third then happening by hand instead of through a test file.

The lack of infrastructure isn't an excuse to stay quiet about, though. It gets reported like anything you couldn't verify, with the reason when it's known, rather than being worked around in silence.

Writing a project's first test is a heavier decision than adding a test to a suite already there, since it commits to a command, a location, and a convention someone will have to pick up afterward. It follows the same question as "When to Write a Test," what will catch it if it breaks in six months, weighed this time against what it costs to introduce the infrastructure for a single line. A project with no tests therefore doesn't oblige the first change that touches it to give it any.

## A Test Reads Without a Comment

A test file carries none, and `comments.md` says why: what you'd have written as a comment doesn't show up when the suite is red, while the case's name and the assertion message do. A setup that needs an explanation actually needs a named setup function, or a named constant instead of the literal you were about to comment.

## A Test That Can't Fail Tests Nothing

You see it red before you see it green. A test written after the fix that passes on the first try has demonstrated nothing, and it might not verify anything at all.

Written after the fact, it also tends to marry the observed behavior instead of the intended one, bug included, because the output gets copied into the expectation. The expectation gets decided before looking at the result.

## Three Ways to Lie Without Meaning To

Saying tests pass without having run them is the most frequent, and the only one that's free to avoid.

Running part of it and concluding about the whole is another. A green file says nothing about the suite, and a suite green locally says nothing about continuous integration.

Fixing a test instead of the code is the third. When a test fails, the first hypothesis is that the change is wrong, and adjusting the expectation removes the only warning you had.

## What You Create to Test, You Remove

Folders, sample projects, temporary files, inputs dropped somewhere to see how the code reacts: all of that gets removed once the check is done, or it becomes a state someone will eventually mistake for real.

And it gets removed by looking at what you're deleting. A broad deletion run in a directory that also holds real work costs far more than the time it saves, especially where nothing is versioned yet. You list before erasing, you name what you erase, and you never erase a pattern.

## What You Report

You say what you ran, and you say what you didn't run.

A check announced but not done is worse than no check, because it transfers confidence with nothing behind it. When part of it couldn't be exercised, for lack of a service, because of an interactive terminal, or a missing platform, you say so with the reason, and you name what's left to verify.

When something fails, you report it with the real output. A failure described from memory loses exactly the detail that would have made it understandable.
