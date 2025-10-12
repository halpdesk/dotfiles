{ config, pkgs, lib, ... }:

let
  fydeVersion = "2.5.11";
  fydeSrc = pkgs.fetchurl {
    # package url from: https://downloads.access.barracuda.com/apt/dists/stable/main/binary-amd64/Packages
    url =
      "https://downloads.access.barracuda.com/apt/pool/stable/a/ac/access-tunnel_2.5.11_amd64.deb";
    sha256 = "sha256-Gg3+M8Qwa4iSUxX36sDgwBpuJ0F1iFqydeubhqGi2Ho=";
  };

  barracuda-vpn = pkgs.stdenv.mkDerivation {
    pname = "barracuda-vpn";
    version = fydeVersion;
    src = fydeSrc;
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
  };
in {
  programs.home-manager.enable = true;
  home.packages = with pkgs; [ wget glibc libcap cacert barracuda-vpn ];

  # Extra user setup
  home.sessionVariables = {
    ACCESS_TUNNEL_BIN =
      "${config.home.homeDirectory}/.nix-profile/bin/access-tunnel";
    ACCESS_INTERFACE_BIN =
      "${config.home.homeDirectory}/.nix-profile/bin/access-interface";
  };

  # Add Fyde desktop entry for cga:// handler
  xdg.mimeApps.defaultApplications = {
    "x-scheme-handler/cga" =
      "${config.home.homeDirectory}/.local/share/applications/fyde-enroller.desktop";
  };

  home.file.".local/share/applications/fyde-enroller.desktop".text = ''
    [Desktop Entry]
    Name=Fyde Enrollment
    Comment=Handle Fyde CGA enrollment URLs
    Exec=konsole --hold -e ${config.home.homeDirectory}/.nix-profile/bin/access-tunnel %u
    Terminal=true
    Type=Application
    NoDisplay=false
    MimeType=x-scheme-handler/cga;
    Icon=network-vpn
    Categories=Network;Security;
  '';

  home.activation.fydeSetup = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    echo "Starting Fyde setup..."

    #exec > >(tee /dev/tty) 2>&1

    ACCESS_TUNNEL_BIN=$(command -v ${barracuda-vpn}/bin/access-tunnel || true)
    ACCESS_INTERFACE_BIN=$(command -v ${barracuda-vpn}/bin/access-interface || true)

    if [ -z "$ACCESS_TUNNEL_BIN" ] || [ -z "$ACCESS_INTERFACE_BIN" ]; then
      echo "ERROR: access-tunnel or access-interface not found in PATH"
      exit 1  # or exit 1
    fi

    ACCESS_TUNNEL_BIN=$(readlink -f "$ACCESS_TUNNEL_BIN")
    ACCESS_INTERFACE_BIN=$(readlink -f "$ACCESS_INTERFACE_BIN")

    # create group if needed
    if ! /usr/bin/getent group access >/dev/null; then
      echo "Creating group 'access'..."
      /usr/bin/sudo /usr/sbin/groupadd access
    else
      echo "✅ Group 'access' already exists"
    fi

    # add user to groups
    for g in access tss; do
      if ! id -nG "$USER" | grep -qw $g; then
        echo "Adding $USER to group $g..."
        /usr/bin/sudo /usr/sbin/usermod -aG $g $USER
      else
        echo "✅ $USER already in $g group"
      fi
    done

    # create Apps folder
    mkdir -p ${config.home.homeDirectory}/Apps/access

    # copy binaries
    for bin in "$ACCESS_TUNNEL_BIN" "$ACCESS_INTERFACE_BIN"; do
      target="${config.home.homeDirectory}/Apps/access/$(basename $bin)"
      rm -f "$target"
      if [ ! -f "$target" ]; then
        echo "Copying $bin to $target"
        /usr/bin/sudo cp "$bin" "$target"
        /usr/bin/sudo chown root:access "$target"
        /usr/bin/sudo chmod 750 "$target"
      else
        echo "DEBUG: $target already exists!"
      fi

      # set capabilities
      if ! /usr/sbin/getcap "$bin" | grep -q "cap_net_admin,cap_net_raw+ep"; then
        echo "Setting capabilities on $bin"
        /usr/bin/sudo /usr/sbin/setcap cap_net_admin,cap_net_raw+ep "$bin"
      else
        echo "✅ Capabilities already set on $bin"
      fi
    done

    # ensure cache/config dirs exist
    for dir in ".cache/fyde/Caches" ".config/fyde/Shared"; do
      mkdir -p ${config.home.homeDirectory}/$dir
      /usr/bin/sudo chmod 777 ${config.home.homeDirectory}/$dir
      /usr/bin/sudo chown $(whoami):$(whoami) -R ${config.home.homeDirectory}/$dir
    done

    # register desktop entry
    # /usr/bin/xdg-mime default fyde-enroller.desktop x-scheme-handler/cga -- DOES NOT WORK
    # instead, add this in your setup:
    # xdg.mimeApps.defaultApplications = {
    #   "x-scheme-handler/cga" = "fyde-enroller.desktop";
    # }

  '';
}
