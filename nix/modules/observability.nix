{ config, pkgs, username, ... }:

{

  home.packages = with pkgs; [
    # monitoring
    glances # System monitor with curses UI
    btop # Resource monitor (CPU, RAM, disk, network) - modern and beautiful
    htop # Interactive process viewer
    iftop # Network usage per interface
    duf # Disk usage with a modern UI
    dool # Versatile resource monitor
    dua # Disk usage analyzer
    procs # Modern `ps` replacement with table view
    dust # Intuitive disk usage analyzer
    bottom # System monitor like btop, written in Rust
    ncdu

    # requires root
    # powertop
    # iotop
    # bandwhich       # Display network usage per process
  ];
}
