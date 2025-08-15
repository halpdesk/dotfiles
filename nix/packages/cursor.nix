{ config, pkgs, lib, ... }:

let
  cursorVersion = "1.4.2";
  cursorAppImage = pkgs.fetchurl {
    url =
      "https://downloads.cursor.com/production/d01860bc5f5a36b62f8a77cd42578126270db343/linux/x64/Cursor-${cursorVersion}-x86_64.AppImage";
    sha256 = "sha256-WMZA0CjApcSTup4FLIxxaO7hMMZrJPawYsfCXnFK4EE=";
  };
in pkgs.stdenv.mkDerivation {
  pname = "cursor";
  version = cursorVersion;

  src = cursorAppImage;

  nativeBuildInputs = [ pkgs.makeWrapper ];

  # skip unpacking
  unpackPhase = ":";

  buildPhase = ''
    mkdir -p $out/opt/cursor
    cp $src $out/opt/cursor/cursor.AppImage
    chmod +x $out/opt/cursor/cursor.AppImage
  '';

  installPhase = ''
    mkdir -p $out/bin
    wrapProgram $out/opt/cursor/cursor.AppImage \
      --prefix LD_LIBRARY_PATH : ${pkgs.gtk3.out}/lib:${pkgs.glib.out}/lib:${pkgs.pango.out}/lib:${pkgs.atk.out}/lib
    ln -s $out/opt/cursor/cursor.AppImage $out/bin/cursor
  '';

  buildInputs = [
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
  ];

  meta = with lib; {
    description = "Cursor - AI code editor";
    homepage = "https://cursor.com";
    license = licenses.unfree;
    platforms = [ "x86_64-linux" ];
  };
}
