{ config, pkgs, lib, ... }:

let
  python = pkgs.python313;

  weasyprint = python.pkgs.buildPythonPackage rec {
    pname = "WeasyPrint";
    version = "62.3";

    src = pkgs.fetchurl {
      url =
        "https://files.pythonhosted.org/packages/1c/d1/10f4225bec3450e7c0aa5813697ce76eb2dfa1f3c5e530510253b6b276b2/weasyprint-62.3-py3-none-any.whl";
      sha256 = "sha256-0xBIZGzhUIThNbM+M0ph9SaqaNL2efzBCe0OD17a7SE=";
    };

    # version = "57.2";

    # src = pkgs.fetchurl {
    #   url =
    #     "https://files.pythonhosted.org/packages/3b/ec/b18f3ea0674bc4a1aab14c9c907575d1150bb4bf55a02f3567472200aa8a/weasyprint-57.2-py3-none-any.whl";
    #   sha256 = "aFaS56K0rsIQEKYcHo8dbNYR3UZQn6cGj8yjyOWalPU=";
    # };

    format = "wheel";

    propagatedBuildInputs = with python.pkgs; [
      cffi
      pydyf
      pyphen
      tinycss2
      cssselect2
      cairocffi
      cairosvg
      pillow
      html5lib
      fonttools
    ];

    nativeBuildInputs = [ pkgs.wrapGAppsHook3 ];
    buildInputs = with pkgs; [
      cairo
      pango
      gdk-pixbuf
      glib
      fontconfig
      freetype
      harfbuzz
    ];
  };
in pkgs.stdenv.mkDerivation {
  pname = "weasyprint-env";
  version = weasyprint.version;

  nativeBuildInputs = [ pkgs.makeWrapper pkgs.wrapGAppsHook3 ];
  buildInputs = with pkgs; [
    cairo
    pango
    gdk-pixbuf
    glib
    fontconfig
    freetype
    harfbuzz
  ];

  unpackPhase = "true";
  installPhase = ''
    mkdir -p $out/bin
    makeWrapper "${weasyprint}/bin/weasyprint" "$out/bin/weasyprint" \
      --prefix LD_LIBRARY_PATH : "${
        pkgs.lib.makeLibraryPath [
          pkgs.glib
          pkgs.cairo
          pkgs.pango
          pkgs.gdk-pixbuf
          pkgs.fontconfig
          pkgs.freetype
          pkgs.harfbuzz
        ]
      }" \
      "''${gappsWrapperArgs[@]}"
  '';
}
