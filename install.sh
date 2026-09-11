#!/bin/sh
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

set -eu

REPOSITORY="${DPW_REPOSITORY:-daf-ep/workspace}"
INSTALL_DIR="${DPW_DIRECTORY:-$HOME/.local/share/dpw}"
BIN_DIR="${DPW_BIN_DIR:-$HOME/.local/bin}"

CHECKSUMS_ASSET="dpw-checksums.txt"

say() { printf '%s\n' "$*"; }
fail() { printf '%s\n' "$*" >&2; exit 1; }

have() { command -v "$1" >/dev/null 2>&1; }

case "$(uname -s)" in
  Linux) BUNDLE_ASSET="dpw-linux-x64.tar.gz" ;;
  Darwin) BUNDLE_ASSET="dpw-macos-arm64.tar.gz" ;;
  *) fail "dpw: no build for $(uname -s). Linux and macOS are published, Windows installs with install.ps1." ;;
esac

if [ "$(uname -s)" = "Darwin" ] && [ "$(uname -m)" != "arm64" ]; then
  fail "dpw: only Apple Silicon macOS is published. An Intel Mac has no build here."
fi

download() {
  asset=$1
  target=$2

  rm -f "$target"

  if have curl; then
    curl -fsSL -o "$target" "https://github.com/$REPOSITORY/releases/latest/download/$asset" \
      || fail "Could not download $asset from the latest release of $REPOSITORY"
  elif have gh; then
    gh release download --repo "$REPOSITORY" --pattern "$asset" --output "$target"
  else
    fail "Needs curl, or the GitHub CLI: https://cli.github.com"
  fi
}

sha256_of() {
  if have sha256sum; then
    sha256sum "$1" | awk '{print $1}'
  elif have shasum; then
    shasum -a 256 "$1" | awk '{print $1}'
  elif have openssl; then
    openssl dgst -sha256 "$1" | awk '{print $NF}'
  else
    fail "Needs sha256sum, shasum or openssl to verify what was downloaded"
  fi
}

verify() {
  target=$1
  name=$2

  want=$(awk -v name="$name" '$2 == name { print $1 }' "$CHECKSUMS_FILE")
  [ -n "$want" ] || fail "$name has no checksum in $CHECKSUMS_ASSET"

  got=$(sha256_of "$target")
  [ "$want" = "$got" ] || fail "$name failed its checksum: expected $want, got $got"
}

mkdir -p "$INSTALL_DIR" "$BIN_DIR"

say "Fetching dpw from the latest release of $REPOSITORY"

CHECKSUMS_FILE="$INSTALL_DIR/$CHECKSUMS_ASSET"
say "  $CHECKSUMS_ASSET"
download "$CHECKSUMS_ASSET" "$CHECKSUMS_FILE"

say "  $BUNDLE_ASSET"
archive="$INSTALL_DIR/$BUNDLE_ASSET"
download "$BUNDLE_ASSET" "$archive"
verify "$archive" "$BUNDLE_ASSET"

rm -rf "${INSTALL_DIR:?}/bin" "${INSTALL_DIR:?}/lib"
tar -xzf "$archive" -C "$INSTALL_DIR"
rm -f "$archive" "$CHECKSUMS_FILE"
chmod +x "$INSTALL_DIR/bin/dpw"

[ -f "$INSTALL_DIR/bin/rules/global/rules.md" ] || fail "$BUNDLE_ASSET carried no bin/rules/global/rules.md"

ln -sfn "$INSTALL_DIR/bin/dpw" "$BIN_DIR/dpw"

say ""
say "Ready. dpw is installed at $BIN_DIR/dpw, reading its rules from $INSTALL_DIR/bin/rules."

case ":$PATH:" in
  *":$BIN_DIR:"*) say "Run dpw init in any project." ;;
  *)
    say "$BIN_DIR is not on your PATH yet. Add it once, then run dpw init in any project:"
    say "  echo 'export PATH=\"$BIN_DIR:\$PATH\"' >> ~/.profile"
    ;;
esac
