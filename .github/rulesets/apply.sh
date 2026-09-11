#!/usr/bin/env bash
# Copyright (C) 2026 Fiber
#
# This software is licensed under the PolyForm Noncommercial License 1.0.0. A
# copy of it is available at
# https://polyformproject.org/licenses/noncommercial/1.0.0, and in the LICENSE
# file at the root of this repository.
#
# What you may do:
# - Use, study, and modify this software for any noncommercial purpose,
#   including personal use, research, education, and use by a charitable,
#   public research, public safety, health, environmental, or government
#   institution.
# - Distribute copies of it, with or without your changes, for those same
#   noncommercial purposes.
#
# What you may not do:
# - Use this software, or a modified or combined version of it, in a
#   commercial product or service, or for any other commercial purpose.
# - Sublicense it, or transfer your licence to someone else.
#
# What you must do in return:
# - Keep this notice on every file you received it on.
#
# Disclaimer:
# AS FAR AS THE LAW ALLOWS, THIS SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY
# OR CONDITION OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO
# WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, OR
# NON-INFRINGEMENT. IN NO EVENT SHALL FIBER BE LIABLE FOR ANY DIRECT, INDIRECT,
# INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING BUT NOT
# LIMITED TO LOSS OF USE, DATA, PROFITS, OR BUSINESS INTERRUPTION) ARISING OUT
# OF OR RELATED TO THESE TERMS OR THE USE OR NATURE OF THE SOFTWARE, UNDER ANY
# KIND OF LEGAL CLAIM.
#
# This header is a summary written for convenience. Where it differs from the
# LICENSE file, the LICENSE file governs.

set -euo pipefail

REPOSITORY="${1:-}"
HERE="$(cd "$(dirname "$0")" && pwd)"

if [ -z "$REPOSITORY" ]; then
  echo "usage: $0 <owner>/<repo>" >&2
  exit 64
fi

if ! command -v gh >/dev/null 2>&1; then
  echo "This needs the GitHub CLI. See https://cli.github.com" >&2
  exit 1
fi

apply_one() {
  ruleset="$1"
  name=$(python3 -c "import json,sys; print(json.load(open(sys.argv[1]))['name'])" "$ruleset")

  if ! listing=$(gh api "repos/$REPOSITORY/rulesets" 2>&1); then
    echo "Could not list existing rulesets on $REPOSITORY:" >&2
    echo "$listing" >&2
    return 1
  fi
  existing=$(printf '%s' "$listing" | python3 -c "
import json, sys
for r in json.load(sys.stdin):
    if r['name'] == sys.argv[1]:
        print(r['id'])
        break
" "$name")

  if [ -n "$existing" ]; then
    echo "Updating \"$name\" (id $existing) on $REPOSITORY"
    gh api --method PUT "repos/$REPOSITORY/rulesets/$existing" --input "$ruleset" --jq '"  " + .name + " is now " + .enforcement'
  else
    echo "Creating \"$name\" on $REPOSITORY"
    gh api --method POST "repos/$REPOSITORY/rulesets" --input "$ruleset" --jq '"  " + .name + " is now " + .enforcement'
  fi
}

for ruleset in "$HERE"/*.json; do
  apply_one "$ruleset" || exit 1
done

cat <<EOF

Done. $REPOSITORY now rejects a direct push to main and an untagged commit
message. That applies to the owner too, past what RepositoryRole admin bypass
allows for a genuine emergency.

To check what is in place:
  gh api repos/$REPOSITORY/rulesets --jq '.[] | .name + " (" + .enforcement + ")"'
EOF
