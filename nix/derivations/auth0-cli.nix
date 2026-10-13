{ config, pkgs, lib, ... }:

# Auth0 CLI for managing Auth0 tenants from the command line.
# Docs: https://auth0.com/docs/deploy-monitor/auth0-cli
# Releases: https://github.com/auth0/auth0-cli/releases
pkgs.stdenv.mkDerivation {
  pname = "auth0-cli";
  version = "1.30.0";
  src = pkgs.fetchurl {
    url =
      "https://github.com/auth0/auth0-cli/releases/download/v1.30.0/auth0-cli_1.30.0_Linux_x86_64.tar.gz";
    sha256 = "sha256-+sRkgZUaUcziGpQ78y1OGVU6v/KvygjwfAT8KUQxXGg=";
  };

  unpackPhase = ''
    mkdir source
    tar -xzf $src -C source
  '';

  installPhase = ''
    mkdir -p $out/bin
    install -m755 source/auth0 $out/bin/auth0
  '';

  meta = with lib; {
    description = "Auth0 CLI for tenant management";
    homepage = "https://github.com/auth0/auth0-cli";
    license = licenses.mit;
    platforms = [ "x86_64-linux" ];
    mainProgram = "auth0";
  };
}
