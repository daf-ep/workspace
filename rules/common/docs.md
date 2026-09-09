# Document

`comments.md` says the why leaves the source. This file says where it lands and how it's written.

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

**The change crosses two roots.** A module that touches its contract, code generated from that contract, and a shared type gets documented where the decision was made, with a pointer from the others. Not three copies that will end up diverging.

## How It's Written

In the team's working language, while what lives in the source stays in English.

The writing rules of `comments.md` apply here too. Normal sentences with a subject and a verb, no dash used as a connector, no emoji, no brochure vocabulary, and above all the real thing rather than the abstract formula. The service that misbehaves gets named, the quota gets a number, the limit gets cited.

A table when the content is genuinely tabular, prose otherwise. A table whose cells hold full sentences is a list in disguise, and it reads worse than the list would.
