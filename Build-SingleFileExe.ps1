param(
    [string]$OutputName = 'RemoveWindowsAI-GUI.exe'
)

$ErrorActionPreference = 'Stop'

$root = $PSScriptRoot
$guiSource = Join-Path $root 'RemoveWindowsAI-GUI.ps1'
$mainSource = Join-Path $root 'RemoveWindowsAi.ps1'

if (!(Test-Path $guiSource)) { throw "Missing: $guiSource" }
if (!(Test-Path $mainSource)) { throw "Missing: $mainSource" }

$mainBytes = [System.IO.File]::ReadAllBytes($mainSource)
$b64 = [Convert]::ToBase64String($mainBytes)

$guiText = [System.IO.File]::ReadAllText($guiSource, [System.Text.Encoding]::UTF8)
if (!$guiText.Contains('__EMBEDDED_MAIN_B64__')) { throw 'Placeholder __EMBEDDED_MAIN_B64__ not found in GUI source' }
$buildText = $guiText.Replace('__EMBEDDED_MAIN_B64__', $b64)

$buildDir = Join-Path $root 'build'
if (!(Test-Path $buildDir)) { New-Item $buildDir -ItemType Directory -Force | Out-Null }
$buildSource = Join-Path $buildDir 'RemoveWindowsAI-GUI-embedded.ps1'
[System.IO.File]::WriteAllText($buildSource, $buildText, (New-Object System.Text.UTF8Encoding($true)))

$tokens = $null; $errors = $null
[void][System.Management.Automation.Language.Parser]::ParseFile($buildSource, [ref]$tokens, [ref]$errors)
if ($errors.Count -gt 0) {
    throw "Embedded build source has $($errors.Count) parse errors"
}

if (!(Get-Module -ListAvailable -Name ps2exe)) {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Scope CurrentUser | Out-Null
    Set-PSRepository -Name PSGallery -InstallationPolicy Trusted -ErrorAction SilentlyContinue
    Install-Module -Name ps2exe -Scope CurrentUser -Force -AllowClobber
}
Import-Module ps2exe

$outputExe = Join-Path $root $OutputName
if (Test-Path $outputExe) { Remove-Item $outputExe -Force }

Invoke-ps2exe -inputFile $buildSource -outputFile $outputExe -noConsole -requireAdmin -title 'Remove Windows AI' -description 'Remove Windows AI - standalone bilingual GUI (EN/中文)' -product 'Remove Windows AI GUI Fork' -company 'Zombie-Kaiser' -version '1.0.0.0' | Out-Null

if (Test-Path $outputExe) {
    "OK: $outputExe ($([math]::Round((Get-Item $outputExe).Length / 1KB, 0)) KB)"
}
else {
    throw 'EXE not created'
}
