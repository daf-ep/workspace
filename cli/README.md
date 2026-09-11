`dpw`, the command-line tool for dafep.

## Commands

`login` links this machine to a dpw account through GitHub or GitLab: pick a
host, or pass `--provider github|gitlab` to skip the menu, and dpw runs that
host's OAuth Device Authorization Grant, opening the browser on its own. dpw's
backend is asked who the resulting access token belongs to exactly once, and
the session it hands back is stored at `$HOME/.local/share/dpw/credentials`
unless `DPW_CREDENTIALS_PATH` says otherwise, restricted to this account's own
read and write wherever `chmod` applies. `logout` forgets it again, and is a
no-op when there was nothing to forget.

Every other command refuses to run at all without a session stored, `dpw
login` first is how it says so, except `hook`: that one is invoked by Claude
Code itself rather than by whoever is or isn't logged in, and its own
contract is to never fail regardless of the reason.

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
way, and adds `.claude/context` to `.gitignore` for whatever local file a
future capture mechanism writes there.

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

`hook` is wired into `SessionStart`, `UserPromptSubmit` and `Stop` in
`.claude/settings.json` by `init`, and is not meant to be run by hand. It
currently does nothing beyond draining its stdin payload: the session
capture it used to write into a project-local encrypted database and push
to a `dpw-context` branch has been retired, in favor of a design where a
CLI-side account can never itself read what it captures. See "Capturing
session context" below for where that stands.

## Logging in

`dpw login` needs an OAuth client id per host, `DPW_GITHUB_CLIENT_ID` and
`DPW_GITLAB_CLIENT_ID`: public identifiers for dpw's own OAuth apps, safe to
ship inside the CLI, never a secret the way a client secret would be. A
self-managed GitLab instance is named through `DPW_GITLAB_BASE_URL`,
`https://gitlab.com` otherwise. `DPW_BACKEND_URL` says where dpw's backend
API lives, `http://localhost:8080` otherwise.

## Checking for updates

Every command checks the public corpus, `daf-ep/workspace` on GitHub, for
updates once it finishes its own work, at most once a day unless
`DPW_UPDATE_CHECK_INTERVAL_SECONDS` says otherwise. A check that finds the
corpus changed replaces the shared store wholesale, the same way `init`
does, and adds any new `project/` file to the current project's
`.claude/dpw/`, never overwriting one already there. A check that cannot
reach GitHub, or that runs before the interval has passed, is silent: dpw
tries again next time, and no command ever fails because of it.

## Capturing session context

Session capture used to work by encrypting `.claude/context`, a project-local
sqlite database, under a symmetric key shared by hand between teammates
(`DPW_CONTEXT_KEY`), then pushing it to `dpw-context`, an orphan branch on
`origin` with no history shared with any other branch. That key let anyone
holding it, including the person captured, decrypt their own capture, which
does not fit an account model where a session's owner should not need to be
trusted with the ability to read it back. `dpw hook` is retired to draining
its stdin payload until the replacement, sealing each event under a public
key only `dpw`'s backend can decrypt and syncing it there over an
authenticated connection rather than through this project's own git history,
is built.

## Running it from source

```
dart run bin/dpw.dart init
```

## Testing it

```
dart test
```
