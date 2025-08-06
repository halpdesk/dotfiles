{ config, pkgs, users, lib, ... }:

let
  username = "halpdesk";
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
    (import ./modules/terminal.nix { inherit config pkgs username; })
    (import ./modules/observability.nix { inherit config pkgs username; })
    (import ./modules/tools.nix { inherit config pkgs username; })
    (import ./modules/devtools.nix {
      inherit config pkgs lib appsDir username email;
    })
  ];

  home.username = username;
  home.homeDirectory = "/home/${username}";
  home.stateVersion = "25.05"; # Do not change manually?

  home.sessionVariables = {
    EDITOR = defaultEditor;
    TZ = timezone;
    PATH = "$HOME/.nix-profile/bin:$HOME/.local/bin:$PATH";
    ZSH_THEME = "dracula";
    LC_ALL = "en_US.UTF-8";
    LANG = "en_US.UTF-8";
  };

  # home.packages = with pkgs; [ kdeFrameworks.kservice ];

  # XDG
  xdg.enable = true;
  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "x-scheme-handler/http" = "google-chrome.desktop";
      "x-scheme-handler/https" = "google-chrome.desktop";
      "application/pdf" = "google-chrome.desktop";
      "text/html" = "google-chrome.desktop";
      "text/plain" = "code.desktop";
      "application/json" = "code.desktop";
      "application/x-yaml" = "code.desktop";
      "application/x-python-code" = "code.desktop";
      "text/x-python" = "code.desktop";
      "text/x-go" = "code.desktop";
      "text/x-java-source" = "code.desktop";
      "text/javascript" = "code.desktop";
      "application/javascript" = "code.desktop";
      "text/x-typescript" = "code.desktop";
      "application/x-sh" = "code.desktop";
      "text/markdown" = "code.desktop";
      "text/x-c" = "code.desktop";
      "text/x-c++src" = "code.desktop";
      "text/x-cmake" = "code.desktop";
      "text/x-makefile" = "code.desktop";
      "text/x-shellscript" = "code.desktop";
      "application/x-php" = "code.desktop";
      "text/x-rustsrc" = "code.desktop";
      "text/x-scala" = "code.desktop";
      "text/x-kotlin" = "code.desktop";
      "text/x-lua" = "code.desktop";
      "text/x-sql" = "code.desktop";
      "image/jpeg" = "org.nomacs.ImageLounge.desktop";
      "image/png" = "org.nomacs.ImageLounge.desktop";
      "image/gif" = "org.nomacs.ImageLounge.desktop";
      "image/webp" = "org.nomacs.ImageLounge.desktop";
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

  home.activation.linkDesktopEntries =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      # Ensure ~/.local/share/applications exists
      mkdir -p "$HOME/.local/share/applications"

      # Define desktop entries you want to symlink
      for app in brave-browser.desktop google-chrome.desktop slack.desktop gimp.desktop code.desktop code-url-handler.desktop org.flameshot.Flameshot.desktop org.kde.konsole.desktop org.kde.yakuake.desktop vlc.desktop yazi.desktop org.nomacs.ImageLounge.desktop; do
        src="$HOME/.nix-profile/share/applications/$app"
        dest="$HOME/.local/share/applications/$app"

        if [ -f "$src" ] && [ ! -L "$dest" ]; then
          ln -s "$src" "$dest"
          echo "✅ Symlinked $app"
        fi
      done
    '';
}
