# Checks the shared generator without downloading tools or touching a real install.
$ErrorActionPreference = 'Stop'
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
}
Write-Host 'Installer contracts: CGFLIX preserved; Heisuca identity and per-user setup verified.'
