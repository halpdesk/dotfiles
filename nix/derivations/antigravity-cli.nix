{ config, pkgs, lib, ... }:

pkgs.stdenv.mkDerivation {
  pname = "antigravity-cli";
  version = "1.1.4";
  src = pkgs.fetchurl {
    url =
      "https://storage.googleapis.com/antigravity-public/antigravity-cli/1.1.4-6277569641840640/linux-x64/cli_linux_x64.tar.gz";
    sha256 = "1ynvmblg38x2zw20czwygagr8pc682ir92g8bbz3nknbjpil5axa";
  };

  sourceRoot = ".";

  installPhase = ''
    mkdir -p $out/bin
    install -Dm755 antigravity $out/bin/agy
  '';

  meta = with lib; {
    description = "Google Antigravity CLI";
    homepage = "https://antigravity.google";
    license = licenses.unfree;
    platforms = [ "x86_64-linux" ];
    mainProgram = "agy";
  };
}
