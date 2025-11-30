{ pkgs, pyalpm }:

pkgs.python3.pkgs.buildPythonPackage rec {
  pname = "namcap";
  version = "3.2.7";

  src = pkgs.fetchurl {
    url =
      "https://ftp.ludd.ltu.se/pub/archlinux/other/packages/namcap/namcap-3.2.7.tar.gz";
    sha256 = "sha256-0Q/kLbG+rZdH1yhUGdbotFcjfppnZONwSoHwHU49FS0";
  };

  format = "setuptools"; # legacy setup.py style

  # Correct way to reference setuptools inside python3
  propagatedBuildInputs =
    [ pkgs.python3.pkgs.setuptools pkgs.python3Packages.pyelftools pyalpm ];

  meta = with pkgs.lib; {
    description = "A tool for checking Arch Linux packages";
    license = licenses.gpl3;
    maintainers = [ maintainers.yourname ];
  };
}
