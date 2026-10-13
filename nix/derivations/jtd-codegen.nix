{ config, pkgs, lib, ... }:

# unstable = import <nixpkgs-unstable> { };

pkgs.stdenv.mkDerivation {
  pname = "jtd-codegen";
  version = "0.4.1";
  src = pkgs.fetchurl {
    url =
      "https://github.com/jsontypedef/json-typedef-codegen/releases/download/v0.4.1/x86_64-unknown-linux-musl.zip";
    sha256 = "sha256-+28QdYAZGYPeKO5/GGCANslTijeGBZKzYiSqq1212kw=";
  };
  nativeBuildInputs = [ pkgs.unzip ];
  unpackPhase = ''
    unzip $src -d .
  '';

  installPhase = ''
    mkdir -p $out/bin
    cp -r jtd-codegen $out/bin/jtd-codegen
  '';

  meta = with lib; {
    description = "JSON Typedef Code Generator CLI";
    platforms = platforms.linux;
  };
}
