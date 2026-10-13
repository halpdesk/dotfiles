{ pkgs, lib, cursorTmpDir }:

pkgs.stdenv.mkDerivation rec {
  pname = "cursor";
  version = "3.24.12";

  src = pkgs.fetchurl {
    url =
      "https://downloads.cursor.com/production/37b865941ccb31e2fc90c685157534efca87f964/linux/x64/deb/amd64/deb/cursor_${version}_amd64.deb";
    sha256 = "sha256-iAtbac1s1530uBp3jqHzQpqvd153GqtsGcaI3haidfQ=";
  };

  nativeBuildInputs = [ pkgs.makeWrapper pkgs.dpkg ];

  unpackPhase = ''
    dpkg-deb --fsys-tarfile $src | tar x --no-same-permissions --no-same-owner
  '';

  buildPhase = ":";

  installPhase = ''
    mkdir -p $out
    cp -r usr/* $out/

    chmod +x $out/share/cursor/cursor
    chmod +x $out/share/cursor/bin/cursor

    mkdir -p $out/bin
    wrapProgram $out/share/cursor/cursor \
      --set TMPDIR ${lib.escapeShellArg cursorTmpDir} \
      --run ${lib.escapeShellArg "mkdir -p -- \"$TMPDIR\""} \
      --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath [
        pkgs.gtk3
        pkgs.glib
        pkgs.pango
        pkgs.atk
        pkgs.cups
        pkgs.xorg.libX11
        pkgs.xorg.libXcursor
        pkgs.xorg.libXrandr
        pkgs.xorg.libXcomposite
        pkgs.xorg.libXi
        pkgs.xorg.libXtst
        pkgs.nss
        pkgs.freetype
        pkgs.libxkbcommon
        pkgs.dbus
        pkgs.libsecret
        pkgs.alsa-lib
        pkgs.mesa
        pkgs.libdrm
        pkgs.libGL
        pkgs.xorg.libxcb
      ]}
    ln -sf $out/share/cursor/bin/cursor $out/bin/cursor
  '';

  meta = with lib; {
    description = "Cursor - AI code editor";
    homepage = "https://cursor.com/";
    license = licenses.unfree;
    platforms = [ "x86_64-linux" ];
  };
}
