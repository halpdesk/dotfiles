{ config, pkgs, lib, ... }:

# unstable = import <nixpkgs-unstable> { };

# package url from: https://downloads.access.barracuda.com/apt/dists/stable/main/binary-amd64/Packages
pkgs.stdenv.mkDerivation {
  pname = "barracuda-vpn";
  version = "2.5.11";
  src = pkgs.fetchurl {
    url =
      "https://downloads.access.barracuda.com/apt/pool/stable/a/ac/access-tunnel_2.5.11_amd64.deb";
    sha256 = "sha256-Gg3+M8Qwa4iSUxX36sDgwBpuJ0F1iFqydeubhqGi2Ho=";
  };
  # buildInputs = [ pkgs.dpkg pkgs.cacert ];
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

  meta = with lib; {
    description = "Barracuda VPN (access-tunnel and access-interface)";
    platforms = platforms.linux;
  };
}

# //
# // This needs to run outside of nix afterwards to make it work
# //
# sudo groupadd access
# sudo usermod -aG access $USER
# newgrp access
# ACCESS_TUNNEL_BIN=$(readlink -f "$(which access-tunnel)")
# ACCESS_INTERFACE_BIN=$(readlink -f "$(which access-interface)")
# mkdir -p $HOME/Apps/access
# sudo cp $ACCESS_TUNNEL_BIN $HOME/Apps/access/access-tunnel
# sudo cp $ACCESS_INTERFACE_BIN $HOME/Apps/access/access-interface
# sudo chown root:access $HOME/Apps/access/access-interface
# sudo chown root:access $HOME/Apps/access/access-tunnel
# sudo chmod 750 $HOME/Apps/access/access-interface
# sudo chmod 750 $HOME/Apps/access/access-tunnel
# sudo setcap cap_net_admin,cap_net_raw+ep $(readlink -f $(which access-interface))
# sudo setcap cap_net_admin,cap_net_raw+ep $(readlink -f $(which access-tunnel))
# sudo mkdir -p ~/.config/fyde/Shared ~/.cache/fyde/Caches
# sudo chmod 777 ~/.config/fyde/Shared ~/.cache/fyde/Caches
# sudo chown $(whoami):$(whoami) -R ~/.config/fyde/Shared ~/.cache/fyde/Caches

## Check which group you need to belong to, tpm or tss: `ls -l /dev/tpm*`
# sudo usermod -aG tss $USER
# newgrp tss
