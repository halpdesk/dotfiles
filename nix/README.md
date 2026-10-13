# README

## Installation

1. Nix package manager
https://nixos.org/download/

2. Home manager
https://nix-community.github.io/home-manager/#sec-install-standalone

3. nixpkgs-unstable
nix-channel --add https://nixos.org/channels/nixpkgs-unstable nixpkgs-unstable
nix-channel --update



## Useful commands
cat ~/.config/home-manager/default.nix
cat ~/.config/home-manager/home.nix

nix-channel --update
nix-channel --list
nix-collect-garbage -d

home-manager generations
home-manager expire-generations '-7 days'


## VS Code
code --list-extensions --show-versions

rm -rf ~/.vscode/extensions/*
rm -rf ~/.vscode-server/extensions/*  # optional if you use remote dev

rm -rf ~/.config/Code/User/workspaceStorage
rm -rf ~/.config/Code/CachedData

## Repository
https://search.nixos.org/packages?channel=25.05&

## Clean up nix
sudo systemctl stop nix-daemon.socket
sudo systemctl stop nix-daemon.service
sudo systemctl disable nix-daemon.socket
sudo systemctl disable nix-daemon.service
sudo systemctl daemon-reload

sudo mv /etc/bash.bashrc.backup-before-nix /etc/bash.bashrc

> Replace username with your username
sudo rm -rf "/etc/nix" "/nix" "/root/.nix-profile" "/root/.nix-defexpr" "/root/.nix-channels" "/root/.local/state/nix" "/root/.cache/nix" "/home/username/.nix-profile" "/home/username/.nix-defexpr" "/home/username/.nix-channels" "/home/username/.local/state/nix" "/home/username/.cache/nix"
