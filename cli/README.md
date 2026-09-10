`dpw`, the command-line tool for dafep.

## Commands

`init` syncs `.claude/rules` into the current directory from the `rules/`
checkout next to this package. A later run refreshes the rules but never
touches an existing file under `customization/`. It also declares `dpw`'s MCP
server in `.mcp.json`, adding or replacing only its own entry and leaving
every other server a project declared for itself alone.

`dpw` only works inside a git repository whose `origin` remote points at
GitHub or GitLab: the project's id is `host/owner/repo`, taken from that
remote rather than stored anywhere, so two clones of the same repository
share the same id.

`mcp` runs the MCP server Claude Code talks to over stdio, exposing
`record_decision`. It is not meant to be run by hand: `init` wires it into
`.mcp.json`, and Claude Code starts and stops the process itself, once per
session. Every decision is recorded in a single database shared across every
project, at `$HOME/.local/share/dpw/decisions.sqlite3` unless
`DPW_DECISIONS_DATABASE` says otherwise, tagged with the project's git-derived
id.

## Running it from source

```
dart run bin/dpw.dart init
```

## Testing it

```
dart test
```
