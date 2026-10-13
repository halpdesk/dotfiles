{ config, pkgs, lib, ... }:

let
  nixgl = import (builtins.fetchTarball
    "https://github.com/nix-community/nixGL/archive/main.tar.gz") {
      inherit pkgs;
    };

  sdrppWrapped = pkgs.writeShellScriptBin "sdrpp-wrapped" ''
    # Ensure plugin directory exists in user space
    mkdir -p ~/.local/share/sdrpp/plugins/@prefix@/lib/sdrpp

    # Link nix store plugins to expected path (safe because -f removes stale links)
    ln -sf ${pkgs.sdrpp}/lib/sdrpp/plugins \
      ~/.local/share/sdrpp/plugins/@prefix@/lib/sdrpp/plugins

    export SDRPP_ROOT=~/.local/share/sdrpp
    export LD_LIBRARY_PATH=${pkgs.rtl-sdr}/lib:$LD_LIBRARY_PATH

    exec ${nixgl.auto.nixGLDefault}/bin/nixGL \
         ${pkgs.sdrpp}/bin/sdrpp "$@"
  '';

in {
  home.packages = with pkgs; [
    nixgl.auto.nixGLDefault
    rtl-sdr
    sdrpp
    sdrppWrapped
  ];
}
