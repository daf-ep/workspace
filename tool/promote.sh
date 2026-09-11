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
