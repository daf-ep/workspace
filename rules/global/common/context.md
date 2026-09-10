# Context

`comments.md` says the why leaves the source. This file says where it lands and how it stays true, whether a project writes it by hand, in files, or captures it with a sync command it runs instead.

Internal documentation is the only place where a decision's context lives. When it isn't published, which is the most common case, it can describe trade-offs, vendor limits, and infrastructure states you wouldn't write in a file meant to leave the repo.

## Docs Describe the Present

This is the rule everything else follows from. A documentation file says what's true today, and nothing else. It doesn't tell the story of how things got there.

When a decision changes, you don't stack the new version under the old one with a date. You rewrite the block concerned so it describes the new state, and the old text disappears. Someone opening the file should read the system's current state without being able to guess it changed yesterday.

Here's the shape it takes when the rule isn't kept:

```md
## Continuous Integration (2026-08-10)

The workflow runs on every push and every pull request. The main job
runs in four stages ...

Added 2026-08-14: until then the CI only ran the last stage. Until now
nothing ran the tests automatically, the suite was green because
someone remembered to run it.
```

Three things are wrong. The heading carries a date that describes nothing about the mechanism. The last paragraph tells the story of a change instead of describing a state. And the reader has to read both versions to figure out which one is true, when only the second is.

What's left after rewriting is the section without its date and without its last paragraph. The four stages describe the CI as it runs, which is enough. If the fact that the suite didn't run automatically still had a consequence today, it would be written in the present, as a property of the system, not as an episode.

The history already exists, and it lives elsewhere. Commits say when and by whom, and `git log -p` on a path gives the full chain. Documentation doesn't need to duplicate it, and a duplicate that ages worse than the original does nobody any favors.

## Words That Give Away a History

They're easy to spot, and their presence almost always signals a block that got appended to instead of rewritten: now, previously, formerly, as of, since version, has been replaced by, used to, following.

A date follows the same rule, with one exception. It has no business in the description of a mechanism. It's legitimate, though, when it dates a reading that will need redoing, like an infrastructure state, an expiring key, or a plan limit observed on a given day. There, the date is part of the fact, because it says from when to be wary.

## What Was Ruled Out Isn't History

`research.md` asks you to keep what was ruled out and why, or the same discussion starts over in six months with the same arguments and no conclusion. That doesn't conflict with the rule of the present, as long as it's written in the present.

A ruled-out option is a property of the system as it stands today, not an episode of its past. "The local counter isn't used, because it lives in a single worker and the effective limit would end up multiplied by the number of replicas" is a present-tense sentence, one that stays true as long as the choice holds. "We used a local counter, we moved to a shared one" is a narrative, one that starts aging the day it's written.

The difference lies in what you're describing: the reason for the current choice, never the movement that led to it.

## Where Things Go

Documentation follows the code's tree, root by root. A code folder with several subfolders gets a doc folder with an entry file and one file per direct subfolder. A folder with no subfolder gets a single flat file.

A folder's entry file says which files to open depending on the task, and it's the one read first.

When a project is built on a shared foundation, nothing specific to the project moves up into the foundation's documentation, and nothing generic moves down into the project's.

## The Entry File Is a Map, Not Just a Router

A folder's entry file doesn't only say which files to open for a task, it explains what the folder holds: every direct file and subfolder gets a line saying what it's for. Someone who has never opened the folder should be able to read this one file and already know what they'd find before opening anything.

Not every line has to stand alone. When several files or subfolders serve the same purpose, or hold nothing worth explaining beyond what their name and place already say, one line covers the group instead of repeating the same sentence with a different name each time. What earns its own line is judged the way `comments.md` judges a comment: silent when the name and the place already say enough, spelled out when they don't.

```
No
`handlers/create.ts` handles creation.
`handlers/update.ts` handles updates.
`handlers/delete.ts` handles deletion.
`handlers/list.ts` handles listing.

Yes
`handlers/` holds one file per verb of the resource's API, named after
the verb, nothing beyond what the name says.
```

The map stays part of the entry file rather than a separate one, because a second file invites the two to drift apart. It's kept current in the same motion as the code that changes the tree, exactly as the rest of this file asks: a file added, moved, or removed updates the line that names it, or the group it belongs to, before the change is called done.

## Keeping Docs Up to Date

This happens in the same motion as the code change, never in a separate pass put off for later.

You list what moved first.

```
git diff --name-only HEAD
git status --short --untracked-files=all
```

