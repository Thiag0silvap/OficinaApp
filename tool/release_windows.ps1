<#
Release Windows (PowerShell)

Uso:
  pwsh -File tool/release_windows.ps1 -BumpKind build
  pwsh -File tool/release_windows.ps1 -BumpKind patch
  pwsh -File tool/release_windows.ps1 -BumpKind minor
  pwsh -File tool/release_windows.ps1 -BumpKind major
  pwsh -File tool/release_windows.ps1 -BumpKind none   # não altera a versão

Faz:
  1) Bump da versão (pubspec + AppVersion)
  2) Build windows release
  3) Gera um .zip do runner/Release em /dist
  4) Gera um manifest JSON em /dist e atualiza também /docs (GitHub Pages)

Pré-requisitos:
  - Flutter e Dart instalados
  - Git configurado (para detectar o repo do GitHub)
  - PowerShell 5+ (Windows PowerShell) ou PowerShell 7+ (pwsh)

Observação:
  - O asset do Release deve ser anexado manualmente no GitHub.
#>

[CmdletBinding()]
param(
  [Parameter(Mandatory = $false)]
  [ValidateSet('build', 'patch', 'minor', 'major', 'none')]
  [string]$BumpKind = 'build'
)

$ErrorActionPreference = 'Stop'

function Die([string]$Message) {
  Write-Error $Message
  exit 1
}

# Resolve root do repo: pasta acima de /tool
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootDir = Resolve-Path (Join-Path $ScriptDir '..')
Set-Location $RootDir

function Get-RepoSlug {
  try {
    $remote = (& git remote get-url origin 2>$null)
    if (-not $remote) { return $null }

    $remote = $remote.Trim()
    if ($remote.EndsWith('.git')) { $remote = $remote.Substring(0, $remote.Length - 4) }

    # https://github.com/OWNER/REPO
    if ($remote -match 'github\.com[:/]+([^/]+)/([^/]+)$') {
      return "$($Matches[1])/$($Matches[2])"
    }

    return $null
  } catch {
    return $null
  }
}

$RepoSlug = Get-RepoSlug
if (-not $RepoSlug) {
  # fallback
  $RepoSlug = 'Thiag0silvap/OficinaApp'
}

# 1) version bump
if ($BumpKind -ne 'none') {
  & dart run tool/bump_version.dart $BumpKind
  if ($LASTEXITCODE -ne 0) { Die "Falha ao bump de versão (tool/bump_version.dart)." }
}

# 2) build
& flutter build windows --release
if ($LASTEXITCODE -ne 0) { Die 'Falha no flutter build windows --release.' }

# 3) zip
$pubspecPath = Join-Path $RootDir 'pubspec.yaml'
if (-not (Test-Path $pubspecPath)) { Die 'pubspec.yaml não encontrado na raiz do projeto.' }

$versionLine = (Get-Content $pubspecPath | Where-Object { $_ -match '^version:\s*' } | Select-Object -First 1)
if (-not $versionLine) { Die 'Linha version: não encontrada no pubspec.yaml.' }

$version = ($versionLine -split ':', 2)[1].Trim()
$safeVersion = $version.Replace('+', '_')
$zipName = "oficinaapp_windows_${safeVersion}.zip"
$tagName = "v${safeVersion}"

$distDir = Join-Path $RootDir 'dist'
New-Item -ItemType Directory -Force -Path $distDir | Out-Null

$releaseDir = Join-Path $RootDir 'build\windows\x64\runner\Release'
if (-not (Test-Path $releaseDir)) {
  # Em algumas versões pode ser build\windows\runner\Release
  $altReleaseDir = Join-Path $RootDir 'build\windows\runner\Release'
  if (Test-Path $altReleaseDir) {
    $releaseDir = $altReleaseDir
  } else {
    Die "Pasta de Release não encontrada. Esperado: $releaseDir"
  }
}

$zipPath = Join-Path $distDir $zipName
if (Test-Path $zipPath) { Remove-Item -Force $zipPath }

# Compacta o CONTEÚDO da pasta Release (não a pasta em si)
$itemsToZip = Join-Path $releaseDir '*'
Compress-Archive -Path $itemsToZip -DestinationPath $zipPath -Force

# 4) manifest
$downloadUrl = "https://github.com/$RepoSlug/releases/download/$tagName/$zipName"

$manifest = [ordered]@{
  latestVersion = $version
  downloadUrl   = $downloadUrl
  notes         = "- Descreva aqui as mudanças desta versão"
}

$manifestPath = Join-Path $distDir 'update_manifest.json'
$manifestJson = ($manifest | ConvertTo-Json -Depth 10)
Set-Content -Path $manifestPath -Value $manifestJson -Encoding UTF8

$docsDir = Join-Path $RootDir 'docs'
New-Item -ItemType Directory -Force -Path $docsDir | Out-Null
$docsManifestPath = Join-Path $docsDir 'update_manifest.json'
Copy-Item -Force $manifestPath $docsManifestPath

Write-Host 'OK'
Write-Host "- Zip: $zipPath"
Write-Host "- Manifest: $manifestPath"
Write-Host "- Manifest (Pages): $docsManifestPath"
Write-Host ''
Write-Host 'Próximo passo no GitHub:'
Write-Host "1) Crie um Release com a tag: $tagName"
Write-Host "2) Anexe o arquivo: $zipName"
Write-Host '3) Commit + push do docs/update_manifest.json (o script já atualizou)'
