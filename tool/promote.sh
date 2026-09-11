#!/usr/bin/env bash
# Copyright (C) 2026 Fiber
#
# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# What you may do:
# - Use this software for any purpose, including commercially, and build and
#   sell your own products on top of it.
# - Change it, and create new works based on it.
# - Distribute copies of it, with or without your changes.
# - Combine it with files under any other licence, proprietary ones included,
#   and licence that larger work on your own terms.
#
# What you must do in return:
# - Keep this notice on every file you received it on.
# - Publish, under these same terms, the source of every file covered by them
#   that you distribute, including the ones you changed, so that whoever
#   receives your version can obtain that source.
# - Leave Fiber out of it: the name "Fiber", its branding, its logos and its
#   trademarks may not be used to endorse or promote what you build, and this
#   licence grants no right to them.
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

PACKAGE=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$PACKAGE"

if ! command -v gh >/dev/null 2>&1; then
  echo "gh is not on your PATH. Install the GitHub CLI, then run this again." >&2
  exit 1
fi

git fetch origin dev main

ahead=$(git rev-list --count origin/main..origin/dev)
if [ "$ahead" -eq 0 ]; then
  echo "dev has nothing main does not already have, nothing to promote"
  exit 0
fi

echo "promoting $ahead commit(s) from dev to main:"
git log --oneline origin/main..origin/dev
echo ""

existing=$(gh pr list --base main --head dev --state open --json number --jq '.[0].number // empty')
if [ -n "$existing" ]; then
  echo "a promotion PR is already open: #$existing"
  pr_number="$existing"
else
  pr_url=$(gh pr create \
    --base main \
    --head dev \
    --title "Promote dev to main" \
    --body "$(git log --format='- %s' origin/main..origin/dev)")
  pr_number="${pr_url##*/}"
  echo "opened promotion PR #$pr_number"
fi

echo "waiting for checks on #$pr_number"
if gh pr checks "$pr_number" --watch --interval 10; then
  gh pr merge "$pr_number" --merge
  echo "merged #$pr_number into main"
else
  echo "" >&2
  echo "checks failed on #$pr_number, not merging" >&2
  echo "fix dev and push again, then rerun this script: the same PR gets reused" >&2
  exit 1
fi