For each modified file, you look for the documentation file that matches it by following the tree, or by the project's index when the path isn't enough.

Then, and this is the part that matters, you read the documentation file in full before touching it. You can't rewrite a block you haven't read, and it's by reading the rest that you notice today's change invalidates a paragraph three sections further down.

Then you rewrite the blocks affected. Surgical at the scale of the file, complete at the scale of the block: you don't redo a three-hundred-line file because a table gained a column, but the paragraph talking about that table gets rewritten in full rather than patched.

Finally you say what got updated, and what didn't need it.

## The Cases That Get Missed

**The code disappears, the doc stays.** A removed module takes its documentation file with it, and the line that named it in the index and in the parent folder's entry file. A doc describing code that no longer exists is worse than no doc, because it gets believed.

**The code moves, the doc's paths point at nothing.** Documentation cites file paths constantly, and renaming a folder breaks all of them silently.

**A new file has no match.** That means the documentation file needs creating, not that the rule doesn't apply.

**A file arrives or leaves, and the entry file's map goes stale.** The map follows the same rule as the rest of the entry file: a file added, moved, or removed updates the line that names it, or the group it belongs to, in the same motion, not left for whoever opens the folder next to notice the mismatch.

**The change crosses two roots.** A module that touches its contract, code generated from that contract, and a shared type gets documented where the decision was made, with a pointer from the others. Not three copies that will end up diverging.

## When a Project Syncs Instead of Writing

Everything above assumes a project writes its documentation by hand, in files, a block rewritten at a time. When a project declares a sync command instead, one that writes the project's context into a structured base, this section says what that command has to capture and how, so the record stays reliable without anyone ever having to reread a diff of it. The standard that judges everything below: someone new to the project who writes a request to an agent should never have to explain by hand a constraint this record should already make findable on its own.

## What Counts as a Decision

A change isn't always a decision. A decision is a choice made against at least one other option, the kind `research.md` already asks you to keep on record.

```
No
Rename `fetchUser` to `loadUser` because the name was poorly chosen.

Yes
In the module that receives payment events, set the incoming
webhook's rate limit to 50 calls per second per key, because an
August 11 load test showed the downstream fraud-scoring service
falls over past 60.
```

The first carries nothing to sync: it's a correction, not a trade-off. The second carries the four reasons a decision exists to be recorded: a precise place, a precise choice, a verifiable reason, a consequence for whoever touches this path next.

A rename, a rewrite in the same shape, a dependency version bump generally carry no decision worth syncing, unless the rename itself carries a trade-off: a transition period on an already-published API, a deprecation that lets both names coexist while callers migrate. In that case, it's no longer the shape of the change that matters but what it commits to, exactly like any other decision.

This judgment doesn't fall to the change's author alone. It goes through the same review as the rest of the work, `review.md`, rather than an individual call nobody else checks: a change that looks harmless can carry consequences its author isn't best placed to measure, and an unverified preference should never enter the record with the same authority as a decision actually made.

## Four Fields, Never Fewer

A synced decision always carries four things, never three:

```
Decided     In the module that receives payment events, the incoming
            webhook caps calls to the fraud-scoring service at 50 per
            second per API key.
Why         An August 11 load test shows this service falls over past
            60 calls per second. A queue was ruled out: it would have
            masked the outage instead of preventing it.
Implies     Any new path that loops over several events must check the
            limit once per item, never once before the loop, or the
            August 11 outage comes back in another shape.
Verified    Replayed the August 11 load test with the limit in place:
            the scoring service stays stable up to 200 calls per
            second ahead of the cap.
```

What was decided states a fact about the system today, not a story of how it got there, and it names without hedging the part of the system it concerns. A repo that carries a single project from end to end can afford the ellipsis, but a repo that carries several at once, several services, several packages, sometimes several applications side by side, never can: the same word, webhook, cache, queue, often names more than one thing there, and a decision that only says "the webhook" without saying which one has captured only half of what matters. An agent working in another part of the same repo six months later can't guess which of the two was meant, and guessing wrong then costs as much as knowing nothing at all. That holds even when the repo carries a single project today: the same ambiguity is waiting for the day a second one moves in, and naming the place from the start costs one clause, while guessing afterward which of the two was meant costs far more. The place gets named in the vocabulary the project already uses to carve itself up, a module, a service, a layer, never a file path copied as is, which will date at the first rename.

