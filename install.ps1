<#
.Synopsis
  Install TsekNet dotfiles.
.DESCRIPTION
  Used for one-line PC setup. Includes package installs, profile download, etc.

  Performs the following tasks, in order:
  1. Install and configure Chocolatey (https://tseknet.com/blog/chocolatey)
  2. Install defined Chocolatey packages
  3. Install package to auto-update all Chocolately packages via Windows Scheduled Tasks
  4. Install PSDepend for package management
  5. Download requirements.psd1 from GitHub to determine modules to install and import
  6. Install and import modules based on list in #5
  7. Configure GitHub SSH keys
  8. Initialize Chezmoi (https://github.com/twpayne/chezmoi) to download and keep remaining dotfiles up-to-date
.PARAMETER ModuleUri
 Fully qualified Uri for the requirements.psd1 file used by PSDepend to install depdendencies.
 See https://github.com/RamblingCookieMonster/PSDepend for more information
.PARAMETER ModulefilePath
 Destination path for the $ModuleUri parameter file (excluding requirements.psd1)
.PARAMETER SSHFile
 Fully qualified path of the SSH file used for GitHub authentication required for chezmo.
.PARAMETER SSHEmail
 Email address for which to add the GitHub SSH key
.PARAMETER SSHUri
 GitHub SSH Uri for the repository that contains desired dotfiles
.PARAMETER Packages
 List of Chocolatey packages to install if missing
#>

[CmdletBinding()]
param (
  [System.Uri]$ModuleUri = 'https://raw.githubusercontent.com/TsekNet/dotfiles/main/dot_config/requirements.psd1',
  [System.IO.FileInfo]$ModuleFilePath = "$env:HOMEDRIVE\$env:HOMEPATH\.config",

  [System.IO.FileInfo]$SSHFile = "$env:USERPROFILE/.ssh/id_ed25519",
  [String]$SSHEmail = 'admin@tseknet.com',
  [String]$SSHUri = 'git@github.com:tseknet/dotfiles.git',

  [String[]]$Packages = @(
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
)

################################################################################
# Package Management                                                           #
################################################################################
Write-Host 'Configuring Chocolatey...' -ForegroundColor Magenta

if (-not (Get-Command -Name choco -ErrorAction SilentlyContinue)) {
  # Allow downloads
  Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Force -Verbose

  # Install Chocolatey
  [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
  Invoke-WebRequest 'https://chocolatey.org/install.ps1' -UseBasicParsing | Invoke-Expression -Verbose

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
    [string]$Package
  )

  Process {
    if (Test-Path -Path $env:ChocolateyInstall) {
      $packageInstalled = Test-Path -Path "$env:ChocolateyInstall\lib\$Package"
    } else {
      Write-Host "Can't find a chocolatey install directory..."
    }

    return $packageInstalled
  }
}

$missing_packages = [System.Collections.ArrayList]::new()
foreach ($package in $Packages) {
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
# Add commonly used modules (this must be done first)                          #
################################################################################
Install-Module PSDepend -Scope CurrentUser
Import-Module PSDepend

Write-Host 'Downloading PowerShell module dependency list from GitHub...' -ForegroundColor Magenta
New-Item -ItemType Directory $ModuleFilePath -ErrorAction SilentlyContinue
Invoke-WebRequest -Uri $ModuleUri -UseBasicParsing -OutFile "$ModuleFilePath\requirements.psd1"

Write-Host 'Installing PowerShell modules...' -ForegroundColor Magenta
Invoke-PSDepend -Path "$ModuleFilePath\requirements.psd1" -Import -Force

################################################################################
# GitHub setup                                                                 #
################################################################################
Write-Host 'Configuring GitHub SSH key...' -ForegroundColor Magenta

# Use OpenSSH ssh-keygen rather than the one in path
& "$env:ProgramFiles\OpenSSH-Win64\ssh-keygen.exe" -t ed25519 -C $SSHEmail
ssh-add $SSHFile

# Copy resulting output to GitHub
$pub_key = Get-Content "$SSHFile.pub"
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

chezmoi init --apply --verbose $SSHUri
chezmoi diff