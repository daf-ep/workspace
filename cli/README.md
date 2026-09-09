`dpw`, the command-line tool for dafep.

## Commands

`init` syncs `.claude/rules` into the current directory from the `rules/`
checkout next to this package, and assigns the project a stable id in
`.claude/ID` the first time it runs. A later run refreshes the rules but
never touches an existing id or an existing file under `customization/`.

## Running it from source

```
dart run bin/dpw.dart init
```

## Testing it

```
dart test
```
