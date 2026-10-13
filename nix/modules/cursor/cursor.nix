{ config, pkgs, lib, ... }:

let
  # Cursor's sandbox cache is path.join(os.tmpdir(), "cursor-sandbox-cache").
  # Default tmpdir is /tmp (tmpfs here), so the cache sits in RAM. Keep it
  # on disk instead. Desktop and `cursor` CLI both exec this wrapped binary.
  cursorTmpDir = "${config.home.homeDirectory}/.cache/cursor-tmp";
  cursorPkg = pkgs.callPackage ./cursor-package.nix { inherit cursorTmpDir; };
  cursorBin = "${cursorPkg}/bin/cursor";
  cursorIcon = pkgs.fetchurl {
    url =
      "https://cursor.com/_next/image?url=%2F_next%2Fstatic%2Fmedia%2Flogo-light.636eeb83.png&w=3840&q=100";
    sha256 =
      "sha256-MZll0bono6v07M5qbWhLhvexIUa6MQxG+WLsgnXAA4g="; # use `nix-prefetch-url` to get correct hash
  };
  desktopFile = ''
    [Desktop Entry]
    Name=Cursor
    Comment=AI-powered code editor
    Exec=${cursorBin}
    Icon=${cursorIcon}
    Terminal=false
    Type=Application
    Categories=Development;IDE;
  '';

  cursorOnlySettings = {
    "cursor.ai.model" = "gpt-4.1";
    "cursor.ai.autocomplete" = true;
  };

  vscodeSettings = config.programs.vscode.profiles.default.userSettings or { };

  mergedSettings = lib.recursiveUpdate vscodeSettings cursorOnlySettings;

  cursorSettings = builtins.toJSON mergedSettings;

  # VS Code-only extensions: these are deliberately not shared into Cursor.
  cursorExcludedExtensions = [ "anthropic.claude-code" ];

  sharedExtensions =
    lib.filter (ext: !lib.elem ext.vscodeExtUniqueId cursorExcludedExtensions)
    (config.programs.vscode.profiles.default.extensions or [ ]);

  # Cursor reads its extension directory the way VS Code does: one directory
  # per extension, which it indexes into its own extensions.json. Linking them
  # individually is what makes an exception possible at all — a single
  # directory symlink cannot exclude one member.
  cursorExtensionLinks = lib.listToAttrs (map (ext: {
    name = ".cursor/extensions/${ext.vscodeExtUniqueId}";
    value.source = "${ext}/share/vscode/extensions/${ext.vscodeExtUniqueId}";
  }) sharedExtensions);
in {

  home.packages = [ cursorPkg ];

  home.file = lib.mkMerge [
    cursorExtensionLinks
    {
      ".config/Cursor/User/keybindings.json".source =
        "${config.home.homeDirectory}/.config/Code/User/keybindings.json";

      ".config/Cursor/User/snippets".source =
        "${config.home.homeDirectory}/.config/Code/User/snippets";

      ".config/Cursor/User/settings.json".text = cursorSettings;
    }
  ];

  # Earlier generations made ~/.cursor/extensions one symlink into the store.
  # Home Manager will not replace a symlink with a directory, so drop it —
  # but only when it is exactly that, a store symlink this repo created.
  home.activation.cursorExtensionsDir =
    lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
      cursorExtDir="$HOME/.cursor/extensions"
      if [ -L "$cursorExtDir" ]; then
        case "$(readlink "$cursorExtDir")" in
        /nix/store/*) run rm -- "$cursorExtDir" ;;
        esac
      fi
    '';

  # The previous generation enabled Home Manager's GNOME Keyring service.
  # This host runs KDE Plasma and already has KWallet 6; the GNOME daemon
  # claimed org.freedesktop.secrets without a usable default collection.
  # Stop only the exact store-backed unit that this module created. Once Home
  # Manager removes that obsolete link, later activations are no-ops.
  home.activation.cursorRemoveLegacyGnomeKeyring =
    lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
      keyringUnit="$HOME/.config/systemd/user/gnome-keyring.service"
      if [ -L "$keyringUnit" ]; then
        case "$(readlink "$keyringUnit")" in
        /nix/store/*-gnome-keyring.service/gnome-keyring.service)
          run systemctl --user stop gnome-keyring.service
          ;;
        esac
      fi
    '';

  # Cursor sandbox cache lives here (see cursorTmpDir). Create only; never
  # delete existing contents — agents refill it on demand.
  home.activation.cursorTmpDir = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p "$HOME/.cache/cursor-tmp"
    chmod 700 "$HOME/.cache/cursor-tmp"
  '';

  # Activation: create desktop entry and icon
  home.activation.cursorDesktop = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p "$HOME/.local/share/applications"
    mkdir -p "$HOME/.local/share/icons/hicolor/128x128/apps"

    # Write desktop file
    echo "${desktopFile}" > "$HOME/.local/share/applications/cursor.desktop"
    chmod 644 "$HOME/.local/share/applications/cursor.desktop"

    # Copy icon if exists
    #if [ -f "${cursorIcon}" ]; then
    #  cp "${cursorIcon}" "$HOME/.local/share/icons/hicolor/128x128/apps/cursor.png"
    #fi

    # Rebuild KDE / GNOME icon cache if needed
    command -v kbuildsycoca6 >/dev/null && kbuildsycoca6 --noincremental || true
  '';
}
