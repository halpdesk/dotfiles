{ config, pkgs, username, ... }:

let

  # Konsole color profile

  # ZSH
  dracula-zsh-theme = pkgs.fetchFromGitHub {
    owner = "dracula";
    repo = "zsh";
    rev = "v1.2.5"; # Use a specific commit for reproducibility
    sha256 = "sha256-4lP4++Ewz00siVnMnjcfXhPnJndE6ANDjEWeswkmobg=";
  };

  myOhMyZsh = pkgs.oh-my-zsh.overrideAttrs (oldAttrs: {
    postInstall = ''
      ${oldAttrs.postInstall or ""}
      cp ${dracula-zsh-theme}/dracula.zsh-theme $out/share/oh-my-zsh/themes/dracula.zsh-theme
    '';
  });

  # VSCODE
  #dracula-vscode-theme = pkgs.fetchFromGitHub {
  #  owner = "dracula";
  #  repo = "zsh";
  #  rev = "v2.24.3";  # Use a specific commit for reproducibility
  #  sha256 = "sha256-4lP4++Ewz00siVnMnjcfXhPnJndE6ANDjEWeswkmobg=";
  #};

  #myVsCode = pkgs.vscode.overrideAttrs (oldAttrs: {
  #  postInstall = ''
  #    ${oldAttrs.postInstall or ""}
  #    cp ${dracula-vscode-theme}/dracula.zsh-theme $out/share/oh-my-zsh/themes/dracula.zsh-theme
  #  '';
  #});

