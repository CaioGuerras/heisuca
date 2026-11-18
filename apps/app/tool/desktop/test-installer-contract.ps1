# Checks the shared generator without downloading tools or touching a real install.
$ErrorActionPreference = 'Stop'
$iscc = Join-Path ${env:ProgramFiles(x86)} 'Inno Setup 6/ISCC.exe'
if (-not (Test-Path -LiteralPath $iscc)) { throw 'Inno Setup compiler is required for the installer contract.' }
$icon = (Resolve-Path 'windows/runner/resources/app_icon.ico').Path
$license = (Resolve-Path '../../LICENSE').Path
$builder = (Resolve-Path 'windows/build-installer.ps1').Path
$testRoot = Join-Path $env:RUNNER_TEMP ('heisuca-contract-' + [Guid]::NewGuid().ToString('N'))
$fake = Join-Path $testRoot 'build com espaços'
New-Item -ItemType Directory -Path $fake -Force | Out-Null
foreach ($product in @('CGFLIX', 'Heisuca')) {
  $outDir = Join-Path $testRoot $product
  & pwsh -NoProfile -File $builder -Product $product -Version '2.0.45' -X64BuildDir $fake -OutputDir $outDir -EmitScriptOnly
  if ($LASTEXITCODE -ne 0) { throw "Generator failed for $product" }
  $script = Get-Content -LiteralPath (Join-Path $outDir 'setup.iss') -Raw
  $expected = if ($product -eq 'Heisuca') {
    @('#define Name "Heisuca"', '#define ExeName "heisuca.exe"',
      'ddf45e29-4518-4c70-a963-998f215557d8', 'OutputBaseFilename=heisuca-windows-installer',
      'PrivilegesRequired=lowest', 'https://heisuca.docaio.com.br', 'UninstallSubkey',
      'Heisuca.Video', 'Flags: uninsdeletevalue', 'AppMutex=br.com.docaio.heisuca.SingleInstance')
  } else {
    @('#define Name "CGFLIX"', '#define ExeName "cgflix.exe"',
      '4213385e-f7be-4f2b-95f9-54082a28bb8f', 'OutputBaseFilename=cgflix-windows-installer',
      'PrivilegesRequired=lowest', 'https://netflix.docaio.com.br/app')
  }
  foreach ($needle in $expected) {
    if (-not $script.Contains($needle)) { throw "Missing contract in ${product}: $needle" }
  }
  if ($product -eq 'Heisuca' -and ($script.Contains('CGFLIX') -or $script.Contains('4213385e-'))) {
    throw 'Heisuca must not take over CGFLIX identity.'
  }
  if ($script -match '(?im)^\[UninstallDelete\]') { throw 'Uninstaller must preserve user-created files.' }
  if ([regex]::Matches($script, '(?m)^\[Registry\]\r?$').Count -ne $(if ($product -eq 'Heisuca') { 1 } else { 0 })) {
    throw 'Registry section must appear only once and never inside Pascal comments.'
  }
  # Compile the actual generated script with tiny fixture payloads. Substring
  # checks alone cannot detect malformed sections or invalid Inno/Pascal syntax.
  $payload = Join-Path $outDir 'staging/x64/licenses'
  New-Item -ItemType Directory -Path $payload -Force | Out-Null
  Copy-Item -LiteralPath $license -Destination (Join-Path $payload 'LICENSE')
  Copy-Item -LiteralPath $icon -Destination (Join-Path $outDir 'app_icon.ico')
  Set-Content -LiteralPath (Join-Path $outDir "staging/x64/$($product.ToLowerInvariant()).exe") -Value 'installer contract fixture'
  & $iscc (Join-Path $outDir 'setup.iss')
  if ($LASTEXITCODE -ne 0) { throw "Inno compilation failed for $product" }

}
Write-Host 'Installer contracts: CGFLIX preserved; Heisuca identity and per-user setup verified.'
