# Don't Trust What You Don't Control

`push.md` stops a secret about to leave in a commit, and `review.md` makes it a veto. Both react once the secret is already written. This file says how to make sure that situation never comes up.

## Trust Stops at the Boundary

What comes from outside the program's trust domain, a user input, a dependency's response, a file's contents, a request header, gets checked before use, because nothing guarantees it looks like what's expected. A crossing isn't only a single moment in the code either: a value checked once and used later, after something else has had the chance to run in between, has effectively crossed the boundary again before that use, so the check has to sit next to the use it protects rather than somewhere earlier in the flow. What stays inside a single trust domain, a call between two functions of the same module, a type the compiler has already checked, doesn't need rechecking: a guard repeated at every internal boundary adds nothing and hides the real boundary, the one touching the outside, behind noise.

An external dependency is a boundary like any other, whether it's pulled in at build time or its code has been copied into the repository. Reading and owning that code changes who has to track what gets published about it, but never what it's allowed to return at runtime: its output still gets checked like any other untrusted input, never treated as an extension of the program just because its source is sitting right there to read.

## What Never Gets Logged

A password, a token, a key, the body of an authorization header, a card number, an email address, an IP address, anything that would identify a person beyond what the log's job requires. A log outlives the request that wrote it, copies more easily than you'd think, and gets read by more people than a commit does. What `push.md` catches in a diff, a log can spread without any review ever seeing it pass, so the same review that reads a diff for a secret about to leave also reads a new log line for one, on an ongoing basis rather than once when the line is written.

When a value is useful for diagnosis but sensitive as a whole, you log what identifies the case without exposing the value, but the identifier has to be one that means nothing on its own. An email or any other value from the list above stands in for the secret just as badly as the secret itself would: what replaces it needs to be a case number or a request id, something that carries no identity until someone with the right access looks it up.

## Least Privilege

A component asks for the access its job needs, never wider because it would be convenient later. It's the same principle `code.md` applies to code, "preparing for the future isn't guessing at it": access granted in anticipation is access nobody audits, and the day it serves a purpose other than planned, nothing has validated it for that use.

Whoever asks for an access has already decided it's justified, which makes them the worst judge of whether it's actually scoped right. The scope needs a second look from someone other than the requester before it's granted: a component's own claim that it needs no more than this is a starting point, not the verification itself.

## Access Gets Revoked, Not Just Granted

Granting the right access is half the job. The other half is taking it away once the need it served is gone, and a grant nobody ever revisits is not a decision anymore, it's an accident waiting for something to reach through it. What keeps this real is tying the review to something that actually changes, a role that moves on, a component that gets retired, a task that ends, rather than trusting that someone will think to check on their own.

## What Review Judges

`review.md`'s veto, "a secret, a binary, or a derived file is about to leave in a commit," is what this file exists to keep you from reaching. A review that triggers this veto signals that this file's discipline slipped earlier, not just that `push.md` did its catch-up job well.
