{ config, pkgs, username, ... }:

{
  home.packages = with pkgs; [
    # file finders and managers
    zoxide # Smarter cd command with jump capability <----------- USE
    yazi # Blazing fast TUI file manager (vim-like) <------------ USE
    eza # exa successor, even better <--------------------------- USE
    dog # Like cat, but with more options.
    bat # A cat clone with syntax highlighting and Git integration
    lsd # Another modern ls alternative with icons

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

    # net utils
    inetutils # telnet and other
    openssh
    rsync
    curl
    xh # Friendly and modern replacement for curl
    wget

    # media
    gimp
    vlc
    flameshot
    nomacs # image viewer

    # games
    rogue
    gnuchess
    bsdgames

    # web browsers and extensions
    google-chrome
    brave

    # communiation
    slack
  ];
}
