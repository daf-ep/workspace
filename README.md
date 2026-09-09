# dafep

**The way I write software, packaged into one command. Take it if it's useful to you.**

Every team re-litigates the same arguments: what deserves a comment, when a test is worth writing, how a commit should read, what "good" even means before you hit push. This repo settles all of it, once, for good, and carries the answer with you from job to job instead of leaving it behind with the last company.

`dafep` is a single command. Run it in any project and it drops a complete set of engineering rules straight into `.claude/rules/`, ready for an AI coding agent or a human to follow from the first line.

## Install

```
git clone git@github.com:daf-ep/workspace.git
cd workspace
dart pub global activate --source path cli
```

That installs `dpw` globally. From then on, in any project:

```
cd ~/any/project
dart pub global run cli:dpw init
```

Run it again whenever you want the latest rules. Anything you've customized for that project stays exactly as you left it, and the project keeps the same id across every run.

## What's inside

Eleven gates, one per stage of writing software, from the first line of research to the moment it ships:

1. **Research.** Where an answer comes from, and what counts as proof.
2. **Debug.** Reproduce it, hypothesize before intervening, isolate by input or by history, confirm before you fix it.
3. **Code.** What makes code read like a human wrote it.
4. **Performance.** Measure before you optimize, always.
5. **Security.** Trust nothing you don't control.
6. **Comments.** What deserves one, and what doesn't.
7. **Context.** Documentation that describes the present, or a synced decision record when a project runs one instead.
8. **Test.** Running it is mandatory, writing a test is a decision.
9. **Review.** Five criteria, scored honestly, before anything gets committed.
10. **Push.** Turning a messy working tree into clean, atomic commits.
11. **CI.** What a green check actually proves, and what it doesn't.

None of it names a language, a company, or a tool. A `customization/` layer lets a single project override one detail, a commit tag list, a review threshold, without touching the rules themselves.

## Why it's public

Read it, fork it, run it. `dpw` never touches anything outside `.claude/`, so trying it costs nothing and leaves nothing behind.

Licensed under the Mozilla Public License 2.0.
