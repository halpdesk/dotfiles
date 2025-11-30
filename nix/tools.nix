{ config, pkgs, lib, username, ... }:

{
  imports = [
    # (import ./modules/lamp.nix { inherit config pkgs lib; })
    # (import ./modules/barracuda-vpn.nix { inherit config pkgs lib; })
  ];

  home.packages = with pkgs; [
    # file finders and managers
    zoxide # Smarter cd command with jump capability <----------- USE
    yazi # Blazing fast TUI file manager (vim-like) <------------ USE
    eza # exa successor, even better <--------------------------- USE
    dog # Like cat, but with more options.
    bat # A cat clone with syntax highlighting and Git integration
    lsd # Another modern ls alternative with icons
    pup # html parser
    html-xml-utils
    pandoc

    # compression
    gnutar
    gzip

    # search tools
    fzf # Fuzzy finder for files, history, git, etc.
    broot # Navigate directory trees with fuzzy search
    fd # A simpler, faster alternative to find
    ripgrep # Fast grep alternative (rg)

    # system help
    neofetch
    navi # Interactive cheat sheet for CLI commands
    tealdeer # Fast tldr client (command help)
    xorg.xinput

    # filesystem tools
    f3

    # net utils
    cacert
    inetutils # telnet and other
    openssh
    rsync
    curl
    xh # Friendly and modern replacement for curl
    wget
    dig
    # (import derivations/access-gui.nix { inherit pkgs; })
    # transmission_3-gtk
    # transmission_4

    # media
    gimp
    vlc
    flameshot
    nomacs # image viewer
    libreoffice-fresh

    # games
    rogue
    gnuchess
    bsdgames

    # web browsers and extensions
    google-chrome
    brave

    # communiation
    slack
    irssi
    discord

    # utilities
    _1password-cli
    _1password-gui
  ];

  # services.transmission = {
  #   enable = true; # Enable transmission daemon
  #   package = pkgs.transmission_4;
  #   openRPCPort = true; # Open firewall for RPC
  #   settings = { # Override default settings
  #     rpc-bind-address = "0.0.0.0"; # Bind to own IP
  #     rpc-whitelist =
  #       "127.0.0.1,10.0.0.1"; # Whitelist your remote machine (10.0.0.1 in this example)
  #     download-dir = "$HOME/Downloads";
  #   };
  # };

}

