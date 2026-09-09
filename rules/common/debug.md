# Debug

`test.md` says a fix gets verified by reproducing the defect before applying it. This file says how you find the cause you're going to fix, in the gap between "something is broken" and "here's why."

## Don't Fix What You Haven't Reproduced

`test.md` already states this for the fix itself, and it starts earlier: as long as the defect doesn't trigger on demand, there's nothing to isolate or explain. A defect you've only seen once, under conditions you can't recreate, provides no proof, only a memory.

## A Hypothesis Before an Intervention

`research.md` asks the question that settles it: what would make me say this is false? Facing a defect, it becomes: what would make me say it isn't this cause? You state the cause you suspect, name what would confirm it and what would rule it out, then run the experiment that answers. Changing a line to see if things improve isn't an experiment, it's a hope, and a hope that works by accident leaves the real cause in place.

## Isolate One Variable at a Time

When several things change between two attempts, the one that mattered can no longer be told apart from the one that didn't. You reduce the case to the smallest one that still reproduces the defect, one input at a time, one step at a time, keeping everything else identical. It's the same reflex as `push.md`'s transitive closure for finding the true extent of a change, applied in reverse: you remove until nothing unnecessary is left.

## A Cause Explains, a Coincidence Just Comes Before

Removing what you suspect and watching the defect disappear isn't enough yet: you have to be able to say why this exact thing produced this exact symptom. Without that explanation, what you found might be a coincidence, something that happened alongside the real cause without being one, and the defect will come back in another form as soon as the conditions that silenced it change.

## The Fix Comes After, Not During

Once the cause is confirmed, writing the fix follows `code.md` and verifying it follows `test.md`, in that order: the proof first, the change second. A fix written before the cause is confirmed fixes a hypothesis, exactly what `test.md` forbids.

## What Review Judges

Criterion 1 of `review.md` asks whether the approach rests on something verified or on what you thought you knew going in. A fix born from an intervention with no hypothesis answers that question with the second answer, the one that costs points.
