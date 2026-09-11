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

BASE="${1:-}"
HEAD="${2:-HEAD}"

TAGS="DEV|BUGFIX|REFACTO|DOC|TEST|CI|PERF|SECURITY|BREAKING|REVERT|CHORE"
PATTERN="^\[(${TAGS})\]: .+$"
SUBJECT_LIMIT=72

if [ -z "$BASE" ] || [ "$BASE" = "0000000000000000000000000000000000000000" ] || ! git cat-file -e "$BASE^{commit}" 2>/dev/null; then
  echo "No base revision to compare against, checking $HEAD on its own"
  COMMITS=$(git rev-list -1 "$HEAD")
else
  COMMITS=$(git rev-list "$BASE..$HEAD")
fi

failed=0
checked=0

for commit in $COMMITS; do
  parents=$(git rev-list --parents -n 1 "$commit" | wc -w)
  if [ "$parents" -gt 2 ]; then
    continue
  fi

  subject=$(git log -1 --format=%s "$commit")
  checked=$((checked + 1))

  if [ ${#subject} -gt $SUBJECT_LIMIT ]; then
    echo "BAD  ${commit:0:8}  subject is ${#subject} characters, limit is $SUBJECT_LIMIT"
    echo "                   $subject"
    failed=$((failed + 1))
    continue
  fi

  if ! printf '%s' "$subject" | grep -Eq "$PATTERN"; then
    echo "BAD  ${commit:0:8}  $subject"
    failed=$((failed + 1))
    continue
  fi

  if printf '%s' "$subject" | grep -Eq '\.$'; then
    echo "BAD  ${commit:0:8}  subject ends with a period"
    echo "                   $subject"
    failed=$((failed + 1))
    continue
  fi

  echo "ok   ${commit:0:8}  $subject"
done

if [ "$failed" -gt 0 ]; then
  cat >&2 <<EOF

$failed of $checked commit messages have the wrong format.

Use [TAG]: message

  DEV        new feature, new endpoint, new code
  BUGFIX     a fix for something that was broken
  REFACTO    moving or rewriting code without changing behaviour
  DOC        documentation only
  TEST       tests only
  CI         workflows and build tooling
  PERF       speed or footprint
  SECURITY   hardening, closing a leak
  BREAKING   breaks the contract or a published API
  REVERT     undoing an earlier commit
  CHORE      dependencies and other housekeeping

Tags are uppercase and in brackets. Keep the message in the imperative, drop
the trailing period, and stay under $SUBJECT_LIMIT characters.

For example:

  [DEV]: add the init command
  [BUGFIX]: keep the project id a rerun does not touch
  [REFACTO]: move the sync logic out of the command
EOF
  exit 1
fi

echo ""
echo "Checked $checked commit messages, all good"
