# Measure Before Optimizing

`code.md` says what readable, simple code looks like. This file talks about a different axis, speed and footprint, because the two sometimes pull in opposite directions and neither should give way blindly. An optimization that hasn't been measured isn't an optimization, it's a bet paid for in readability.

## You Don't Guess What's Slow

`research.md` asks the question that settles it: what would make me say this is false? On speed, intuition fails more often than it succeeds, because what looks costly reading a piece of code and what actually costs at runtime are rarely the same spot. The only thing that settles it is a measurement, a profiler, a latency log, a production counter, never an impression.

Guessing and then fixing based on that intuition amounts to applying a fix to a bug you haven't reproduced, exactly what `test.md` forbids for a functional correction. The reasoning is the same: an unverified hypothesis stays a hypothesis, however sound the common sense behind it looks.

## Premature Optimization Costs Without Buying Anything

A form that's faster on paper but harder to read is a real expense, paid at every rereading, against a gain that might not exist where it was placed. Criterion 4 of `review.md`, the simplest form that works, applies here without exception: a complexity nothing measures has no place, even when it comes from a good intention.

```
No
Replace the list with a hash table here, in case this function
becomes a hot path someday.

Yes
The function is called once per request on a list of three elements.
Nothing justifies replacing it before a profiler points to this spot.
```

The first measured neither the present nor the hypothesis that justifies it. The second names what's verifiable today and what's missing to change your mind, which is exactly `research.md`'s question.

## What Justifies Measuring

A stated latency budget, a resource limit already hit, a slowness a user reported, a cost that grows faster than what it processes. Intuition alone isn't enough, even informed by experience, because a system shifts under the feet of whoever still thinks they know it.

None of these signals requires guessing in advance which part of the code is at fault. That's exactly what the measurement establishes.

## What Justifies Optimizing

Once the measurement is done, you touch the spot it points to, not the one you suspected before measuring. You measure again after the change, using the same method, to confirm the gain exists and is worth the added complexity. A change that doesn't measure better than before gets removed, even if it seemed right in theory.

When the result keeps a less obvious form than the original, `comments.md` takes over: the declaration carries the short reason, what the measurement confirms, and what would break if you went back to the simple form. A reader who only sees the more complex code, without that comment, will simplify it in good faith and lose a gain nobody could show them.

## What Review Judges

Criterion 4 of `review.md` asks what can be removed without losing anything. An optimization with no measurement behind it is exactly that identifiable fat: it doesn't buy back its reading cost with a proof, and a proof, here, has a precise name, the one from before and the one from after.
