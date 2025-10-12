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
