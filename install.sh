#!/bin/bash

set -e # Exit on Error

cd "$HOME" || return
echo -e "BEEP BOOP. Setting up..."
set -x # Log Executions
sudo apt update
sudo apt install openssh-server fish vim curl git -y
sudo apt upgrade -y

ssh-keygen -t ed25519 -C "admin@tseknet.com"
eval `ssh-agent -s`
ssh-add
chmod 0700 ~/.ssh # Ensure correct permissions
set +x
echo -e 'Copy to https://github.com/settings/ssh/new'
echo -e "\033[32m" ;cat ~/.ssh/id_ed25519.pub; echo -e "\033[0m"
read -p 'Press any key to continue...'

# Install chezmoi
set -x
cd ~
curl -sfL https://git.io/chezmoi | bash

if [ ! -n "$(grep "^github.com " ~/.ssh/known_hosts)" ]; then ssh-keyscan github.com >> ~/.ssh/known_hosts 2>/dev/null; fi

export PATH=$HOME/bin:$PATH
chezmoi init --apply --verbose git@github.com:tseknet/dotfiles.git
chezmoi apply