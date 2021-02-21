<#
.Synopsis
    Install TsekNet dotfiles.

.DESCRIPTION
    Used for one-line PC setup. Includes package installs, profile download, etc.
    TODO: Fill this in with detailed steps
#>

################################################################################
# Package Management (https://tseknet.com/blog/chocolatey)                     #
################################################################################

Write-Host 'Configuring Chocolatey...' -ForegroundColor Magenta

if (-not (Get-Command -Name choco -ErrorAction SilentlyContinue)) {
  # Allow downloads
  Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Force -Verbose

  # Install Chocolatey
  [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
  Invoke-WebRequest https://chocolatey.org/install.ps1 -UseBasicParsing | Invoke-Expression -Verbose

  # Auto confirm package installations (no need to pass -y)
  choco feature enable -n allowGlobalConfirmation -y

  refreshenv
}

function Test-ChocolateyPackageInstalled {
  <#
  .LINK
    https://octopus.com/docs/runbooks/runbook-examples/routine/installing-software-chocolatey
  #>
  Param (
    [Parameter(Mandatory)]
    [string]
    $Package
  )

  Process {
    if (Test-Path -Path $env:ChocolateyInstall) {
      $packageInstalled = Test-Path -Path $env:ChocolateyInstall\lib\$Package
    } else {
      Write-Host "Can't find a chocolatey install directory..."
    }

    return $packageInstalled
  }
}

$DESIRED_PACKAGES = @(
  '7zip'
  'cascadiacodepl'
  'chezmoi'
  'git'
  'gitversion.portable'
  'google-backup-and-sync'
  'googlechrome'
  'greenshot'
  'microsoft-edge'
  'microsoft-windows-terminal'
  'mpc-hc'
  'notepadplusplus'
  'openssh'
  'powershell-preview'
  'python3'
  'spotify'
  'starship'
  'steam'
  'treesizefree'
  'vscode-insiders'
)

$missing_packages = [System.Collections.ArrayList]::new()
foreach ($package in $DESIRED_PACKAGES) {
  if (-not (Test-ChocolateyPackageInstalled($package))) {
    $missing_packages.Add($package)
  }
}

if ($missing_packages) {
  & choco install $missing_packages
}

# Keep packages up to date
if (-not (Test-ChocolateyPackageInstalled('choco-upgrade-all-at'))) {
  & choco install choco-upgrade-all-at --params "'/WEEKLY:yes /DAY:SUN /TIME:01:00'" --force
}

################################################################################
# GitHub setup                                                                 #
################################################################################

Write-Host 'Configuring GitHub SSH key...' -ForegroundColor Magenta

# Use OpenSSH ssh-keygen rather than the one in path
& "$env:ProgramFiles\OpenSSH-Win64\ssh-keygen.exe" -t ed25519 -C 'admin@tseknet.com'
ssh-add "$env:USERPROFILE/.ssh/id_ed25519"

# Copy resulting output to GitHub
$pub_key = Get-Content $env:USERPROFILE/.ssh/id_ed25519.pub
$pub_key | Set-Clipboard
Write-Host 'SSH Public Key copied to clipboard: [' -NoNewline
Write-Host $pub_key -ForegroundColor Green -NoNewline
Write-Host ']'

# Wait until key is added to GitHub
Write-Output 'Launching chrome to add SSH key. Press any key to continue...'
Start-Process chrome 'https://github.com/settings/ssh/new'
$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')

################################################################################
# Chezmoi setup                                                                #
################################################################################

Write-Host 'Configuring Chezmoi...' -ForegroundColor Magenta

chezmoi cd
chezmoi init --apply --verbose git@github.com:tseknet/dotfiles.git
chezmoi diff
chezmoi apply