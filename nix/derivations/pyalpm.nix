{ pkgs, libalpm }:

pkgs.python3Packages.buildPythonPackage rec {
  pname = "pyalpm";
  version = "6.0.2";

  src = pkgs.fetchFromGitLab {
    domain = "gitlab.archlinux.org";
    owner = "archlinux";
    repo = "pyalpm";
    rev = "0.10.12"; # tag name
    sha256 = "sha256-mZGz0zCLKVxZgi09C0g0pwZdgpmuU0s3wjCzmOOjYd8=";
  };

  # tell Nix it’s setuptools/legacy setup.py
  format = "setuptools";

  nativeBuildInputs = [ pkgs.python3.pkgs.setuptools pkgs.pkg-config ];

  # make sure Python bindings find libalpm
  buildInputs = [ libalpm ];

  # point the build to libalpm include/lib dirs via environment
  buildPhase = ''
    export ALPM_INCLUDE_DIR=${libalpm}/include
    export ALPM_LIB_DIR=${libalpm}/lib
    python3 setup.py build
  '';

  installPhase = ''
    python3 setup.py install --prefix=$out
  '';

  meta = with pkgs.lib; {
    description = "Python bindings for libalpm";
    license = licenses.gpl2;
  };
}
