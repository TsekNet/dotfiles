#!/bin/bash

set -e # Exit on Error
set -x # Log Executions

################################################################################
# Install commands                                                             #
################################################################################
cd "$HOME" || return
echo -e "BEEP BOOP. Setting up..."
sudo apt install curl wget gpg -y

# https://learn.microsoft.com/en-us/dotnet/core/install/linux-debian
wget https://packages.microsoft.com/config/debian/12/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
sudo dpkg -i packages-microsoft-prod.deb
rm packages-microsoft-prod.deb

# https://code.visualstudio.com/docs/setup/linux
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
sudo install -D -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg
sudo sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'
rm -f packages.microsoft.gpg
sudo apt update

sudo apt install openssh-server vim git xclip lsb-release dotnet-sdk-8.0 apt-transport-https code-insiders -y
curl -sS https://starship.rs/install.sh | sh -s -- --force

# Install pwsh (https://github.com/PowerShell/PowerShell/issues/19889)
dotnet tool update --global powershell
PATH=$HOME/.dotnet/tools:$PATH
echo $(pwsh --version) installed!

sudo apt upgrade -y

################################################################################
# Setup SSH                                                                    #
################################################################################
ssh-keygen -t ed25519 -C "admin@tseknet.com"
eval `ssh-agent -s`
ssh-add
chmod 0700 ~/.ssh # Ensure correct permissions
set +x
echo -e 'Copy to https://github.com/settings/ssh/new'
cat ~/.ssh/id_ed25519.pub | xclip -selection clipboard
echo -e -n "SSH Public Key copied to clipboard: [\033[32m"$(cat ~/.ssh/id_ed25519.pub)"\033[0m]\n"
read -p 'Press any key to continue...'

################################################################################
# Chezmoi                                                                      #
################################################################################
set -x
cd ~
curl -sfL https://git.io/chezmoi | bash

if [ ! -n "$(grep "^github.com " ~/.ssh/known_hosts)" ]; then ssh-keyscan github.com >> ~/.ssh/known_hosts 2>/dev/null; fi

export PATH=$HOME/bin:$PATH
chezmoi init --apply --verbose git@github.com:tseknet/dotfiles.git

################################################################################
# PowerShell                                                                   #
################################################################################
# Set pwsh as the default shell
sudo chsh -s "$(command -v pwsh)" "${USER}"

# Install PowerShell (pwsh) Modules
pwsh -NoLogo