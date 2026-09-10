# Don't Trust What You Don't Control

`push.md` stops a secret about to leave in a commit, and `review.md` makes it a veto. Both react once the secret is already written. This file says how to make sure that situation never comes up.

## Trust Stops at the Boundary

What comes from outside the program's trust domain, a user input, a dependency's response, a file's contents, a request header, gets checked before use, because nothing guarantees it looks like what's expected. A crossing isn't only a single moment in the code either: a value checked once and used later, after something else has had the chance to run in between, has effectively crossed the boundary again before that use, so the check has to sit next to the use it protects rather than somewhere earlier in the flow. What stays inside a single trust domain, a call between two functions of the same module, a type the compiler has already checked, doesn't need rechecking: a guard repeated at every internal boundary adds nothing and hides the real boundary, the one touching the outside, behind noise.

An external dependency is a boundary like any other, whether it's pulled in at build time or its code has been copied into the repository. Reading and owning that code changes who has to track what gets published about it, but never what it's allowed to return at runtime: its output still gets checked like any other untrusted input, never treated as an extension of the program just because its source is sitting right there to read. Trusting a dependency at the moment it's added isn't trusting it forever either: what's known about its published flaws keeps changing after that moment, for every version already in use, not only for the one being considered next.

## Untrusted Data Never Becomes Structure

A checked value that looks fine on its own can still cause damage once it gets stitched into a command, a query, or a document as if it were part of the instruction rather than a piece of data inside it. The two stay separate: data passed as data, never spliced as text into the part that says what to run. A value confirmed to be a harmless string is still dangerous the moment a larger instruction gets built by joining it in as a fragment, because the check that passed it only proved it was a valid value, never that it was safe to read as part of the instruction itself.

## What Never Gets Logged

A password, a token, a key, the body of an authorization header, a card number, an email address, an IP address, anything that would identify a person beyond what the log's job requires. A log outlives the request that wrote it, copies more easily than you'd think, and gets read by more people than a commit does. What `push.md` catches in a diff, a log can spread without any review ever seeing it pass, so the same review that reads a diff for a secret about to leave also reads a new log line for one, on an ongoing basis rather than once when the line is written.

When a value is useful for diagnosis but sensitive as a whole, you log what identifies the case without exposing the value, but the identifier has to be one that means nothing on its own. An email or any other value from the list above stands in for the secret just as badly as the secret itself would: what replaces it needs to be a case number or a request id, something that carries no identity until someone with the right access looks it up.

## What an Error Response Never Reveals

A log is read by people trusted with the system's internals. A response goes back to whoever asked, trusted or not, and the two never get held to the same disclosure standard. What comes back to a caller who failed a check says that it failed, not why in a way that teaches them what to try next: an internal path, a query fragment, a stack trace, or a hint about which part of a check specifically failed, such as telling an unrecognized account apart from a wrong password on the same login attempt. The detail that helps diagnose the failure belongs in the log this file already restricts, read by someone with the access for it, never in the answer sent back to the request that triggered it.

## Being Allowed In Isn't Being Allowed to This

Confirming who's asking answers a different question than confirming what they're allowed to touch, and passing the first check is routinely mistaken for having passed the second. A request that carries a real, valid identity still names a specific resource, and that resource gets checked against this identity every time, never assumed safe because the request came from someone real. The common failure isn't a stranger walking through an open door, it's a known caller reaching for a neighbor's resource because the code confirmed they were someone, not that they were allowed to this one.

## Least Privilege

A component asks for the access its job needs, never wider because it would be convenient later. It's the same principle `code.md` applies to code, "preparing for the future isn't guessing at it": access granted in anticipation is access nobody audits, and the day it serves a purpose other than planned, nothing has validated it for that use.

Whoever asks for an access has already decided it's justified, which makes them the worst judge of whether it's actually scoped right. The scope needs a second look from someone other than the requester before it's granted: a component's own claim that it needs no more than this is a starting point, not the verification itself.

## Access Gets Revoked, Not Just Granted

Granting the right access is half the job. The other half is taking it away once the need it served is gone, and a grant nobody ever revisits is not a decision anymore, it's an accident waiting for something to reach through it. What keeps this real is tying the review to something that actually changes, a role that moves on, a component that gets retired, a task that ends, rather than trusting that someone will think to check on their own.

The same holds for a secret rather than a grant. One that has left its intended boundary, through a log, a diff, or a channel it shouldn't have reached, gets replaced rather than trusted again once it's out of sight, because removing the copy that was seen says nothing about the copies nobody noticed.

## What Review Judges

`review.md`'s veto, "a secret, a binary, or a derived file is about to leave in a commit," is what this file exists to keep you from reaching. A review that triggers this veto signals that this file's discipline slipped earlier, not just that `push.md` did its catch-up job well.
