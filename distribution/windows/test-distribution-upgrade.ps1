[CmdletBinding()]
param(
  [Parameter(Mandatory = $false)]
  [string]$ReleaseJsonPath = "distribution/windows/release.json",

  [Parameter(Mandatory = $false)]
  [string]$SourceUnpackedDir = "inputs/unpacked",

  [Parameter(Mandatory = $false)]
  [string]$PreviousInstallerPath = "inputs/previous/heisuca-windows-installer.exe",

  [Parameter(Mandatory = $false)]
  [string]$DistOutputDir = "dist-output",

  [Parameter(Mandatory = $false)]
  [string]$NewInstallerPath = "",

  [Parameter(Mandatory = $false)]
  [string]$NewPortableZipPath = "",

  [Parameter(Mandatory = $false)]
  [string]$InstallDir = "",

  [Parameter(Mandatory = $false)]
  [string]$ReportOutputPath = "dist-output/windows-distribution-verification.json",

  [Parameter(Mandatory = $false)]
  [string]$LogOutputPath = "dist-output/windows-distribution-verification.log"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$script:LogLines = [System.Collections.Generic.List[string]]::new()

function Write-StepLog {
  param([Parameter(Mandatory = $true)][string]$Message)
  $timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
  $line = "[$timestamp] $Message"
  $script:LogLines.Add($line)
  Write-Host $line
}

function Resolve-ExistingPath {
  param(
    [Parameter(Mandatory = $true)][string]$PathToResolve,
    [Parameter(Mandatory = $true)][string]$Label
  )
  if (-not (Test-Path -LiteralPath $PathToResolve)) {
    throw "$Label nao encontrado: $PathToResolve"
  }
  return (Resolve-Path -LiteralPath $PathToResolve).ProviderPath
}

function Get-RelativePeHashMap {
  param(
    [Parameter(Mandatory = $true)][string]$BaseDir,
    [Parameter(Mandatory = $false)][switch]$ExcludeGeneratedUninstaller
  )

  $resolvedBaseDir = Resolve-ExistingPath -PathToResolve $BaseDir -Label "BaseDir para mapa PE"
  $files = @(Get-ChildItem -LiteralPath $resolvedBaseDir -Recurse -File)
  $map = [ordered]@{}

  $peItems = foreach ($file in $files) {
    $resolvedFile = (Resolve-Path -LiteralPath $file.FullName).ProviderPath
    $relPath = [System.IO.Path]::GetRelativePath($resolvedBaseDir, $resolvedFile).Replace('\', '/')
    $ext = $file.Extension.ToLowerInvariant()

    if ($ext -notin @('.exe', '.dll')) {
      continue
    }

    if ($ExcludeGeneratedUninstaller -and ($relPath -match '^unins\d{3}\.exe$')) {
      continue
    }

    [PSCustomObject]@{
      RelativePath = $relPath
      FullPath     = $resolvedFile
    }
  }

  foreach ($item in ($peItems | Sort-Object RelativePath)) {
    $hash = (Get-FileHash -LiteralPath $item.FullPath -Algorithm SHA256).Hash.ToLowerInvariant()
    $map[$item.RelativePath] = $hash
  }

  if ($map.Count -eq 0) {
    throw "Mapa relativo PE vazio em: $resolvedBaseDir"
  }

  if (-not $map.Contains('heisuca.exe')) {
    throw "Executavel principal 'heisuca.exe' ausente na raiz do mapa PE de: $resolvedBaseDir"
  }

  return $map
}

function Assert-PeHashMapsEqual {
  param(
    [Parameter(Mandatory = $true)][System.Collections.IDictionary]$ReferenceMap,
    [Parameter(Mandatory = $true)][System.Collections.IDictionary]$TargetMap,
    [Parameter(Mandatory = $true)][string]$ReferenceLabel,
    [Parameter(Mandatory = $true)][string]$TargetLabel
  )

  if ($ReferenceMap.Count -eq 0) {
    throw "Mapa PE de referencia ($ReferenceLabel) esta vazio."
  }
  if ($TargetMap.Count -eq 0) {
    throw "Mapa PE alvo ($TargetLabel) esta vazio."
  }

  $refKeys = @($ReferenceMap.Keys | Sort-Object)
  $targetKeys = @($TargetMap.Keys | Sort-Object)

  $missingInTarget = @($refKeys | Where-Object { -not $TargetMap.Contains($_) })
  $extraInTarget = @($targetKeys | Where-Object { -not $ReferenceMap.Contains($_) })

  if ($missingInTarget.Count -gt 0 -or $extraInTarget.Count -gt 0) {
    $missingStr = if ($missingInTarget.Count -gt 0) { $missingInTarget -join ', ' } else { '<nenhum>' }
    $extraStr = if ($extraInTarget.Count -gt 0) { $extraInTarget -join ', ' } else { '<nenhum>' }
    throw "Divergencia de caminhos PE entre $ReferenceLabel e $TargetLabel. Ausentes em ${TargetLabel}: [$missingStr]. Extras em ${TargetLabel}: [$extraStr]."
  }

  $mismatchedHashes = [System.Collections.Generic.List[string]]::new()
  foreach ($key in $refKeys) {
    $refHash = [string]$ReferenceMap[$key]
    $targetHash = [string]$TargetMap[$key]
    if ($refHash -ne $targetHash) {
      $mismatchedHashes.Add("${key} ($ReferenceLabel=$refHash vs $TargetLabel=$targetHash)")
    }
  }

  if ($mismatchedHashes.Count -gt 0) {
    throw "Divergencia de SHA-256 PE entre $ReferenceLabel e $TargetLabel: $($mismatchedHashes -join '; ')"
  }

  Write-StepLog "Paridade PE confirmada entre $ReferenceLabel e $TargetLabel ($($refKeys.Count) arquivos PE)."
}

function Assert-UninstallDisplayVersion {
  param(
    [Parameter(Mandatory = $true)][string]$RegistryPath,
    [Parameter(Mandatory = $true)][string]$ExpectedVersion,
    [Parameter(Mandatory = $true)][string]$StageLabel
  )

  if (-not (Test-Path -LiteralPath $RegistryPath)) {
    throw "[$StageLabel] Chave de desinstalacao ausente no Registro: $RegistryPath"
  }

  $props = Get-ItemProperty -LiteralPath $RegistryPath
  if ($null -eq $props -or -not ($props.PSObject.Properties.Name -contains 'DisplayVersion')) {
    throw "[$StageLabel] Propriedade DisplayVersion ausente em: $RegistryPath"
  }

  $actualVersion = [string]$props.DisplayVersion
  if ($actualVersion -ne $ExpectedVersion) {
    throw "[$StageLabel] DisplayVersion incorreta em $RegistryPath. Esperado: '$ExpectedVersion', Obtido: '$actualVersion'."
  }

  Write-StepLog "[$StageLabel] Registro validado: $RegistryPath -> DisplayVersion=$actualVersion"
  return $actualVersion
}

Write-StepLog "Iniciando verificacao de upgrade e paridade da distribuicao Windows."

$absReleaseJsonPath = Resolve-ExistingPath -PathToResolve $ReleaseJsonPath -Label "release.json"
$releaseData = Get-Content -LiteralPath $absReleaseJsonPath -Raw -Encoding UTF8 | ConvertFrom-Json

$appGuid = [string]$releaseData.appGuid
$expectedOldVersion = [string]$releaseData.nativeVersion
$expectedNewVersion = [string]$releaseData.distributionVersion
$expectedPrevSha256 = ([string]$releaseData.previousInstaller.sha256).ToLowerInvariant()

if ($appGuid -ne "ddf45e29-4518-4c70-a963-998f215557d8") {
  throw "appGuid inesperado em release.json: $appGuid"
}
if ($expectedOldVersion -ne "2.0.45") {
  throw "nativeVersion inesperada em release.json: $expectedOldVersion"
}
if ($expectedNewVersion -ne "2.0.45.2") {
  throw "distributionVersion inesperada em release.json: $expectedNewVersion"
}

$absSourceDir = Resolve-ExistingPath -PathToResolve $SourceUnpackedDir -Label "Diretorio fonte desempacotado"
$absPrevInstaller = Resolve-ExistingPath -PathToResolve $PreviousInstallerPath -Label "Instalador anterior"
$absDistOutputDir = Resolve-ExistingPath -PathToResolve $DistOutputDir -Label "Diretorio dist-output"

$actualPrevSha256 = (Get-FileHash -LiteralPath $absPrevInstaller -Algorithm SHA256).Hash.ToLowerInvariant()
if ($actualPrevSha256 -ne $expectedPrevSha256) {
  throw "SHA-256 do instalador anterior diverge de release.json. Esperado: $expectedPrevSha256, Obtido: $actualPrevSha256"
}
Write-StepLog "SHA-256 do instalador anterior validado: $actualPrevSha256"

if ([string]::IsNullOrWhiteSpace($NewInstallerPath)) {
  $exeCandidates = @(Get-ChildItem -LiteralPath $absDistOutputDir -Filter "*.exe" -File | Where-Object { $_.Name -notmatch '^unins\d{3}\.exe$' })
  if ($exeCandidates.Count -ne 1) {
    throw "Esperado exatamente 1 instalador .exe em $absDistOutputDir, encontrados: $($exeCandidates.Count)"
  }
  $NewInstallerPath = $exeCandidates[0].FullName
}
$absNewInstaller = Resolve-ExistingPath -PathToResolve $NewInstallerPath -Label "Novo instalador"

if ([string]::IsNullOrWhiteSpace($NewPortableZipPath)) {
  $zipCandidates = @(Get-ChildItem -LiteralPath $absDistOutputDir -Filter "*.zip" -File)
  if ($zipCandidates.Count -ne 1) {
    throw "Esperado exatamente 1 pacote portatil .zip em $absDistOutputDir, encontrados: $($zipCandidates.Count)"
  }
  $NewPortableZipPath = $zipCandidates[0].FullName
}
$absNewPortableZip = Resolve-ExistingPath -PathToResolve $NewPortableZipPath -Label "Novo ZIP portatil"

$runnerTempRoot = if (-not [string]::IsNullOrWhiteSpace($env:RUNNER_TEMP)) {
  $env:RUNNER_TEMP
} else {
  [System.IO.Path]::GetTempPath()
}
$absRunnerTempRoot = (Resolve-Path -LiteralPath $runnerTempRoot).ProviderPath

if ([string]::IsNullOrWhiteSpace($InstallDir)) {
  $InstallDir = Join-Path $absRunnerTempRoot "HeisucaDistribution"
}
$absInstallDir = [System.IO.Path]::GetFullPath($InstallDir)

$uninstallRegPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\{ddf45e29-4518-4c70-a963-998f215557d8}_is1"

if ([string]::IsNullOrWhiteSpace($env:APPDATA)) {
  throw "Variavel de ambiente APPDATA nao definida."
}
$absAppData = (Resolve-Path -LiteralPath $env:APPDATA).ProviderPath
$sentinelDir = Join-Path $absAppData "br.com.docaio\Heisuca"
$sentinelPath = Join-Path $sentinelDir "test-distribution-sentinel.txt"

$portableExtractDir = Join-Path $absRunnerTempRoot ("HeisucaPortableVerify-" + [System.Guid]::NewGuid().ToString("N"))

try {
  # Limpeza preventiva caso exista residuo no ambiente
  if (Test-Path -LiteralPath $absInstallDir) {
    Remove-Item -LiteralPath $absInstallDir -Recurse -Force
  }
  if (Test-Path -LiteralPath $uninstallRegPath) {
    Remove-Item -LiteralPath $uninstallRegPath -Recurse -Force
  }
  if (Test-Path -LiteralPath $sentinelPath) {
    Remove-Item -LiteralPath $sentinelPath -Force
  }

  # 1. Instalar versao anterior (2.0.45)
  $installArgs = @(
    "/DIR=$absInstallDir",
    "/NORUN=1",
    "/VERYSILENT"
  )
  Write-StepLog "Executando instalador anterior: $absPrevInstaller $($installArgs -join ' ')"
  $prevProc = Start-Process -FilePath $absPrevInstaller -ArgumentList $installArgs -Wait -PassThru -NoNewWindow
  if ($null -eq $prevProc -or $prevProc.ExitCode -ne 0) {
    $code = if ($null -ne $prevProc) { $prevProc.ExitCode } else { 'null' }
    throw "Instalacao da versao anterior falhou com ExitCode: $code"
  }
  Write-StepLog "Instalador anterior concluido com ExitCode 0."

  # 2. Verificar DisplayVersion=2.0.45 no Registro apos instalacao antiga
  $displayVersionAfterOld = Assert-UninstallDisplayVersion `
    -RegistryPath $uninstallRegPath `
    -ExpectedVersion "2.0.45" `
    -StageLabel "Pos-instalacao antiga"

  # 3. Criar sentinela em %APPDATA%\br.com.docaio\Heisuca\test-distribution-sentinel.txt
  New-Item -ItemType Directory -Path $sentinelDir -Force | Out-Null
  $sentinelExpectedContent = "heisuca-sentinel-upgrade-check-2.0.45-to-2.0.45.2"
  [System.IO.File]::WriteAllText($sentinelPath, $sentinelExpectedContent, [System.Text.UTF8Encoding]::new($false))
  if (-not (Test-Path -LiteralPath $sentinelPath -PathType Leaf)) {
    throw "Falha ao criar arquivo sentinela em: $sentinelPath"
  }
  Write-StepLog "Sentinela criada em: $sentinelPath"

  # 4. Instalar nova versao (2.0.45.2) por cima no mesmo diretorio
  Write-StepLog "Executando novo instalador (upgrade): $absNewInstaller $($installArgs -join ' ')"
  $newProc = Start-Process -FilePath $absNewInstaller -ArgumentList $installArgs -Wait -PassThru -NoNewWindow
  if ($null -eq $newProc -or $newProc.ExitCode -ne 0) {
    $code = if ($null -ne $newProc) { $newProc.ExitCode } else { 'null' }
    throw "Instalacao da nova versao (2.0.45.2) falhou com ExitCode: $code"
  }
  Write-StepLog "Novo instalador concluido com ExitCode 0."

  # 5. Verificar DisplayVersion=2.0.45.2 no Registro apos instalacao nova
  $displayVersionAfterNew = Assert-UninstallDisplayVersion `
    -RegistryPath $uninstallRegPath `
    -ExpectedVersion "2.0.45.2" `
    -StageLabel "Pos-upgrade 2.0.45.2"

  # Verificar que a sentinela persistiu apos o upgrade
  if (-not (Test-Path -LiteralPath $sentinelPath -PathType Leaf)) {
    throw "Sentinela desapareceu apos upgrade para 2.0.45.2: $sentinelPath"
  }
  $sentinelContentAfterUpgrade = [System.IO.File]::ReadAllText($sentinelPath, [System.Text.Encoding]::UTF8)
  if ($sentinelContentAfterUpgrade -ne $sentinelExpectedContent) {
    throw "Conteudo da sentinela foi alterado apos upgrade."
  }
  Write-StepLog "Sentinela intacta apos upgrade para 2.0.45.2."

  # 6. Extrair ZIP portatil e comparar mapas relativos PE (Fonte vs ZIP vs Instalado)
  New-Item -ItemType Directory -Path $portableExtractDir -Force | Out-Null
  Expand-Archive -LiteralPath $absNewPortableZip -DestinationPath $portableExtractDir -Force

  $sourcePeMap = Get-RelativePeHashMap -BaseDir $absSourceDir
  $zipPeMap = Get-RelativePeHashMap -BaseDir $portableExtractDir
  $installedPeMap = Get-RelativePeHashMap -BaseDir $absInstallDir -ExcludeGeneratedUninstaller

  Assert-PeHashMapsEqual `
    -ReferenceMap $sourcePeMap `
    -TargetMap $zipPeMap `
    -ReferenceLabel "Fonte(inputs/unpacked)" `
    -TargetLabel "PortableZIP"

  Assert-PeHashMapsEqual `
    -ReferenceMap $sourcePeMap `
    -TargetMap $installedPeMap `
    -ReferenceLabel "Fonte(inputs/unpacked)" `
    -TargetLabel "Instalado(HeisucaDistribution)"

  # Verificar que o desinstalador unins000.exe existe na pasta instalada
  $uninstallerCandidate = Join-Path $absInstallDir "unins000.exe"
  $absUninstaller = Resolve-ExistingPath -PathToResolve $uninstallerCandidate -Label "Desinstalador unins000.exe"

  # 7. Desinstalar via unins000.exe esperando conclusao com ExitCode
  $uninstallArgs = @(
    "/VERYSILENT",
    "/SUPPRESSMSGBOXES",
    "/NORESTART"
  )
  Write-StepLog "Executando desinstalador: $absUninstaller $($uninstallArgs -join ' ')"
  $uninsProc = Start-Process -FilePath $absUninstaller -ArgumentList $uninstallArgs -Wait -PassThru -NoNewWindow
  if ($null -eq $uninsProc -or $uninsProc.ExitCode -ne 0) {
    $code = if ($null -ne $uninsProc) { $uninsProc.ExitCode } else { 'null' }
    throw "Desinstalacao via unins000.exe falhou com ExitCode: $code"
  }

  # Inno Setup pode finalizar remocao em processo auxiliar por alguns instantes apos o exit code 0
  $maxWaitSeconds = 30
  $elapsed = 0
  $installedExePath = Join-Path $absInstallDir "heisuca.exe"
  while (((Test-Path -LiteralPath $uninstallRegPath) -or (Test-Path -LiteralPath $installedExePath)) -and ($elapsed -lt $maxWaitSeconds)) {
    Start-Sleep -Milliseconds 500
    $elapsed += 0.5
  }

  if (Test-Path -LiteralPath $uninstallRegPath) {
    throw "Chave de registro permaneceu presente apos desinstalacao: $uninstallRegPath"
  }
  if (Test-Path -LiteralPath $installedExePath) {
    throw "Executavel instalado permaneceu presente apos desinstalacao: $installedExePath"
  }
  Write-StepLog "Desinstalacao concluida com ExitCode 0 e remocao confirmada."

  # 8. Verificar que a sentinela em APPDATA persiste apos desinstalacao
  if (-not (Test-Path -LiteralPath $sentinelPath -PathType Leaf)) {
    throw "Sentinela em APPDATA foi removida pela desinstalacao: $sentinelPath"
  }
  $sentinelContentAfterUninstall = [System.IO.File]::ReadAllText($sentinelPath, [System.Text.Encoding]::UTF8)
  if ($sentinelContentAfterUninstall -ne $sentinelExpectedContent) {
    throw "Conteudo da sentinela em APPDATA foi corrompido apos desinstalacao."
  }
  Write-StepLog "Sentinela em APPDATA persistiu intacta apos desinstalacao: $sentinelPath"

  # 9. Emitir relatorio JSON e log de verificacao (sem afirmar assinatura Windows)
  $reportObj = [ordered]@{
    distributionVersion             = $expectedNewVersion
    nativeVersion                   = $expectedOldVersion
    versionCode                     = [int]$releaseData.versionCode
    appGuid                         = $appGuid
    scope                           = [string]$releaseData.scope
    registryKey                     = $uninstallRegPath
    installDir                      = $absInstallDir
    displayVersionAfterOldInstall   = $displayVersionAfterOld
    displayVersionAfterUpgrade      = $displayVersionAfterNew
    peFileCount                     = $sourcePeMap.Count
    sourceVsZipPeParity             = $true
    sourceVsInstalledPeParity       = $true
    uninstallerExecuted             = $absUninstaller
    uninstallExitCode               = $uninsProc.ExitCode
    sentinelPath                    = $sentinelPath
    sentinelPersistedAfterUpgrade   = $true
    sentinelPersistedAfterUninstall = $true
    signing                         = [ordered]@{
      signed = $false
      status = "unsigned"
    }
  }

  $utf8NoBom = [System.Text.UTF8Encoding]::new($false)

  if (-not [string]::IsNullOrWhiteSpace($ReportOutputPath)) {
    $reportParent = Split-Path -Parent $ReportOutputPath
    if (-not [string]::IsNullOrWhiteSpace($reportParent) -and -not (Test-Path -LiteralPath $reportParent)) {
      New-Item -ItemType Directory -Path $reportParent -Force | Out-Null
    }
    $reportJson = ($reportObj | ConvertTo-Json -Depth 6) -replace "`r`n", "`n"
    [System.IO.File]::WriteAllText($ReportOutputPath, $reportJson + "`n", $utf8NoBom)
    Write-StepLog "Relatorio JSON gravado em: $ReportOutputPath"
  }

  if (-not [string]::IsNullOrWhiteSpace($LogOutputPath)) {
    $logParent = Split-Path -Parent $LogOutputPath
    if (-not [string]::IsNullOrWhiteSpace($logParent) -and -not (Test-Path -LiteralPath $logParent)) {
      New-Item -ItemType Directory -Path $logParent -Force | Out-Null
    }
    $logText = ($script:LogLines -join "`n") + "`n"
    [System.IO.File]::WriteAllText($LogOutputPath, $logText, $utf8NoBom)
  }
}
finally {
  if (Test-Path -LiteralPath $portableExtractDir) {
    Remove-Item -LiteralPath $portableExtractDir -Recurse -Force -ErrorAction SilentlyContinue
  }
  if (Test-Path -LiteralPath $absInstallDir) {
    Remove-Item -LiteralPath $absInstallDir -Recurse -Force -ErrorAction SilentlyContinue
  }
}
