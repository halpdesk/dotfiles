# README

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

sudo rm -rf "/etc/nix" "/nix" "/root/.nix-profile" "/root/.nix-defexpr" "/root/.nix-channels" "/root/.local/state/nix" "/root/.cache/nix" "/home/halpdesk/.nix-profile" "/home/halpdesk/.nix-defexpr" "/home/halpdesk/.nix-channels" "/home/halpdesk/.local/state/nix" "/home/halpdesk/.cache/nix"
