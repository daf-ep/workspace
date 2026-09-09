# Don't Trust What You Don't Control

`push.md` stops a secret about to leave in a commit, and `review.md` makes it a veto. Both react once the secret is already written. This file says how to make sure that situation never comes up.

## Trust Stops at the Boundary

What comes from outside the program, a user input, a dependency's response, a file's contents, a request header, gets checked before use, because nothing guarantees it looks like what's expected. What stays inside, a call between two functions of the same module, a type the compiler has already checked, doesn't need rechecking: a guard repeated at every internal boundary adds nothing and hides the real boundary, the one touching the outside, behind noise.

An external dependency is a boundary like any other. Its code can be read before trusting it, but its output at runtime gets treated like any untrusted input, never like an extension of the program.

## What Never Gets Logged

A password, a token, a key, the body of an authorization header, a card number, anything that would identify a person beyond what the log's job requires. A log outlives the request that wrote it, copies more easily than you'd think, and gets read by more people than a commit does. What `push.md` catches in a diff, a log can spread without any review ever seeing it pass.

When a value is useful for diagnosis but sensitive as a whole, you log what identifies the case without exposing the value, an identifier rather than the secret it goes with.

## Least Privilege

A component asks for the access its job needs, never wider because it would be convenient later. It's the same principle `code.md` applies to code, "preparing for the future isn't guessing at it": access granted in anticipation is access nobody audits, and the day it serves a purpose other than planned, nothing has validated it for that use.

## What Review Judges

`review.md`'s veto, "a secret, a binary, or a derived file is about to leave in a commit," is what this file exists to keep you from reaching. A review that triggers this veto signals that this file's discipline slipped earlier, not just that `push.md` did its catch-up job well.
