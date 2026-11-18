# Native desktop proof: capture the composed Windows window, not Flutter's
# layer-only screenshot. Uses original synthetic video, with no audio device.
param([string]$Bundle = 'build/windows/x64/direct/runner/Release', [string]$Output = 'dist/native-evidence', [switch]$VerifySecondInstance, [switch]$HomeOnly, [ValidateSet('shikkoku','hisui','sumi')][string]$Theme = 'shikkoku')
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
Add-Type @'
using System;
using System.Runtime.InteropServices;
public static class HeisucaWindowCapture {
  [StructLayout(LayoutKind.Sequential)] public struct RECT { public int Left, Top, Right, Bottom; }
  [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h, out RECT r);
  [DllImport("user32.dll")] public static extern bool SetWindowPos(IntPtr h, IntPtr after, int x, int y, int w, int hgt, uint flags);
  [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
  [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr h, int state);
}
'@
$exe = (Resolve-Path (Join-Path $Bundle 'heisuca.exe')).Path
$fixture = (Resolve-Path 'test/desktop/fixtures/video-sem-audio.mkv').Path
New-Item -ItemType Directory -Force -Path $Output | Out-Null
function Capture-Window([IntPtr]$Handle) {
  $rect = New-Object HeisucaWindowCapture+RECT
  if (-not [HeisucaWindowCapture]::GetWindowRect($Handle, [ref]$rect)) { throw 'Janela nativa indisponivel.' }
  $bitmap = New-Object System.Drawing.Bitmap ($rect.Right-$rect.Left), ($rect.Bottom-$rect.Top)
  $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
  try { $graphics.CopyFromScreen($rect.Left,$rect.Top,0,0,$bitmap.Size) }
  finally { $graphics.Dispose() }
  return $bitmap
}
function Count-VideoColors($Bitmap) {
  $count=0
  for ($y=[int]($Bitmap.Height*0.25);$y -lt $Bitmap.Height*0.70;$y+=12) {
    for ($x=[int]($Bitmap.Width*0.15);$x -lt $Bitmap.Width*0.85;$x+=12) {
      $c=$Bitmap.GetPixel($x,$y)
      if (($c.R -gt 125 -and $c.G -lt 100 -and $c.B -lt 100) -or
          ($c.G -gt 125 -and $c.R -lt 100 -and $c.B -lt 100) -or
          ($c.B -gt 125 -and $c.R -lt 100 -and $c.G -lt 100)) { $count++ }
    }
  }
  return $count
}
if ($HomeOnly) {
  # This is the disposable CI profile, never the source/bundle. Preserve history.
  $profile = Join-Path $env:APPDATA 'br.com.docaio\Heisuca'
  New-Item -ItemType Directory -Path $profile -Force | Out-Null
  $preferencesPath = Join-Path $profile 'heisuca-desktop-preferences.json'
  $preferences = if (Test-Path $preferencesPath) { Get-Content $preferencesPath -Raw | ConvertFrom-Json -AsHashtable } else { @{ version=1; recents=@() } }
  $preferences.theme = $Theme
  $preferences | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $preferencesPath -Encoding UTF8
}
$process=$null;$first=$null;$second=$null
$renderTimer = [Diagnostics.Stopwatch]::StartNew()
try {
  $process = if ($HomeOnly) {
    Start-Process -FilePath $exe -PassThru -WorkingDirectory (Split-Path $exe)
  } else {
    Start-Process -FilePath $exe -ArgumentList ('"'+$fixture+'"') -PassThru -WorkingDirectory (Split-Path $exe)
  }
  $limit=[DateTime]::UtcNow.AddSeconds(25)
  do {
    Start-Sleep -Milliseconds 300
    $process.Refresh()
    if ($process.HasExited) { throw 'O executavel encerrou antes da prova visual.' }
    $handle=$process.MainWindowHandle
  } while ($handle -eq [IntPtr]::Zero -and [DateTime]::UtcNow -lt $limit)
  if ($handle -eq [IntPtr]::Zero) { throw 'Janela nao apareceu no prazo.' }
  [void][HeisucaWindowCapture]::SetWindowPos($handle,[IntPtr]::Zero,0,0,1000,700,0x0040)
  [void][HeisucaWindowCapture]::SetForegroundWindow($handle)
  if ($HomeOnly) {
    Start-Sleep -Seconds 2
    $first = Capture-Window $handle
    $first.Save((Join-Path $Output 'windows-home.png'), [System.Drawing.Imaging.ImageFormat]::Png)
    @{ nativeWindow=$true; mode='home'; themeRequested=$Theme; physicalGpuCertified=$false } |
      ConvertTo-Json | Set-Content (Join-Path $Output 'home-evidence.json') -Encoding UTF8
    return
  }
  do {
    Start-Sleep -Milliseconds 500
    if ($first) { $first.Dispose() }
    $first=Capture-Window $handle
    $colored=Count-VideoColors $first
  } while ($colored -lt 35 -and [DateTime]::UtcNow -lt $limit)
  $first.Save((Join-Path $Output 'windows-video-01.png'),[System.Drawing.Imaging.ImageFormat]::Png)
  if ($colored -lt 35) { throw 'Sem padrao de cores do video na janela composta: imagem preta, erro ou loading.' }
  $firstVideoSeconds = [Math]::Round($renderTimer.Elapsed.TotalSeconds, 3)
  $forwarded = $false
  if ($VerifySecondInstance) {
    $secondSource = Join-Path $env:RUNNER_TEMP 'Heisuca segunda fonte ação.mkv'
    Copy-Item -LiteralPath $fixture -Destination $secondSource -Force
    # Reproduce the startup-visibility race deliberately: the owner exists but is hidden.
    [void][HeisucaWindowCapture]::ShowWindow($handle, 0)
    $launcher = Start-Process -FilePath $exe -ArgumentList ('"'+$secondSource+'"') -PassThru -WorkingDirectory (Split-Path $exe)
    Start-Sleep -Milliseconds 700
    [void][HeisucaWindowCapture]::ShowWindow($handle, 5)
    if (-not $launcher.WaitForExit(5000) -or $launcher.ExitCode -ne 0) { throw 'Second launch did not forward to existing instance.' }
    $process.Refresh()
    if ($process.HasExited) { throw 'Original instance exited during file handoff.' }
    $historyPath = Join-Path $env:APPDATA 'br.com.docaio\Heisuca\heisuca-desktop-preferences.json'
    $sourceLimit = [DateTime]::UtcNow.AddSeconds(10)
    $sourceConfirmed = $false
    do {
      Start-Sleep -Milliseconds 150
      if (Test-Path -LiteralPath $historyPath) {
        try {
          $history = Get-Content -LiteralPath $historyPath -Raw | ConvertFrom-Json
          $sourceConfirmed = $history.recents.Count -gt 0 -and $history.recents[0].uri -like '*segunda*fonte*'
        } catch { $sourceConfirmed = $false }
      }
    } while (-not $sourceConfirmed -and [DateTime]::UtcNow -lt $sourceLimit)
    if (-not $sourceConfirmed) { throw 'Second source was forwarded but did not render/persist in the desktop app.' }
    $forwarded = $true
  }
  Start-Sleep -Seconds 2
  $second=Capture-Window $handle
  $second.Save((Join-Path $Output 'windows-video-02.png'),[System.Drawing.Imaging.ImageFormat]::Png)
  $changed=0
  for ($y=[int]($first.Height*0.25);$y -lt $first.Height*0.70;$y+=8) {
    for ($x=[int]($first.Width*0.15);$x -lt $first.Width*0.85;$x+=8) {
      $a=$first.GetPixel($x,$y);$b=$second.GetPixel($x,$y)
      if ([Math]::Abs([int]$a.R-[int]$b.R)+[Math]::Abs([int]$a.G-[int]$b.G)+[Math]::Abs([int]$a.B-[int]$b.B) -gt 50) { $changed++ }
    }
  }
  if ($changed -lt 20) { throw 'A janela mostra cores, mas o quadro nao avancou entre capturas.' }
  $process.Refresh()
  @{ firstVideoSeconds=$firstVideoSeconds; workingSetMiB=[Math]::Round($process.WorkingSet64 / 1MB, 1); nativeWindow=$true; secondInstanceForwarded=$forwarded; coloredSamples=$colored; changedSamples=$changed; physicalGpuCertified=$false; physicalAudioCertified=$false } |
    ConvertTo-Json | Set-Content (Join-Path $Output 'evidence.json') -Encoding UTF8
  Write-Host "Prova visual nativa: cores=$colored, amostras que mudaram=$changed."
} finally {
  if ($first) { $first.Dispose() }
  if ($second) { $second.Dispose() }
  if ($process) {
    $process.Refresh()
    if (-not $process.HasExited) {
      [void]$process.CloseMainWindow()
      if (-not $process.WaitForExit(10000)) { Stop-Process -Id $process.Id -Force }
    }
  }
}
