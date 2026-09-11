# injectable

**The way I write software, packaged into one command. Take it if it's useful to you.**

Every team re-litigates the same arguments: what deserves a comment, when a test is worth writing, how a commit should read, what "good" even means before you hit push. This repo settles all of it, once, for good, and carries the answer with you from job to job instead of leaving it behind with the last company.

`injectable` is a single command. Run it in any project and it wires an MCP server into that project, ready for an AI coding agent to read the full set of engineering rules from the first line, and links the machine to an injectable account so every session can be traced back to whoever ran it.

## Install

```
curl -fsSL https://raw.githubusercontent.com/daf-ep/injectable/main/install.sh | sh
```

On Windows:

```
irm https://raw.githubusercontent.com/daf-ep/injectable/main/install.ps1 | iex
```

That installs `injectable` globally, no Dart required. From then on, in any project:

```
cd ~/any/project
injectable init
```

`injectable` also checks this repository for updates on its own, at most once a day, so you rarely need to run `init` again just to catch up. Anything you've customized for that project stays exactly as you left it, and the project keeps the same id across every run.

Working on the CLI itself, rather than just using it, needs the Dart SDK:

```
git clone git@github.com:daf-ep/injectable.git
cd injectable/cli
dart pub get
dart run bin/injectable.dart init
```

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

None of it names a language, a company, or a tool. A `.claude/injectable/` layer lets a single project override one detail, a commit tag list, a review threshold, without touching the rules themselves.

## Why it's public

Read it, run it, check there's nothing shady in it. Everything `injectable` touches in your project is `.claude/`, `.mcp.json` and `.gitignore`, never your code and never `main`, and everything it keeps for itself on the machine lives under `$HOME/.local/share/injectable/`.

Licensed under the [PolyForm Noncommercial License 1.0.0](LICENSE): free to use, study, and modify for any noncommercial purpose, never as the base of a commercial product or service. The repository isn't open to outside contributions; reach out if you want to work on it.
