{ config, pkgs, lib, ... }:

pkgs.stdenv.mkDerivation {
  pname = "cursor-cli";
  version = "latest";
  src = pkgs.fetchurl {
    url =
      "https://downloads.cursor.com/lab/2025.08.27-24c29c1/linux/x64/agent-cli-package.tar.gz";
    sha256 = "sha256-046NAHLckWOvIG5WJ8p3SNiUTbelEw2eTZ+/1DvTpNY=";
  };

  unpackPhase = ''
    mkdir source
    tar -xzf $src -C source
    ls -lah source/dist-package
  '';

  installPhase = ''
    mkdir -p $out/opt/cursor-cli
    cp -r source/dist-package/* $out/opt/cursor-cli/

    mkdir -p $out/bin
    ln -s $out/opt/cursor-cli/cursor-agent $out/bin/cursor-agent
  '';

  meta = with lib; {
    description = "Cursor CLI";
    homepage = "https://cursor.com";
    license = licenses.unfree;
    platforms = [ "x86_64-linux" ];
  };
}