in {
  home.packages = with pkgs; [
    # shell
    kdePackages.konsole
    kdePackages.yakuake
    zsh
    grc
  ];

  # Konsole
  home.file.".local/share/konsole/Dracula.colorscheme".source = pkgs.fetchurl {
    url =
      "https://raw.githubusercontent.com/dracula/konsole/master/Dracula.colorscheme";
    sha256 =
      "12sykj46w6gixaibfhaz247va4r36kagch8wx71az0mpg563m4yd"; # Update via `nix-prefetch-url <URL>`
  };

  home.file.".local/share/konsole/Shell.profile".text = ''
    [Appearance]
    ColorScheme=Dracula

    [General]
    Name=Shell
    Command=${config.programs.zsh.package}/bin/zsh
  '';

  home.file.".config/konsolerc".text = ''
    [Desktop Entry]
    DefaultProfile=Shell.profile
  '';

  home.file.".tmux/plugins/tpm".source = pkgs.fetchFromGitHub {
    owner = "tmux-plugins";
    repo = "tpm";
    rev = "v3.1.0"; # specific commit for reproducibility
    sha256 = "sha256-CeI9Wq6tHqV68woE11lIY4cLoNY8XWyXyMHTDmFKJKI";
  };

  home.file.".tmux-startup-layout.sh" = {
    text = ''
      #!/usr/bin/env bash
      SESSION="main"

      # Create session only if it doesn't exist
      tmux has-session -t $SESSION 2>/dev/null

      if [ $? != 0 ]; then
        # Start new session in detached mode
        tmux new-session -d -s $SESSION -c "$PWD"

        # Create panes
        tmux split-window -h -t $SESSION:0.0
        tmux split-window -v -t $SESSION:0.1

        # Return focus to left pane
        tmux select-pane -t $SESSION:0.0
      fi
    '';
    executable = true;
  };

  # Zsh
  programs.zsh = {
    enable = true;
    syntaxHighlighting.enable = true;
    history.size = 10000;

    shellAliases = {
      update = "home-manager switch";

      # terminal
      ll = "eza -lah --color=auto";
      ls = "ls --color=auto";
      grep = "grep --color=auto";
      cat = "bat --style plain,header-filename,header-filesize,grid";
      tmain = "tmux attach -t main";

      # git
      huh = "git diff";
      wow = "git add .";
      wtf = "git status";
      such = "git commit -m";
      omg = "git push origin";
      omfg = "git push --force origin";
      ga = "git add";
      fu = "git commit --amend --no-edit";
      gpo = "git pull origin";
      out = "git checkout";
      greb2 = "git rebase -i HEAD~2";
      gitauthors = "git log --format='%C(Magenta)%aN' | sort -u";

      # build
      make = "grc make";
    };

    oh-my-zsh = {
      package = myOhMyZsh;
      enable = true;
      plugins = [ "git" ];
      theme = "dracula";
    };

    initContent = ''
      # enables completion system including command name completion
      autoload -Uz compinit
      compinit

      # Only auto-start tmux if not already inside one
      if command -v tmux &> /dev/null && [ -z "$TMUX" ]; then
        ~/.tmux-startup-layout.sh
        tmux attach -t main
      fi
    '';
  };

  #
  home.file.".zprofile".text = ''
    # Custom made zprofile - loads on login shells

    file="$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh"
    if [ -f "$file" ]; then
      export __HM_SESS_VARS_SOURCED=
      source "$file"
      hash -r
    fi

    # forces zsh to rescan the PATH for new executables.
    rehash

    echo "# Logged in"
  '';

  # Tmux
  programs.tmux = {
    enable = true;
    terminal = "screen-256color";
    clock24 = true;
    extraConfig = ''
      # Core bindings
      unbind '"'
      unbind %
      unbind -n s
      set -g prefix C-b
      bind C-b send-prefix
      bind r source-file ~/.config/tmux/.tmux.conf \; display "Config reloaded!"

      # Pane bindings
      bind "'" split-window -h
      bind - split-window -v
      bind M-Left select-pane -L
      bind M-Right select-pane -R
      bind M-Up select-pane -U
      bind M-Down select-pane -D
      bind s split-window
      bind q kill-pane
      bind Q detach
      bind W resize-pane -U 2
      bind A resize-pane -L 2
      bind S resize-pane -D 2
      bind D resize-pane -R 2

      # Behaviour
      set -g history-limit 8000
      set -g mouse on
      set-option -g allow-rename off # do not rename automatically

      # Color settings
      set -g default-terminal "screen-256color"
      set-option -g status-interval 2
      set-option -g status-justify centre
      set-option -g status on
      set-option -g status-style bg=#21222C,fg=#F8F8F2

      # Active window
      setw -g window-status-current-style bg=#44475A,fg=#F8F8F2
      setw -g window-status-current-format " #I:#W "

      # Inactive windows
      setw -g window-status-style bg=#21222C,fg=#6272A4
      setw -g window-status-format " #I:#W "

      # Pane borders
      set-option -g pane-border-style fg=#44475A
      set-option -g pane-active-border-style fg=#BD93F9

      # Message
      set-option -g message-style bg=#BD93F9,fg=#21222C

      # Command prompt
      set-option -g message-command-style bg=#50FA7B,fg=#21222C

      # Status Left
      set-option -g status-left-length 60
      set-option -g status-left "#[fg=#8BE9FD,bg=#21222C,bold] #S #[default]"

      # Status Right (time and date)
      set-option -g status-right-length 90
      set-option -g status-right "#[fg=#FF79C6] %Y-%m-%d #[fg=#50FA7B] %H:%M #[default]"

      # Clock mode
      set-window-option -g clock-mode-colour "#FFB86C"
      set-window-option -g clock-mode-style 24

      # TPM plugin manager
      set -g @plugin 'tmux-plugins/tpm'
      set -g @plugin 'tmux-plugins/tmux-sensible'
      set -g @plugin 'tmux-plugins/tmux-resurrect'
      set -g @plugin 'tmux-plugins/tmux-continuum'

      # Dracula
      set -g @plugin 'dracula/tmux'
      set -g @dracula-show-battery true
      set -g @dracula-show-powerline true
      set -g @dracula-show-timezone false
      set -g @dracula-weather-unit c
      set -g @dracula-refresh-rate 10
      set -g @dracula-show-weather false
      set -g @dracula-location "Stockholm, Sweden"

      # Auto-install plugins if missing
      run-shell '~/.tmux/plugins/tpm/bin/install_plugins'

      # Initialize TPM
      run '~/.tmux/plugins/tpm/tpm'
    '';
  };

}

