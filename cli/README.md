`dpw`, the command-line tool for dafep.

## Commands

`init` syncs `global/`, at the `rules/` checkout next to this package, into a
single store every project on the machine shares, at
`$HOME/.local/share/dpw/rules/` unless `DPW_RULES_DIR` says otherwise. A
later run replaces that store's content wholesale, so it always matches the
installed corpus exactly. `project/` is the one part of the corpus that is
not shared: `init` ensures each of its files exists under this project's
`.claude/dpw/`, without ever overwriting one the project already wrote.
`init` also declares `dpw`'s MCP server in `.mcp.json`, adding or replacing
only its own entry and leaving every other server a project declared for
itself alone. It declares `dpw`'s hooks in `.claude/settings.json` the same
way, adds `.claude/context` to `.gitignore`, and prepares the project's
`dpw-context` branch, an orphan with no history shared with any other
branch, the way `gh-pages` is for built docs.

`dpw` only works inside a git repository whose `origin` remote points at
GitHub or GitLab: the project's id is `host/owner/repo`, taken from that
remote rather than stored anywhere, so two clones of the same repository
share the same id.

`mcp` runs the MCP server Claude Code talks to over stdio, exposing
`get_rule` and `list_rules` to read the shared corpus and `record_decision`
to capture a decision. It is not meant to be run by hand: `init` wires it
into `.mcp.json`, and Claude Code starts and stops the process itself, once
per session. Every decision is recorded in a single database shared across
every project, at `$HOME/.local/share/dpw/decisions.sqlite3` unless
`DPW_DECISIONS_DATABASE` says otherwise, tagged with the project's git-derived
id.

`hook` records one Claude Code hook event's raw stdin payload into this
project's own context database, `.claude/context`, and pushes that database
to `dpw-context` when a push is due. It is not meant to be run by hand
either: `init` wires it into `SessionStart`, `UserPromptSubmit` and `Stop`
in `.claude/settings.json`. Every payload lands verbatim in a `raw_events`
table, unparsed: what a session said and what Claude answered is captured
now, and read later, by a processing pass this does not do yet.

## Checking for updates

Every command checks the public corpus, `daf-ep/workspace` on GitHub, for
updates once it finishes its own work, at most once a day unless
`DPW_UPDATE_CHECK_INTERVAL_SECONDS` says otherwise. A check that finds the
corpus changed replaces the shared store wholesale, the same way `init`
does, and adds any new `project/` file to the current project's
`.claude/dpw/`, never overwriting one already there. A check that cannot
reach GitHub, or that runs before the interval has passed, is silent: dpw
tries again next time, and no command ever fails because of it.

## Pushing captured context

A `hook` call that finds a push due commits `.claude/context` onto
`dpw-context` and pushes it to `origin`, at most once every five minutes
unless `DPW_CONTEXT_PUSH_INTERVAL_SECONDS` says otherwise. The commit is
built by plumbing, `hash-object`, `mktree`, `commit-tree`, parented on
whatever `dpw-context` currently points to on `origin`, so this project's own
working tree and index are never touched: no branch switch, no checkout, the
way a bot deploys to `gh-pages` without ever checking it out. A push that
cannot reach `origin`, or that loses a race against a teammate's push, is
silent, the same way the rules corpus's own update check is: the next `hook`
call tries again.

## Running it from source

```
dart run bin/dpw.dart init
```

## Testing it

```
dart test
```
