{ config, pkgs, lib, ... }:

let
  sdrangelQt6 = pkgs.sdrangel.overrideAttrs (old: {

    cmakeFlags = (old.cmakeFlags or [ ])
      ++ [ "-DENABLE_QT6=ON" "-DENABLE_FEATURE_MORSEDECODER=OFF" ];

    nativeBuildInputs = (old.nativeBuildInputs or [ ])
      ++ [ pkgs.qt6.wrapQtAppsHook ];

    # Ensure we stay entirely in Qt6
    buildInputs = (lib.filter (p: !(lib.hasPrefix "qtbase-5" (p.pname or "")))
      (old.buildInputs or [ ])) ++ [
        pkgs.qt6.qtbase
        pkgs.qt6.qttools
        pkgs.qt6.qtmultimedia
        pkgs.qt6.qtserialport
        pkgs.qt6.qtlocation
        pkgs.qt6.qtpositioning
        pkgs.qt6.qtcharts
      ];

    # Remove the private Qt dependency that fails under Qt6 in nixpkgs
    postPatch = (old.postPatch or "") + ''
      substituteInPlace sdrbase/CMakeLists.txt \
        --replace "Qt::CorePrivate" ""
    '';

  });
in { home.packages = with pkgs; [ sdrangelQt6 rtl-sdr soapysdr ]; }
