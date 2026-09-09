# Research

The question to ask before writing is whether you know, or whether you think you know. Seen from the inside the two look a lot alike, and it's the second one that costs. It gets paid for later, at the point where the choice it drove is already everywhere in the code.

It isn't about checking everything. It's about knowing, for every decision that commits to something, where the answer comes from.

## Where to Look

There are three places, and each has authority over a different question. Asking the question in the wrong place is where the most time gets lost.

**Code says what is.** A problem already solved here already has a solution here, so you start by looking for the symbol, its callers, the neighboring module that does almost the same thing. You gain twice, because you don't rewrite what exists and because you write in the repo's own form. A better solution in the abstract but foreign to the code it joins stays a bad solution.

**Internal documentation says why.** Code shows what's done, never why it isn't done otherwise, and that's where the accepted trade-offs live, a service's limits, the dead ends already explored. It's the source skipped most often, and the one whose omission costs the most, because it holds decisions already settled. Undoing a choice without knowing why it was made means repeating the mistake it avoided, and discovering it a second time at the same price.

**The outside world says what a tool you didn't write does.** A dependency's real behavior, a spec, a format, a platform trap, a service's limit. You don't go outside to settle an internal design decision. Nobody out there knows the constraint that determines it, and you come back with a general answer to a question that wasn't.

## What Counts as Proof

The three levels that follow go from strongest to weakest, and you stop at the first one that settles it.

The strongest is observed behavior. You run it, you look at what comes out. It's also often the cheapest, since five minutes of running beats an hour of reading.

Next comes the primary source, that is, the official documentation for the version in use, the spec, the dependency's own code, its changelog, or its tickets.

Last, a secondary source you can verify what it claims: a piece that shows the code, names the version it's talking about, and whose experiment you can rerun yourself.

## What Isn't Proof

**Sales talk.** Fast, modern, robust, production-ready, best practice. Those are adjectives, not measurements. A page trying to convince doesn't have to demonstrate, that's its job.

**Popularity.** Stars, downloads, and everyone using it measure a tool's reach, not its fit for our problem.

**A text with no version or date.** The interface it talks about may have changed three times since, and an answer that was right in its time doesn't warn that it has stopped being one.

**An example that works elsewhere.** A README excerpt assumes its whole context, the version, the runtime, the platform, the build mode.

**One's own certainty**, the most dangerous one because it doesn't look like a source. An interface you're sure of is an interface you haven't checked.

**Text produced by a model**, mine included. It's a lead, and you confirm it against the primary source before using it, never the other way around.

## True in General, False Here

A proof has to hold in our own context. Before concluding, you check it against what sets us apart: the tool's exact version, not the latest one, the runtime and the platform, the mode you're running in, and the limits of the plan subscribed to, which often make unavailable what the documentation presents as a given.

An exact answer read in the wrong context is indistinguishable from a false one.

## The Question That Settles It

When in doubt, the right question is: what would make me say this is false?

If no observation could change your mind, it isn't a technical decision, it's a preference, and it should be announced as one. The question also helps find what to try, because the answer it gets describes exactly the experiment to run.

## Decide, Then Stop

A structural decision, one you won't undo without touching everything, gets made against at least one other option. You keep what was ruled out and why, or the same discussion starts over in six months with the same arguments and no conclusion.

When nothing settles it after a reasonable time, you pick the reversible option over the best one on paper, you write down the uncertainty and what would resolve it, and you move on. Continuing past that point is no longer rigor, it's a way of not deciding.

The proof that drove the decision doesn't live in the code. It goes into the documentation, with what was ruled out. A decision whose reason is written nowhere will be re-litigated, and nothing guarantees it will go the same way twice.
