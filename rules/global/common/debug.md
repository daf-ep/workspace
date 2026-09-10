# Debug

`test.md` says a fix gets verified by reproducing the defect before applying it. This file says how you find the cause you're going to fix, in the gap between "something is broken" and "here's why."

## Don't Fix What You Haven't Reproduced

`test.md` already states this for the fix itself, and it starts earlier: as long as the defect doesn't trigger on demand, there's nothing to isolate or explain. A defect you've only seen once, under conditions you can't recreate, provides no proof, only a memory.

## When It Only Happens Somewhere Else

Reproducing isn't always possible on the machine doing the work. A defect tied to a scale, a dataset, or an environment you don't have access to still needs evidence before a fix, just not the same kind: the actual output, the actual error, the actual state of the system at the moment it happened, gathered from wherever it ran rather than guessed at from here. A fix written against a secondhand description carries the same risk as one written against a hypothesis never tested, and it gets reported the same way `test.md` asks a check to report what it couldn't verify, naming the gap rather than papering over it with confidence the evidence doesn't support.

## A Hypothesis Before an Intervention

`research.md` asks the question that settles it: what would make me say this is false? Facing a defect, it becomes: what would make me say it isn't this cause? You state the cause you suspect, name what would confirm it and what would rule it out, then run the experiment that answers. Changing a line to see if things improve isn't an experiment, it's a hope, and a hope that works by accident leaves the real cause in place. A hypothesis the experiment rules out gets its probe removed before the next one starts: leaving it in place in case it helps is how a fix ends up working for a reason nobody can name, the exact defect this file exists to prevent one step later.

## Isolate One Variable at a Time

When several things change between two attempts, the one that mattered can no longer be told apart from the one that didn't. You reduce the case to the smallest one that still reproduces the defect, one input at a time, one step at a time, keeping everything else identical. It's the same reflex as `push.md`'s transitive closure for finding the true extent of a change, applied in reverse: you remove until nothing unnecessary is left.

## The Change History Narrows It Too

A defect that used to not happen has a moment it started, and that moment is a variable to isolate exactly like an input is. Instead of only asking what's different about the case that triggers it, you can ask what's different about the code that now runs it: checking an older state against the current one narrows the search to the change that introduced the defect, rather than the whole surface that could have caused it. A defect present since the first version of the affected code has no such moment to find, and the input-based search above is where it has to be found instead.

## A Cause Explains, a Coincidence Just Comes Before

Removing what you suspect and watching the defect disappear isn't enough yet: you have to be able to say why this exact thing produced this exact symptom. Without that explanation, what you found might be a coincidence, something that happened alongside the real cause without being one, and the defect will come back in another form as soon as the conditions that silenced it change.

## Confirmed Once You Can Turn It Back On

Removing what you suspect and watching the defect disappear only shows correlation. Bringing the same cause back and watching the defect return is what tells correlation from coincidence, since a coincidence doesn't reappear on command. You still need the explanation the section above asks for: the toggle says the cause is real, the explanation says why it produces this exact symptom, and a fix resting on only one of the two rests on half the proof.

## The Fix Comes After, Not During

Once the cause is confirmed, writing the fix follows `code.md` and verifying it follows `test.md`, in that order: the proof first, the change second. A fix written before the cause is confirmed fixes a hypothesis, exactly what `test.md` forbids.

## What You Report

You name the cause you found in terms of what it explains, not just what changing it seemed to fix. You name what you ruled out along the way, so the same dead end doesn't get walked twice by whoever reads this next. When the investigation stops without a confirmed cause, because reproduction failed or the evidence available couldn't settle between two explanations, you say that plainly instead of naming the most likely guess as if it were the answer.

## What Review Judges

Criterion 1 of `review.md` asks whether the approach rests on something verified or on what you thought you knew going in. A fix born from an intervention with no hypothesis answers that question with the second answer, the one that costs points.
