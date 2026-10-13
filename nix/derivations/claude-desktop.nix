{ pkgs, lib, ... }:

# Claude Desktop for Linux (beta). Anthropic ships it only through an apt
# repository, so `version` must be bumped against the pool index:
#
#   curl -s https://downloads.claude.ai/claude-desktop/apt/stable/dists/stable/main/binary-amd64/Packages \
#     | grep '^Version:' | sort -V | tail -1
#
# The .deb's postinst would register that apt repo and enable an in-app
# updater. Only the data tarball is unpacked here, so neither happens and Nix
# stays the single source of truth for the installed version.

pkgs.stdenv.mkDerivation rec {
  pname = "claude-desktop";
  version = "1.49585.0";

  src = pkgs.fetchurl {
    url =
      "https://downloads.claude.ai/claude-desktop/apt/stable/pool/main/c/claude-desktop/claude-desktop_${version}_amd64.deb";
    sha256 = "sha256-4LTOYxOUOmnpvWF0mik7/KJBtN+zf4jfZBG0tp7GekA=";
  };

  # libgbm and libudev are deliberately absent from LD_LIBRARY_PATH below and
  # left to resolve from the host. Nix's libgbm looks for DRI drivers under
  # /run/opengl-driver/lib/gbm, which does not exist on Arch, so shadowing the
  # system copy costs GPU acceleration; and a second libudev buys nothing when
  # the host's already matches the running udev.
  nativeBuildInputs = [ pkgs.makeWrapper pkgs.dpkg ];

  unpackPhase = ''
    dpkg-deb --fsys-tarfile $src | tar x --no-same-permissions --no-same-owner
  '';

  buildPhase = ":";

  installPhase = ''
    mkdir -p $out
    cp -r usr/* $out/
    rm -rf $out/share/lintian $out/share/doc

    chmod +x $out/lib/claude-desktop/claude-desktop

    # usr/bin/claude-desktop is a relative symlink into ../lib, so it keeps
    # resolving inside $out and points at the wrapper created below.
    wrapProgram $out/lib/claude-desktop/claude-desktop \
      --prefix PATH : ${lib.makeBinPath [ pkgs.xdg-utils ]} \
      --prefix LD_LIBRARY_PATH : ${
        lib.makeLibraryPath [
          pkgs.gtk3
          pkgs.glib
          pkgs.pango
          pkgs.cairo
          pkgs.gdk-pixbuf
          pkgs.atk
          pkgs.at-spi2-atk
          pkgs.at-spi2-core
          pkgs.cups
          pkgs.expat
          pkgs.fontconfig
          pkgs.freetype
          pkgs.libnotify
          pkgs.libsecret
          pkgs.libuuid
          pkgs.libxkbcommon
          pkgs.dbus
          pkgs.alsa-lib
          pkgs.libdrm
          pkgs.libGL
          pkgs.nss
          pkgs.nspr
          pkgs.xorg.libX11
          pkgs.xorg.libxcb
          pkgs.xorg.libXcomposite
          pkgs.xorg.libXcursor
          pkgs.xorg.libXdamage
          pkgs.xorg.libXext
          pkgs.xorg.libXfixes
          pkgs.xorg.libXi
          pkgs.xorg.libXrandr
          pkgs.xorg.libXtst
        ]
      }

    # The packaged entry assumes a system install and calls the bare name.
    # Upstream renamed this file once already (claude-desktop.desktop ->
    # com.anthropic.Claude.desktop), so match by glob rather than by name —
    # but still fail if no entry ships at all.
    shopt -s nullglob
    entries=($out/share/applications/*.desktop)
    if [ ''${#entries[@]} -eq 0 ]; then
      echo "claude-desktop: upstream package shipped no .desktop entry" >&2
      exit 1
    fi
    for entry in "''${entries[@]}"; do
      substituteInPlace "$entry" \
        --replace-fail "Exec=claude-desktop" "Exec=$out/bin/claude-desktop"
    done
  '';

  meta = with lib; {
    description = "Claude Desktop - Chat, Cowork and Claude Code in one app";
    homepage = "https://claude.com/download";
    license = licenses.unfree;
    platforms = [ "x86_64-linux" ];
    mainProgram = "claude-desktop";
  };
}
