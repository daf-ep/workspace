`dpw`, the command-line tool for dafep.

## Commands

`init` syncs the corpus at the `rules/` checkout next to this package into a
single database every project on the machine shares, at
`$HOME/.local/share/dpw/rules.sqlite3` unless `DPW_RULES_DATABASE` says
otherwise. A later run replaces that database's content wholesale, so it
always matches the installed corpus exactly. `customization/` is the one part
of the corpus that is not shared: `init` ensures each of its files exists
under this project's `.claude/rules/customization/`, without ever overwriting
one the project already wrote. `init` also declares `dpw`'s MCP server in
`.mcp.json`, adding or replacing only its own entry and leaving every other
server a project declared for itself alone.

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

## Running it from source

```
dart run bin/dpw.dart init
```

## Testing it

```
dart test
```
