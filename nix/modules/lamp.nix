{ pkgs, ... }:

{
  home.packages =
    [ pkgs.apacheHttpd pkgs.php pkgs.php.phpExtensions.mysqli pkgs.mariadb ];
}
