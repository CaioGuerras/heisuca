# Installs the actual build in a private CI directory, checks upgrade and
# coexistence, captures the installed player, then removes only this test install.
param(
  [string]$Installer = 'dist/heisuca-windows-installer.exe',
  [string]$Bundle = 'build/windows/x64/direct/runner/Release',
  [string]$Output = 'dist/install-evidence'
)
$ErrorActionPreference = 'Stop'
$installerPath = (Resolve-Path $Installer).Path
$bundlePath = (Resolve-Path $Bundle).Path
$destination = Join-Path $env:RUNNER_TEMP ('Heisuca teste ação ' + [Guid]::NewGuid().ToString('N'))
$oldDestination = Join-Path $env:RUNNER_TEMP ('CGFLIX coexistencia ' + [Guid]::NewGuid().ToString('N'))
$ownKey = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\{ddf45e29-4518-4c70-a963-998f215557d8}_is1'
$oldKey = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\{4213385e-f7be-4f2b-95f9-54082a28bb8f}_is1'
if ((Test-Path $ownKey) -or (Test-Path $oldKey)) { throw 'Test requires a clean runner; refuses an existing install.' }
New-Item -ItemType Directory -Path $destination, $oldDestination, $Output -Force | Out-Null
$oldSentinel = Join-Path $oldDestination 'cgflix-keep.txt'
'CGFLIX CI fixture: must remain unchanged.' | Set-Content -LiteralPath $oldSentinel
New-Item -Path $oldKey -Force | Out-Null
New-ItemProperty -Path $oldKey -Name 'DisplayName' -Value 'CGFLIX' -Force | Out-Null
New-ItemProperty -Path $oldKey -Name 'InstallLocation' -Value $oldDestination -Force | Out-Null
$sentinel = Join-Path $destination 'meus-dados-preservados.txt'
function Invoke-Installer {
  $process = Start-Process -FilePath $installerPath -ArgumentList @('/VERYSILENT', '/SUPPRESSMSGBOXES', '/NORESTART', '/NORUN=1', ('/DIR="'+$destination+'"')) -Wait -PassThru
  if ($process.ExitCode -ne 0) { throw "Installer exit code: $($process.ExitCode)" }
}
$uninstallPath = Join-Path $destination 'unins000.exe'
$evidence = [ordered]@{ installed=$false; reinstalled=$false; installedVideo=$false; uninstalled=$false; userDataPreserved=$false; cgflixPreserved=$false }
try {
  Invoke-Installer
  $installedExe = Join-Path $destination 'heisuca.exe'
  if (-not (Test-Path $installedExe)) { throw 'Installed executable missing.' }
  if ((Get-FileHash $installedExe).Hash -ne (Get-FileHash (Join-Path $bundlePath 'heisuca.exe')).Hash) {
    throw 'Installed executable differs from tested bundle.'
  }
  $entry = Get-ItemProperty $ownKey
  if ($entry.DisplayName -notlike 'Heisuca*') { throw 'Wrong uninstall identity.' }
  $evidence.installed = $true
  'Arquivo criado pelo usuário; não pertence ao manifesto do instalador.' | Set-Content -LiteralPath $sentinel -Encoding UTF8
  Invoke-Installer
  if (-not (Test-Path $sentinel)) { throw 'Reinstall lost user-created data.' }
  $evidence.reinstalled = $true
  & pwsh -NoProfile -File 'tool/desktop/capture-native-windows.ps1' -Bundle $destination -Output $Output
  if ($LASTEXITCODE -ne 0) { throw 'Installed executable failed native video proof.' }
  $evidence.installedVideo = $true
  $remove = Start-Process -FilePath $uninstallPath -ArgumentList @('/VERYSILENT', '/SUPPRESSMSGBOXES', '/NORESTART') -PassThru -Wait
  if ($remove.ExitCode -ne 0) { throw 'Uninstall failed.' }
  if ((Test-Path $installedExe) -or (Test-Path $ownKey)) { throw 'Uninstall left executable/registry entry.' }
  $evidence.uninstalled = $true
  $evidence.userDataPreserved = Test-Path $sentinel
  $evidence.cgflixPreserved = (Test-Path $oldSentinel) -and ((Get-ItemProperty $oldKey).InstallLocation -eq $oldDestination)
  if (-not $evidence.userDataPreserved -or -not $evidence.cgflixPreserved) { throw 'Uninstall damaged data or CGFLIX coexistence fixture.' }
} finally {
  $evidence | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $Output 'installation.json') -Encoding UTF8
  # These are exclusively the registry fixtures created by this test.
  if (Test-Path $oldKey) { Remove-Item $oldKey -Force }
  if (Test-Path $uninstallPath) {
    Start-Process -FilePath $uninstallPath -ArgumentList @('/VERYSILENT', '/SUPPRESSMSGBOXES', '/NORESTART') -Wait | Out-Null
  }
}
