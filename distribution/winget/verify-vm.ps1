[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$ManifestDir,

    [Parameter(Mandatory = $true)]
    [string]$OutDir
)

$ErrorActionPreference = 'Stop'

# Assegurar existência do diretório de saída
if (-not (Test-Path -LiteralPath $OutDir)) {
    New-Item -ItemType Directory -Path $OutDir -Force | Out-Null
}

$LogFile = Join-Path -Path $OutDir -ChildPath 'verify-vm.log'
Start-Transcript -Path $LogFile -Force

try {
    Write-Host "==> Iniciando verificação de manifesto WinGet"
    Write-Host "    ManifestDir: $ManifestDir"
    Write-Host "    OutDir     : $OutDir"

    if (-not (Test-Path -LiteralPath $ManifestDir)) {
        throw "Diretório de manifesto não encontrado: $ManifestDir"
    }

    # Leitura dos arquivos YAML do manifesto
    $yamlFiles = Get-ChildItem -Path $ManifestDir -Filter '*.yaml' -Recurse
    if (-not $yamlFiles -or $yamlFiles.Count -eq 0) {
        throw "Nenhum arquivo YAML encontrado em $ManifestDir"
    }

    $packageVersion = $null
    $installerUrl = $null
    $installerSha256 = $null

    foreach ($file in $yamlFiles) {
        $content = Get-Content -LiteralPath $file.FullName -Raw

        if (-not $packageVersion -and ($content -match 'PackageVersion:\s*([0-9\.]+)')) {
            $packageVersion = $matches[1].Trim()
        }
        if (-not $installerUrl -and ($content -match 'InstallerUrl:\s*(\S+)')) {
            $installerUrl = $matches[1].Trim()
        }
        if (-not $installerSha256 -and ($content -match 'InstallerSha256:\s*([A-Fa-f0-9]{64})')) {
            $installerSha256 = $matches[1].Trim()
        }
    }

    # Validações dos campos extraídos
    if (-not $packageVersion) {
        throw "Campo 'PackageVersion' não encontrado no manifesto."
    }
    if ($packageVersion -ne '2.0.45.2') {
        throw "PackageVersion incompatível. Esperado: '2.0.45.2' | Obtido: '$packageVersion'"
    }
    if (-not $installerUrl) {
        throw "Campo 'InstallerUrl' não encontrado no manifesto."
    }
    if (-not $installerSha256) {
        throw "Campo 'InstallerSha256' de 64 hexadecimais não encontrado no manifesto."
    }

    Write-Host "==> Metadados extraídos:"
    Write-Host "    PackageVersion : $packageVersion"
    Write-Host "    InstallerUrl   : $installerUrl"
    Write-Host "    InstallerSha256: $installerSha256"

    # Download do executável via HTTPS e validação de hash SHA-256
    $downloadPath = Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath "winget-installer-$([System.Guid]::NewGuid().ToString('N')).exe"
    Write-Host "==> Baixando instalador para: $downloadPath"
    Invoke-WebRequest -Uri $installerUrl -OutFile $downloadPath -UseBasicParsing

    Write-Host "==> Validando hash SHA-256 do arquivo baixado..."
    $computedHash = (Get-FileHash -Path $downloadPath -Algorithm SHA256).Hash
    if ($computedHash.ToLowerInvariant() -ne $installerSha256.ToLowerInvariant()) {
        throw "Incompatibilidade no hash SHA-256. Esperado: $installerSha256 | Calculado: $computedHash"
    }
    Write-Host "    Hash SHA-256 validado com sucesso: $computedHash"

    $ErrorActionPreference = 'Stop'
    if ($existingWinget = Get-Command winget -ErrorAction SilentlyContinue) {
        Write-Host "WinGet preexistente: $(& $existingWinget.Source --version)"
    }
    
    Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Scope CurrentUser | Out-Null
    Install-Module -Name Microsoft.WinGet.Client -Force -Scope CurrentUser -AllowClobber
    Import-Module Microsoft.WinGet.Client -Force
    Repair-WinGetPackageManager -Force -Latest
    
    $winApps = Join-Path $env:LOCALAPPDATA 'Microsoft\WindowsApps'
    if (($env:PATH -split ';') -notcontains $winApps) {
        $env:PATH = "$winApps;$env:PATH"
    }
    
    $wingetBin = (Get-Command winget -ErrorAction Stop).Source
    $wingetVersion = & $wingetBin --version
    if ($LASTEXITCODE -ne 0) {
        throw "Falha ao executar 'winget --version' (exit code: $LASTEXITCODE)."
    }
    Write-Host "WinGet atualizado para validacao: $wingetVersion"

    # 1. winget validate --manifest ManifestDir
    Write-Host "==> Executando validação de manifesto..."
    & $wingetBin validate --manifest $ManifestDir
    if ($LASTEXITCODE -ne 0) {
        throw "winget validate falhou com código de saída $LASTEXITCODE"
    }

    # 2. Habilitar LocalManifestFiles
    Write-Host "==> Configurando LocalManifestFiles..."
    & $wingetBin settings --enable LocalManifestFiles

    # 3. winget install
    Write-Host "==> Instalando pacote a partir do manifesto local..."
    & $wingetBin install --manifest $ManifestDir --silent --accept-package-agreements --accept-source-agreements --disable-interactivity
    if ($LASTEXITCODE -ne 0) {
        throw "winget install falhou com código de saída $LASTEXITCODE"
    }

    # 4. Verificar Registro HKCU
    $regPath = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\{ddf45e29-4518-4c70-a963-998f215557d8}_is1'
    Write-Host "==> Verificando chave de desinstalação: $regPath"
    if (-not (Test-Path -LiteralPath $regPath)) {
        throw "Chave de registro não localizada após instalação: $regPath"
    }

    $regValues = Get-ItemProperty -LiteralPath $regPath
    $regVersion = $regValues.DisplayVersion
    if ($regVersion -ne '2.0.45.2') {
        throw "DisplayVersion incorreto no registro. Esperado: '2.0.45.2' | Encontrado: '$regVersion'"
    }
    Write-Host "    DisplayVersion confirmado no registro: $regVersion"

    $uninstallString = $regValues.UninstallString
    if (-not $uninstallString) {
        throw "Propriedade UninstallString não encontrada no registro."
    }
    Write-Host "    UninstallString identificada: $uninstallString"

    # 5. Criar sentinela em APPDATA
    $fixtureDir = Join-Path -Path $env:APPDATA -ChildPath 'br.com.docaio\Heisuca'
    if (-not (Test-Path -LiteralPath $fixtureDir)) {
        New-Item -ItemType Directory -Path $fixtureDir -Force | Out-Null
    }
    $fixturePath = Join-Path -Path $fixtureDir -ChildPath 'winget-fixture.txt'
    Set-Content -LiteralPath $fixturePath -Value 'benign-fixture-data' -Encoding UTF8
    Write-Host "==> Sentinela criada: $fixturePath"

    # 6. Desinstalação respeitando aspas
    Write-Host "==> Preparando desinstalação silenciosa..."
    $uninstallerExecutable = $null
    if ($uninstallString -match '^\s*"([^"]+)"') {
        $uninstallerExecutable = $matches[1]
    } elseif ($uninstallString -match '^\s*(\S+)') {
        $uninstallerExecutable = $matches[1]
    } else {
        throw "Falha ao analisar UninstallString: $uninstallString"
    }

    if (-not (Test-Path -LiteralPath $uninstallerExecutable)) {
        throw "Executável de desinstalação não encontrado: $uninstallerExecutable"
    }

    $uninstallArgs = '/VERYSILENT /SUPPRESSMSGBOXES /NORESTART'
    Write-Host "    Executando: $uninstallerExecutable $uninstallArgs"
    $uninstallProcess = Start-Process -FilePath $uninstallerExecutable -ArgumentList $uninstallArgs -Wait -Passthru -NoNewWindow

    if ($uninstallProcess.ExitCode -ne 0) {
        throw "Desinstalação encerrou com código de erro: $($uninstallProcess.ExitCode)"
    }
    Write-Host "    Desinstalação concluída com exit code 0."

    # 7. Validação pós-desinstalação
    Write-Host "==> Validando integridade pós-desinstalação..."
    if (-not (Test-Path -LiteralPath $fixturePath)) {
        throw "Inconsistência: arquivo sentinela foi apagado durante a desinstalação ($fixturePath)."
    }
    Write-Host "    Sucesso: Arquivo sentinela persiste íntegro."

    if (Test-Path -LiteralPath $regPath) {
        throw "Inconsistência: chave de registro ainda permanece ativa ($regPath)."
    }
    Write-Host "    Sucesso: Registro removido adequadamente."

    # Limpeza do executável temporário
    if (Test-Path -LiteralPath $downloadPath) {
        Remove-Item -LiteralPath $downloadPath -Force -ErrorAction SilentlyContinue
    }

    # 8. Emissão de receipt.json após aprovação total
    $receiptPath = Join-Path -Path $OutDir -ChildPath 'receipt.json'
    $receiptPayload = [PSCustomObject]@{
        status            = 'success'
        packageVersion    = $packageVersion
        license           = 'GPL-3.0'
        installerSha256   = $installerSha256
        sentinelPersisted = $true
        registryCleaned   = $true
        timestampUtc      = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
    }

    $receiptPayload | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath $receiptPath -Encoding UTF8
    Write-Host "==> Verificação concluída com sucesso. Recibo emitido em: $receiptPath"

} catch {
    Write-Error "FALHA NA VERIFICAÇÃO WINGET: $_"
    throw $_
} finally {
    Stop-Transcript
}
