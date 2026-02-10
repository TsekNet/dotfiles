# Skip loading profile when running in Cursor sandbox (fast, no network/modules)
if ($env:NPM_CONFIG_CACHE -and $env:NPM_CONFIG_CACHE -eq 'cursor-sandbox-cache') { return }

#region functions

function Get-FileHash256 {
  <#
  .SYNOPSIS
    Compute the SHA-256 hash for a given file.
  .DESCRIPTION
    Wrapper function for Get-FileHash which defaulst the Algorithm parameter to
    SHA256 and copies the returned hash to the clipboard.
  .PARAMETER Path
    Fully qualified path to the file for which to obtain the SHA-256 hash.
  .EXAMPLE
    Get-FileHash256 -Path C:\Windows\System32\notepad.exe
  #>
  [CmdletBinding()]
  param (
    [System.IO.FileInfo]$Path
  )

  if (-not (Test-Path $Path)) {
    throw "File $Path not found, could not determine hash."
  }

  $sha_256_hash = (Get-FileHash -Algorithm SHA256 $Path).hash
  Write-Host "SHA-256 hash copied to clipboard for [$Path]: " -NoNewline
  Write-Host $sha_256_hash -ForegroundColor Green
  return $sha_256_hash | Set-Clipboard
}

function Edit-Profile {
  <#
  .SYNOPSIS
    Opens the $profile file an editor.
  .DESCRIPTION
    Opens the $profile.CurrentUserAllHosts file conditionally in one of the
    following programs:
    1. PowerShell ISE, if detected as the current host.
    2. VSCode, if detected as the current host.
    3. Notepad, if the current host is netiher of the above.
  .EXAMPLE
    Edit-Profile
  #>

  $PATH = $profile.CurrentUserAllHosts

  switch ((Get-Host).Name) {
    'Visual Studio Code Host' {
      if (Get-Command Open-EditorFile -ErrorAction SilentlyContinue) { Open-EditorFile $PATH }
      elseif (Get-Command code-insiders -ErrorAction SilentlyContinue) { code-insiders $PATH }
      else { & code $PATH }
    }
    'Windows PowerShell ISE Host' { psedit $PATH }
    default { Start-Process "$env:windir\system32\notepad.exe" -ArgumentList @($PATH) }
  }
}

function Open-HistoryFile {
  <#
  .SYNOPSIS
    Opens the PowerShell history file.
  .DESCRIPTION
    Opens the (Get-PSReadLineOption).HistorySavePath file conditionally in one
    of the following programs:
    1. PowerShell ISE, if detected as the current host.
    2. VSCode, if detected as the current host.
    3. Notepad, if the current host is netiher of the above.
  .EXAMPLE
    Open-HistoryFile
  #>

  if (-not (Get-Module PSReadLine)) {
    Write-Warning 'PSReadLine not loaded; cannot open history file.'
    return
  }
  $HISTORY_PATH = (Get-PSReadLineOption).HistorySavePath

  switch ((Get-Host).Name) {
    'Visual Studio Code Host' {
      if (Get-Command Open-EditorFile -ErrorAction SilentlyContinue) { Open-EditorFile $HISTORY_PATH }
      elseif (Get-Command code-insiders -ErrorAction SilentlyContinue) { code-insiders $HISTORY_PATH }
      else { & code $HISTORY_PATH }
    }
    'Windows PowerShell ISE Host' { psedit $HISTORY_PATH }
    default { Start-Process "$env:windir\system32\notepad.exe" -ArgumentList $HISTORY_PATH }
  }
}

#endregion

#region execution

################################################################################
# Update the console title with current PowerShell elevation and version       #
################################################################################
$baseTitle = "PS | v$($PSVersionTable.PSVersion.Major).$($PSVersionTable.PSVersion.Minor)"
try {
  $Host.UI.RawUI.WindowTitle = "$baseTitle | $((Invoke-WebRequest -Uri 'https://wttr.in/nyc?format=%c%t&u' -UseBasicParsing -TimeoutSec 3).Content)"
} catch {
  $Host.UI.RawUI.WindowTitle = "$baseTitle | $env:COMPUTERNAME"
}