Why carries the reasoning and what was ruled out, not just what was chosen. Implies states the consequence for whoever touches this part of the system next, precisely enough that an agent reading only this field knows what to do. Verified states what confirmed it works and what a future change has to reproduce or extend to stay compliant, the same thing `test.md` asks of a fix applied to a real bug rather than a hypothesis. A record missing any of the four isn't a decision, it's a note, and it doesn't get synced as one.

This floor isn't a ceiling. An operational decision, one that touches a resource limit or a production number, additionally carries what it would break if exceeded and how fast that would show, a field of its own rather than buried in a sentence once the decision is complex enough to earn it. A decision that builds on another without replacing it carries a pointer to it, so an agent reading one knows the other exists too. The place already named in what was decided gives most decisions their scope for free. A project whose base grows past what a single full read can hold, or a decision that holds beyond the one place where it was made, a cross-cutting convention for instance, additionally gives each decision a scope declared on its own, a module, a service, or the whole project, to stay searchable by proximity rather than by full read once it counts in the thousands of entries.

## It Replaces, It Never Stacks

The present-tense rule above holds here too, but not by reusing the same key.

```
No
outbound-http-timeout.json       { "decided": "5s timeout on every
                                    outbound HTTP call." }
outbound-http-timeout-v2.json    { "decided": "30s timeout on every
                                    outbound HTTP call." }

Yes
outbound-http-timeout.json       { "decided": "30s timeout on every
                                    outbound HTTP call.",
                                    "supersedes": "outbound-http-timeout" }
```

In the first case, the two records coexist under two different keys, and nothing says which one still holds: an agent who runs into both has to guess, and guesses wrong about as often as right. A decision that replaces an earlier one carries an explicit pointer to it rather than relying on its author having reused the exact same identifier. Reusing the same key is a human gesture that can fail with nothing to flag it; a declared pointer gets checked. The command refuses to write a decision whose subject overlaps an existing record until that pointer is there, rather than letting the two coexist in silence. A base where the same subject carries two contradicting records is worse than no base at all, because nothing says which one still holds.

## Syncing Happens in the Same Motion as the Change

Never a separate pass, never put off for later. The command runs in the same change as the one that made the decision, exactly at the moment the present-tense rule above would have asked for the block to be rewritten by hand. A decision synced afterward, in a separate commit written "while it's on my mind," has already had time to drift from what the code actually does.

## What Stands In for the Diff

A file's change gets checked by reading its diff. A synced record doesn't get that for free, so the command rereads what it just wrote and confirms it matches what it was supposed to capture, the same discipline `test.md` asks of a fix: reproduce, apply, confirm. Confirming here means rereading the four fields as recorded and checking they match word for word what the command meant to write, not just that the write raised no error. A sync nobody rereads is a claim nobody verified.

## The Code Points to the Decision

A base nothing links to the code it constrains only helps the query that already knew what to look for.

```ts
/**
 * Forwards each event to the fraud-scoring service.
 *
 * Rate-limited per item, per decision `webhook-rate-limit`.
 */
```

When a decision constrains a specific declaration, a limit applied in a function, a format a type assumes, that declaration's comment names the decision's key, exactly as `comments.md` already asks a comment to say why a constraint exists. It's this link, not the base alone, that makes an agent opening the code land on the decision without being pointed to it, the same way a comment citing an issue's identifier makes it findable from the code it changed rather than from a blind search through a folder of decisions.

## What a Project Declares

The command itself, what it's built with, and how it talks to its base are a choice of this project, never named here, the same way `rules.md` never names which command compiles or tests. This section only says what the command has to guarantee: the four fields, the replace-by-pointer rule rather than a reused key, and the reread. A project without such a command follows the hand-written rules above, in files.

## What Review Judges

Criterion 3 of `review.md` asks whether the documentation describing the code still tells the truth. Whether a project writes files by hand or syncs instead, that question finds its answer in the reread this file requires and, when syncing, in the pointer the code carries to the decision, not in a diff someone would reread.

## How It's Written

In the team's working language, while what lives in the source stays in English.

The writing rules of `comments.md` apply here too. Normal sentences with a subject and a verb, no dash used as a connector, no emoji, no brochure vocabulary, and above all the real thing rather than the abstract formula. The service that misbehaves gets named, the quota gets a number, the limit gets cited.

A table when the content is genuinely tabular, prose otherwise. A table whose cells hold full sentences is a list in disguise, and it reads worse than the list would.
