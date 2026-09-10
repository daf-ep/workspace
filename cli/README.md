`dpw`, the command-line tool for dafep.

## Commands

`init` syncs `global/`, at the `rules/` checkout next to this package, into a
single database every project on the machine shares, at
`$HOME/.local/share/dpw/rules.sqlite3` unless `DPW_RULES_DATABASE` says
otherwise. A later run replaces that database's content wholesale, so it
always matches the installed corpus exactly. `project/` is the one part of
the corpus that is not shared: `init` ensures each of its files exists under
this project's `.claude/dpw/`, without ever overwriting one the project
already wrote. `init` also declares `dpw`'s MCP server in `.mcp.json`, adding
or replacing only its own entry and leaving every other server a project
declared for itself alone.

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

## Checking for updates

Every command checks the public corpus, `daf-ep/workspace` on GitHub, for
updates once it finishes its own work, at most once a day unless
`DPW_UPDATE_CHECK_INTERVAL_SECONDS` says otherwise. A check that finds the
corpus changed replaces the shared database wholesale, the same way `init`
does, and adds any new `project/` file to the current project's
`.claude/dpw/`, never overwriting one already there. A check that cannot
reach GitHub, or that runs before the interval has passed, is silent: dpw
tries again next time, and no command ever fails because of it.

## Running it from source

```
dart run bin/dpw.dart init
```

## Testing it

```
dart test
```
