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

# The PowerShell half of install.sh, for a Windows that has no sh.
#
#   irm https://raw.githubusercontent.com/daf-ep/workspace/main/install.ps1 | iex

$ErrorActionPreference = 'Stop'

$Repository = if ($env:DPW_REPOSITORY) { $env:DPW_REPOSITORY } else { 'daf-ep/workspace' }
$InstallDir = if ($env:DPW_DIRECTORY) { $env:DPW_DIRECTORY } else { Join-Path $env:LOCALAPPDATA 'dpw' }

$BundleAsset = 'dpw-windows-x64.tar.gz'
$ChecksumsAsset = 'dpw-checksums.txt'

function Fail($message) {
  Write-Error $message
  exit 1
}

function Get-Asset($asset, $target) {
  if (Test-Path $target) { Remove-Item $target -Force }
  $url = "https://github.com/$Repository/releases/latest/download/$asset"
  try {
    Invoke-WebRequest -Uri $url -OutFile $target -UseBasicParsing
  } catch {
    Fail "Could not download $asset from the latest release of $Repository"
  }
}

function Test-Checksum($target, $name, $checksumsFile) {
  $want = (Select-String -Path $checksumsFile -Pattern "  $name`$" | ForEach-Object { ($_ -split '\s+')[0] })
  if (-not $want) { Fail "$name has no checksum in $ChecksumsAsset" }
  $got = (Get-FileHash -Path $target -Algorithm SHA256).Hash.ToLower()
  if ($want -ne $got) { Fail "$name failed its checksum: expected $want, got $got" }
}

New-Item -ItemType Directory -Force -Path $InstallDir | Out-Null

Write-Host "Fetching dpw from the latest release of $Repository"

$checksumsFile = Join-Path $InstallDir $ChecksumsAsset
Write-Host "  $ChecksumsAsset"
Get-Asset $ChecksumsAsset $checksumsFile

$archive = Join-Path $InstallDir $BundleAsset
Write-Host "  $BundleAsset"
Get-Asset $BundleAsset $archive
Test-Checksum $archive $BundleAsset $checksumsFile

$binDir = Join-Path $InstallDir 'bin'
$libDir = Join-Path $InstallDir 'lib'
if (Test-Path $binDir) { Remove-Item $binDir -Recurse -Force }
if (Test-Path $libDir) { Remove-Item $libDir -Recurse -Force }
tar -xzf $archive -C $InstallDir
if ($LASTEXITCODE -ne 0) { Fail "could not unpack $BundleAsset. Windows 10 1803 and later ship tar." }
Remove-Item $archive -Force
Remove-Item $checksumsFile -Force

$binaryPath = Join-Path $binDir 'dpw.exe'
$rules = Join-Path $binDir 'rules'
if (-not (Test-Path (Join-Path $rules 'rules.md'))) { Fail "$BundleAsset carried no bin/rules/rules.md" }

Write-Host ''
Write-Host "Ready. dpw is installed at $binaryPath, reading its rules from $rules."

$userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
if (";$userPath;" -notlike "*;$binDir;*") {
  [Environment]::SetEnvironmentVariable('Path', "$userPath;$binDir", 'User')
  Write-Host "Added $binDir to your user PATH. Open a new terminal, then run dpw init in any project."
} else {
  Write-Host "Run dpw init in any project."
}
