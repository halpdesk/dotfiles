# derivations/libalpm.nix
{ pkgs }:

pkgs.stdenv.mkDerivation rec {
  pname = "libalpm";
  version = "6.0.2"; # match your pacman version

  src = pkgs.fetchFromGitLab {
    domain = "gitlab.archlinux.org";
    owner = "pacman";
    repo = "pacman";
    rev = "v${version}";
    sha256 = "sha256-93SoFsR+zeIVXzzbbTgc8GwrsBxawxs5YSsFL+k0sHs=";
  };

  nativeBuildInputs =
    [ pkgs.autoconf pkgs.automake pkgs.libtool pkgs.pkg-config pkgs.gettext ];

  buildInputs = [ pkgs.gpgme pkgs.openssl pkgs.zlib ];

  configurePhase = ''
    ./autogen.sh
    ./configure --prefix=$out
  '';

  buildPhase = ''
    make -C lib/libalpm
  '';

  installPhase = ''
    mkdir -p $out/lib $out/include
    cp lib/libalpm/.libs/libalpm.so* $out/lib/
    cp lib/libalpm/*.h $out/include/
  '';

  meta = with pkgs.lib; {
    description = "Library for Arch Linux Package Management (ALPM)";
    homepage = "https://gitlab.archlinux.org/pacman/pacman";
    license = licenses.gpl2Plus;
    maintainers = [ ];
  };
}
