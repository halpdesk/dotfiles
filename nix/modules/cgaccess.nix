{ config, pkgs, lib, ... }:

let
  accessTunnel = pkgs.stdenv.mkDerivation {
    pname = "access-tunnel";
    version = "2.5.11";
    src = pkgs.fetchurl {
      # package url from: https://downloads.access.barracuda.com/apt/dists/stable/main/binary-amd64/Packages
      url =
        "https://downloads.access.barracuda.com/apt/pool/stable/a/ac/access-tunnel_2.5.11_amd64.deb";
      sha256 = "sha256-Gg3+M8Qwa4iSUxX36sDgwBpuJ0F1iFqydeubhqGi2Ho=";
    };
    nativeBuildInputs = [ pkgs.dpkg pkgs.cacert pkgs.makeWrapper ];
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
      description = "access (access-tunnel and access-interface)";
      platforms = platforms.linux;
    };
  };

  cgaccess = pkgs.stdenv.mkDerivation {
    pname = "cgaccess";
    version = "2.5.11";

    nativeBuildInputs = [ pkgs.binutils pkgs.cacert pkgs.makeWrapper ];

    src = pkgs.fetchurl {
      # package url from: https://downloads.access.barracuda.com/apt/dists/stable/main/binary-amd64/Packages
      # Depends: access-tunnel, gconf2, gconf-service, libnotify4, libappindicator1, libxtst6, libnss3, xdg-utils
      url =
        "https://downloads.access.barracuda.com/apt/pool/stable/a/ac/access_2.5.11_amd64.deb";
      sha256 = "sha256-wwnwD4W7QC3KwIKFUfuqzZ6b+4Px/WJF1et6aBZ5PnE=";
    };

    unpackPhase = ''
      mkdir source
      cd source
      ar x $src
      tar --extract --file=data.tar.xz
    '';

    installPhase = ''
      mkdir -p $out/bin
      cp -r * $out/
      cp -r ${accessTunnel}/opt/access/* $out/opt/access/
      # cp -r ${accessTunnel}/bin/* $out/bin/

      # Symlink the system CA certs
      ln -s /etc/ssl/certs $out/certs

      wrapProgram $out/opt/access/chrome-sandbox \
        --set SSL_CERT_FILE "/etc/ssl/certs/ca-certificates.crt" \
        --set SSL_CERT_DIR "/etc/ssl/certs" \
        --set ELECTRON_EXTRA_CA_CERTS "/etc/ssl/certs/ca-certificates.crt" \
        --set NODE_EXTRA_CA_CERTS "/etc/ssl/certs/ca-certificates.crt" \
        --add-flags "--ignore-certificate-errors" \
        --add-flags "--ignore-urlfetcher-cert-requests"

      # Wrap cgaccess so Electron sees certs
      wrapProgram $out/opt/access/cgaccess \
        --set ELECTRON_EXTRA_CA_CERTS "/etc/ssl/certs/ca-certificates.crt" \
        --set NODE_EXTRA_CA_CERTS "/etc/ssl/certs/ca-certificates.crt" \
        --set SSL_CERT_FILE "/etc/ssl/certs/ca-certificates.crt" \
        --set SSL_CERT_DIR "/etc/ssl/certs" \
        --add-flags "--ignore-certificate-errors" \
        --add-flags "--allow-insecure-localhost" \
        --add-flags "--test-type"

      ln -s $out/opt/access/.cgaccess-wrapped $out/bin/barracudavpn
    '';

    meta = with pkgs.lib; {
      description =
        "Access Tunnel VPN client (Cisco AnyConnect Barracuda fork)";
      license = licenses.unfree;
      platforms = platforms.linux;
    };
  };

  # FHSEnv
  cgaccessEnv = pkgs.buildFHSEnv {
    name = "cgaccess-env";
    targetPkgs = pkgs:
      with pkgs; [
        glibc
        systemd
        openssl
        nss
        nspr
        libnotify
        libappindicator-gtk3
        xdg-utils
        zlib
        dbus
        atk
        gtk3
        xorg.libX11
        xorg.libXcomposite
        xorg.libXdamage
        xorg.libXext
        xorg.libXfixes
        xorg.libXfixes
        xorg.libXrandr
        xorg.libXrender
        xorg.libxcb
        libxkbcommon
        libgbm
        libdrm
        expat
        mesa
        libGL
        alsa-lib
        cups
        udev
        adwaita-icon-theme
        gnome-themes-extra
        gtk3
        noto-fonts
        accessTunnel
        cgaccess
      ];

    # runScript = "/bin/barracudavpn";
    runScript = pkgs.writeShellScript "run-barracuda" ''
      #!/bin/sh
      # set FHS env PATH
      export PATH="$HOME/.local/bin:$PATH"

      # optionally set other vars
      export ACCESS_TUNNEL_BIN=$HOME/.local/bin/access-tunnel
      export ACCESS_INTERFACE_BIN=$HOME/.local/bin/access-interface

      cp $out/bin/access-tunnel $ACCESS_TUNNEL_BIN
      cp $out/bin/access-interface $ACCESS_INTERFACE_BIN

      ls -lah $ACCESS_TUNNEL_BIN
      ls -lah $ACCESS_INTERFACE_BIN

      # exec the actual binary
      exec /bin/barracudavpn "$@"
    '';

    extraMounts = [{
      source = "${cgaccess}/opt/access";
      target = "/opt/access";
      recursive = true;
    }];
  };

in {
  home.packages = with pkgs; [
    pkgs.cacert
    pkgs.libnotify
    pkgs.libappindicator-gtk2
    pkgs.xorg.libXtst
    pkgs.nss
    pkgs.xdg-utils
    cgaccessEnv
  ];

  home.activation.fydeSetup = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    echo "Barracuda adding group 'access'..."

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

    # ensure cache/config dirs exist
    for dir in ".cache/fyde/Caches" ".config/fyde/Shared"; do
      __TARGET="${config.home.homeDirectory}/$dir"
      if [ ! -d "$__TARGET" ]; then
        echo "Creating and fixing permissions for $__TARGET ..."
        mkdir -p "$__TARGET"
        /usr/bin/sudo chmod 777 "$__TARGET"
        /usr/bin/sudo chown "$(whoami):$(whoami)" -R "$__TARGET"
      fi
    done


    # set capabilities
    for bin in "$HOME/.local/bin/access-tunnel" "$HOME/.local/bin/access-interface"; do
      if ! /usr/sbin/getcap "$bin" | grep -q "cap_net_admin,cap_net_raw+ep"; then
        echo "Setting capabilities on $bin"
        /usr/bin/sudo /usr/sbin/setcap cap_net_admin,cap_net_raw+ep "$bin"
      else
        echo "✅ Capabilities already set on $bin"
      fi
    done
  '';

  home.activation.createAccessTunnelDeamon =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      echo "Writing the access daemon file..."

      __ACCESS_DAEMON_FILE="$HOME/.local/bin/access-daemon"
      cat > $__ACCESS_DAEMON_FILE << EOF
      #!/bin/sh
      set -e

      # Start access-interface first (the RPC backend)
      $HOME/.local/bin/access-interface -g access &

      sleep 1

      # Now start access-tunnel (depends on interface)
      $HOME/.local/bin/access-tunnel
      EOF

      if [ ! -d "$__ACCESS_DAEMON_FILE" ]; then
        /usr/bin/sudo chmod +x $__ACCESS_DAEMON_FILE
      fi

      echo "Writing systemd user service for access-tunnel..."

      mkdir -p $HOME/.config/systemd/user
      __TUNNEL_SERVICE_FILE="$HOME/.config/systemd/user/access-tunnel.service"
      cat > $__TUNNEL_SERVICE_FILE <<EOF
      [Unit]
      Description=Access Tunnel Daemon (Barracuda VPN)
      After=network.target

      [Service]
      ExecStart=$__ACCESS_DAEMON_FILE
      Restart=on-failure
      RestartSec=5s

      [Install]
      WantedBy=default.target
      EOF
    '';

  home.activation.startAccessTunnelService =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      # Remove old user-defined service
      echo "Stopping and removing systemd user service for access-tunnel..."
      /usr/bin/systemctl --user stop access-tunnel.service
      /usr/bin/systemctl --user disable access-tunnel.service

      # Reload user units
      echo "Adding and starting systemd user service for access-tunnel..."
      /usr/bin/systemctl --user daemon-reload
      /usr/bin/systemctl --user enable --now access-tunnel.service
      # journalctl --user -u access-tunnel.service -f
    '';
}

# IT WORKS!
# Manually stopping and restarting the daemon:
# systemctl --user stop access-tunnel.servic
# systemctl --user start access-tunnel.servic
# cgaccess-env
#
# IF it doesn't work, then try run the binaries:
# ~/.local/bin/access-interface &
# ~/.local/bin/access-tunnel
# and then run
# cgaccess-env

# --
# -- Note for safekeeping down below
# --

# -- ADD DEFINED USER SERVICE --

# stop and remove
# systemctl --user stop access-tunnel.service
# systemctl --user disable access-tunnel.service
# rm ~/.config/systemd/user/access-tunnel.service
# systemctl --user daemon-reload

# add and enable
# systemctl --user enable --now access-tunnel.service
# systemctl --user status access-tunnel.service
# journalctl --user -u access-tunnel.service -f

# -- CAPABILITIES --

# set capabilities
# for bin in "$ACCESS_TUNNEL_BIN" "$ACCESS_INTERFACE_BIN"; do
#   if ! /usr/sbin/getcap "$bin" | grep -q "cap_net_admin,cap_net_raw+ep"; then
#     echo "Setting capabilities on $bin"
#     /usr/bin/sudo /usr/sbin/setcap cap_net_admin,cap_net_raw+ep "$bin"
#   else
#     echo "✅ Capabilities already set on $bin"
#   fi
# done

# --- OLD ---

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

# -- More setup --

# Add Fyde desktop entry for cga:// handler
# xdg.mimeApps.defaultApplications = {
#   "x-scheme-handler/cga" =
#     "${cgaccess}/usr/share/applications/cgaccess.desktop";
# };

# Extra user setup
# home.sessionVariables = {
#   ACCESS_TUNNEL_BIN = "${cgaccessEnv}/bin/access-tunnel";
#   ACCESS_INTERFACE_BIN = "${cgaccessEnv}/bin/access-interface";
# };
