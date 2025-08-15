{ config, pkgs, username, ... }:

let
  # unstable = import <nixpkgs-unstable> { };

  # package url from: https://downloads.access.barracuda.com/apt/dists/stable/main/binary-amd64/Packages
  barracuda-vpn = pkgs.stdenv.mkDerivation {
    pname = "barracuda-vpn";
    version = "0.32.2";
    src = pkgs.fetchurl {
      url =
        "https://downloads.access.barracuda.com/apt/pool/stable/a/ac/access-tunnel_0.30.2_amd64.deb";
      sha256 = "sha256-MiMECichCe5UMWBH9EJi2PhCnXPqaJNHjhqCrbAk1fc=";
    };
    nativeBuildInputs = [ pkgs.dpkg ];
    unpackPhase = ''
      dpkg-deb -x $src .
    '';

    installPhase = ''
      mkdir -p $out/opt/access
      mkdir -p $out/bin
      cp -r opt/access/* $out/opt/access

      ln -s $out/opt/access/access-tunnel $out/bin/access-tunnel
      ln -s $out/opt/access/access-interface $out/bin/access-interface
    '';
  };

in {
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
    barracuda-vpn
    transmission_3-gtk
    # transmission_4

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

