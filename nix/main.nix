{ config, pkgs, users, lib, ... }:

let
  username = "halpdesk";
  name = "Daniel Wiltshire Leppänen";
  companyEmail = "daniel@juni.co";
  email = "daniel.leppanen@gmail.com";
  home = "/home/${username}";
  timezone = "Europe/Stockholm";
  defaultEditor = "code";
  appsDir = "${home}/Apps";
  # backup sources from mounted drive
  sshSource = "/media/backup/ssh"; # ssh from old system
  awsSource = "/media/backup/aws"; # aws credentials from old system
  netrcSource = "/media/backup/.netrc"; # .netrc from old system
in {

  imports = [
    # (import ./modules/lamp.nix { inherit pkgs; })
    (import ./modules/cgaaccess.nix { inherit config pkgs lib; })
    (import ./terminal.nix { inherit config pkgs username; })
    (import ./observability.nix { inherit config pkgs username; })
    (import ./tools.nix { inherit config pkgs lib username; })
    (import ./devtools.nix {
      inherit config pkgs lib appsDir name companyEmail;
    })
  ];

  home.username = username;
  home.homeDirectory = "/home/${username}";
  home.stateVersion = "25.05"; # Do not change manually?

  nixpkgs.config = {
    allowBroken = false;
    allowUnfree = true;

    # Make all derivations use system certs instead of Nix's own
    sslCertFile = "/etc/ssl/certs/ca-certificates.crt";
    sslCertDir = "/etc/ssl/certs";
  };

  home.sessionVariables = {
    EDITOR = "nano";
    TZ = timezone;
    PATH =
      "$HOME/.nix-profile/bin:$HOME/.local/bin:$HOME/go/bin:$HOME/.npm-global/bin:$PATH";
    ZSH_THEME = "dracula";
    LC_ALL = "en_US.UTF-8";
    LANG = "en_US.UTF-8";
    GOPATH = "$HOME/go";
    GOPRIVATE = "gitlab.com/junitechnology/*";
    GO111MODULE = "on";
    # GOPROXY = "off";
    PKG_CONFIG_PATH =
      "${pkgs.vips.dev}/lib/pkgconfig:${pkgs.glib.dev}/lib/pkgconfig";
    SSL_CERT_DIR = "/etc/ssl/certs";
    SSL_CERT_FILE = "/etc/ssl/certs/ca-certificates.crt";
    ELECTRON_EXTRA_CA_CERTS = "/etc/ssl/certs/ca-certificates.crt";
    NODE_EXTRA_CA_CERTS = "/etc/ssl/certs/ca-certificates.crt";
  };
  home.sessionVariables.LD_LIBRARY_PATH = lib.makeLibraryPath [
    pkgs.glib
    pkgs.gobject-introspection
    pkgs.cairo
    pkgs.pango
    pkgs.harfbuzz
    pkgs.freetype
    pkgs.gdk-pixbuf
    pkgs.libffi
  ];

  # home.packages = with pkgs; [ kdeFrameworks.kservice ];

  # XDG
  xdg.enable = true;
  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "application/javascript" = "code.desktop";
      "application/json" = "code.desktop";
      "application/pdf" = "google-chrome.desktop";
      "application/x-php" = "code.desktop";
      "application/x-python-code" = "code.desktop";
      "application/x-sh" = "code.desktop";
      "application/x-yaml" = "code.desktop";
      "image/gif" = "org.nomacs.ImageLounge.desktop";
      "image/jpeg" = "org.nomacs.ImageLounge.desktop";
      "image/png" = "org.nomacs.ImageLounge.desktop";
      "image/webp" = "org.nomacs.ImageLounge.desktop";
      "text/html" = "google-chrome.desktop";
      "text/javascript" = "code.desktop";
      "text/markdown" = "code.desktop";
      "text/plain" = "code.desktop";
      "text/x-c" = "code.desktop";
      "text/x-cmake" = "code.desktop";
      "text/x-c++src" = "code.desktop";
      "text/x-go" = "code.desktop";
      "text/x-java-source" = "code.desktop";
      "text/x-kotlin" = "code.desktop";
      "text/x-lua" = "code.desktop";
      "text/x-makefile" = "code.desktop";
      "text/x-python" = "code.desktop";
      "text/x-rustsrc" = "code.desktop";
      "text/x-scala" = "code.desktop";
      "text/x-shellscript" = "code.desktop";
      "text/x-sql" = "code.desktop";
      "text/x-typescript" = "code.desktop";
      "x-scheme-handler/http" = "google-chrome.desktop";
      "x-scheme-handler/https" = "google-chrome.desktop";
      "x-scheme-handler/magnet" = "userapp-transmission-gtk-B138A3.desktop";
      "x-scheme-handler/slack" = "slack.desktop;Slack.desktop";
      "x-scheme-handler/cga" = "fyde-enroller.desktop";
    };
  };

  # POST SCRIPTS
  # copy old ssh files
  home.activation.copySshFiles = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ ! -f "${config.home.homeDirectory}/.ssh/.is_copied" ]; then
      if [ -d "${sshSource}" ]; then
        echo "Copying SSH files from ${sshSource} to ~/.ssh ..."
        mkdir -p "${config.home.homeDirectory}/.ssh"

        # Copy everything except known_hosts
        for file in "${sshSource}"/*; do
          if [ "$(basename "$file")" != "known_hosts" ]; then
            cp -av "$file" "${config.home.homeDirectory}/.ssh/"
          fi
        done

        # Merge known_hosts if it exists
        if [ -f "${sshSource}/known_hosts" ]; then
          touch "${config.home.homeDirectory}/.ssh/known_hosts"
          while IFS= read -r line; do
            grep -qxF "$line" "${config.home.homeDirectory}/.ssh/known_hosts" || echo "$line" >> "${config.home.homeDirectory}/.ssh/known_hosts"
          done < "${sshSource}/known_hosts"
        fi

        # Fix permissions
        chmod 700 "${config.home.homeDirectory}/.ssh"
        find "${config.home.homeDirectory}/.ssh" -type d -exec chmod 700 {} \;
        find "${config.home.homeDirectory}/.ssh" -type f -exec chmod 600 {} \;

        touch "${config.home.homeDirectory}/.ssh/.is_copied"
        echo "✅ SSH files copied and known_hosts merged."
      else
        echo "⚠️  SSH backup folder not found at ${sshSource}"
      fi
    else
      echo "✅ SSH files already copied (marker exists)."
    fi
  '';

  # Copy .netrc file
  home.activation.copyNetrcFile = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    NETRC_TARGET="${config.home.homeDirectory}/.netrc"
    NETRC_SOURCE="${netrcSource}" # Define this in home.nix or pass it in

    if [ ! -f "$NETRC_TARGET" ]; then
      if [ -f "$NETRC_SOURCE" ]; then
        echo "Copying .netrc from $NETRC_SOURCE ..."
        cp -av "$NETRC_SOURCE" "$NETRC_TARGET"

        chmod 600 "$NETRC_TARGET"
        echo "✅ .netrc copied with secure permissions."
      else
        echo "⚠️  .netrc source not found at $NETRC_SOURCE"
      fi
    else
      echo "✅ .netrc already exists, skipping copy."
    fi
  '';

  # Copy aws credentials
  home.activation.copyAwsFiles = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    AWS_TARGET="${config.home.homeDirectory}/.aws"
    AWS_SOURCE="${awsSource}" # Define this in home.nix or pass it in

    if [ ! -f "$AWS_TARGET/.is_copied" ]; then
      if [ -d "$AWS_SOURCE" ]; then
        echo "Copying AWS credentials from $AWS_SOURCE to $AWS_TARGET ..."
        mkdir -p "$AWS_TARGET"

        cp -av "$AWS_SOURCE"/* "$AWS_TARGET/"

        chmod 700 "$AWS_TARGET"
        find "$AWS_TARGET" -type d -exec chmod 700 {} \;
        find "$AWS_TARGET" -type f -exec chmod 600 {} \;

        touch "$AWS_TARGET/.is_copied"
        echo "✅ AWS credentials copied with secure permissions."
      else
        echo "⚠️  AWS source folder not found at $AWS_SOURCE"
      fi
    else
      echo "✅ AWS credentials already copied (marker exists)."
    fi
  '';

  home.activation.linkApplicationsAndIcons =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      src="$HOME/.nix-profile/share"
      dest="$HOME/.local/share"

      mkdir -p "$dest"

      for dir in applications icons mime pixmaps; do
        if [ -d "$src/$dir" ]; then
          mkdir -p "$dest/$dir"
          for f in "$src/$dir"/*; do
            bn=$(basename "$f")
            if [ -e "$dest/$dir/$bn" ]; then
              continue
            fi
            ln -s "$f" "$dest/$dir/$bn"
            echo "✅ Linked $dir/$bn"
          done
        fi
      done

      # Rebuild KDE system config cache
      kbuildsycoca6 --noincremental || true
    '';
}