################################################################################
# PSReadLine and prompt options                                                #
################################################################################
if (-not (Get-Module PSReadline)) {
  Write-Warning 'Failed to locate PSReadLine module'
} else {
  Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
  Set-PSReadLineOption -ShowToolTips -BellStyle Visual -HistoryNoDuplicates
  try {
    Set-PSReadLineOption -PredictionSource History -PredictionViewStyle ListView
  } catch {
    # PredictionSource / PredictionViewStyle require PSReadLine 2.1+ (e.g. not in WinPS 5.1)
  }

  if ($env:STARSHIP_SHELL -in 'powershell', 'pwsh') {
    # Set the prompt character to change color based on syntax errors
    # https://github.com/PowerShell/PSReadLine/issues/1541#issuecomment-631870062
    $esc = [char]0x1b
    $symbol = [char]0x276F  # ❯
    $fg = '0'
    $bg = '8;2;78;213;93'  # 24-bit color
    $err_bg = '1'
    $csi = "$esc" + "["
    Set-PSReadLineOption -PromptText (
      " ${csi}4${fg};3${bg}m$symbol ",
      " ${csi}4${fg};3${err_bg}m$symbol "
    )
    $env:STARSHIP_LOG = 'error'
  }
}

# https://starship.rs/ — cache init script so we don't spawn starship every startup
$starshipCacheDir = if ($env:XDG_CACHE_HOME) { $env:XDG_CACHE_HOME } elseif ($env:LOCALAPPDATA) { $env:LOCALAPPDATA } else { Join-Path $env:HOME '.cache' }
$starshipCache = Join-Path $starshipCacheDir 'starship-init.ps1'
$cacheMaxAgeHours = 24
$useCache = (Test-Path $starshipCache) -and ((Get-Item $starshipCache).LastWriteTime -gt (Get-Date).AddHours(-$cacheMaxAgeHours))
if ($useCache) {
  . $starshipCache
} else {
  $init = & starship init powershell 2>$null
  if ($init) {
    New-Item -ItemType Directory -Path $starshipCacheDir -Force | Out-Null
    $init | Set-Content -Path $starshipCache -Encoding utf8 -Force
    Invoke-Expression ($init -join "`n")
  } else {
    Invoke-Expression (&starship init powershell)
  }
}

################################################################################
# Windows/Linux differences                                                    #
################################################################################
if ($IsLinux -or $IsMacOs) {
  $TMP_DIR = '/tmp/'

  # PSDepend doesn't seem to work on PS7 on Linux, install modules here.
  Set-PSRepository -Name 'PSGallery' -InstallationPolicy Trusted
  $modules = @('PowerShellGet', 'PSReadLine', 'Get-ChildItemColor', 'PSWriteHTML')
  $available = (Get-Module -ListAvailable).Name
  foreach ($module in $modules) {
    if ($module -notin $available) {
      Install-Module $module -AllowClobber -AllowPrerelease -Scope CurrentUser -Force
    }
  }

  function g4d {
    param (
      [System.IO.FileInfo]$Path
    )
    Set-Location -Path $(p4 g4d $Path)
  }
  function hgd {
    param (
      [System.IO.FileInfo]$Path
    )
    Set-Location -Path $(hg hgd $Path)
  }
  
} else {
  $TMP_DIR = 'C:\Tmp'
  # Chezmoi edit command defaults to vi, which doesn't exist on Windows
  $env:EDITOR = 'code-insiders'

  # Fake sudo on Windows
  function sudo {
    Start-Process @args -Verb RunAs -Wait
  }
}

################################################################################
# Set common aliases                                                           #
################################################################################
if (Get-Command Get-ChildItemColor -ErrorAction SilentlyContinue) {
  Set-Alias -Name ll -Value Get-ChildItemColor -Scope Global -Option AllScope
  Set-Alias -Name ls -Value Get-ChildItemColorFormatWide -Scope Global -Option AllScope
}
Set-Alias -Name History -Value Open-HistoryFile -Scope Global -Option AllScope

################################################################################
# Always start in the same directory                                           #
################################################################################

if (-not (Test-Path $TMP_DIR)) {
  New-Item -ItemType Directory -Path $TMP_DIR -Force
}
Set-Location $TMP_DIR

#endregion
