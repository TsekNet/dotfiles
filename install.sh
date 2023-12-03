#!/bin/bash

set -e # Exit on Error
set -x # Log Executions

# Install commands
cd "$HOME" || return
echo -e "BEEP BOOP. Setting up..."
sudo apt update
sudo apt install openssh-server vim curl git xclip wget lsb-release -y
curl -sS https://starship.rs/install.sh | sh -s -- --force
sudo apt upgrade -y

# Setup SSH
ssh-keygen -t ed25519 -C "admin@tseknet.com"
eval `ssh-agent -s`
ssh-add
chmod 0700 ~/.ssh # Ensure correct permissions
set +x
echo -e 'Copy to https://github.com/settings/ssh/new'
cat ~/.ssh/id_ed25519.pub | xclip -selection clipboard
echo -e -n "SSH Public Key copied to clipboard: [\033[32m"$(cat ~/.ssh/id_ed25519.pub)"\033[0m]\n"
read -p 'Press any key to continue...'

# Install pwsh (https://github.com/PowerShell/PowerShell/issues/19889)
sudo apt install dotnet-sdk-8.0
dotnet tool update --global powershell
PATH=$HOME/.dotnet/tools:$PATH
echo $(pwsh --version) installed!

# Install chezmoi
set -x
cd ~
curl -sfL https://git.io/chezmoi | bash

if [ ! -n "$(grep "^github.com " ~/.ssh/known_hosts)" ]; then ssh-keyscan github.com >> ~/.ssh/known_hosts 2>/dev/null; fi

export PATH=$HOME/bin:$PATH
chezmoi init --apply --verbose git@github.com:tseknet/dotfiles.git

# Install PowerShell (pwsh) Modules
pwsh