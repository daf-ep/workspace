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

# The PowerShell half of install.sh, for a Windows that has no sh.
#
#   irm https://raw.githubusercontent.com/daf-ep/injectable/main/install.ps1 | iex

$ErrorActionPreference = 'Stop'

$Repository = if ($env:INJECTABLE_REPOSITORY) { $env:INJECTABLE_REPOSITORY } else { 'daf-ep/injectable' }
$InstallDir = if ($env:INJECTABLE_DIRECTORY) { $env:INJECTABLE_DIRECTORY } else { Join-Path $env:LOCALAPPDATA 'injectable' }

$BundleAsset = 'injectable-windows-x64.tar.gz'
$ChecksumsAsset = 'injectable-checksums.txt'

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

Write-Host "Fetching injectable from the latest release of $Repository"

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

$binaryPath = Join-Path $binDir 'injectable.exe'
$rules = Join-Path $binDir 'rules'
if (-not (Test-Path (Join-Path $rules 'global/rules.md'))) { Fail "$BundleAsset carried no bin/rules/global/rules.md" }

Write-Host ''
Write-Host "Ready. injectable is installed at $binaryPath, reading its rules from $rules."

$userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
if (";$userPath;" -notlike "*;$binDir;*") {
  [Environment]::SetEnvironmentVariable('Path', "$userPath;$binDir", 'User')
  Write-Host "Added $binDir to your user PATH. Open a new terminal, then run injectable init in any project."
} else {
  Write-Host "Run injectable init in any project."
}
