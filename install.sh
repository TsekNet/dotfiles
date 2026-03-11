#!/bin/bash

set -e # Exit on Error
set -x # Log Executions

################################################################################
# Install commands                                                             #
################################################################################
cd "$HOME" || return
echo -e "BEEP BOOP. Setting up..."
sudo apt install curl wget gpg -y

sudo apt install openssh-server vim git xclip lsb-release apt-transport-https -y
curl -sS https://starship.rs/install.sh | sh -s -- --force

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
cd ~
curl -sfL https://git.io/chezmoi | bash

if [ ! -n "$(grep "^github.com " ~/.ssh/known_hosts)" ]; then ssh-keyscan github.com >> ~/.ssh/known_hosts 2>/dev/null; fi

export PATH=$HOME/bin:$PATH
chezmoi init --apply --verbose git@github.com:tseknet/dotfiles.git

################################################################################
# Shell                                                                        #
################################################################################
# Bash is the default shell; install starship prompt (shared config with pwsh)
if ! command -v starship &>/dev/null; then
  curl -sS https://starship.rs/install.sh | sh -s -- --yes
fi

