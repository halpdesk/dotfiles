{ config, pkgs, lib, appsDir, username, email, ... }:

{
  home.packages = with pkgs; [
    # IDEs
    vscode

    # cli tools
    gitui # TUI for git workflows
    git # code revision
    jq # JSON CLI processor
    #yq # YAML CLI processor
    yq-go # version 4?
    fx # JSON visualizer
    miller # Like awk/sed/cut/jq for CSV and TSV files
    hexyl # Beautiful hex viewer
    choose # Cut/awk alternative
    hyperfine # Benchmarking CLI commands

    # nix
    nil # nix language server
    nixfmt-classic # nix formatter

    # Build tools
    gnumake
    gcc
    binutils
    zlib

    # golang
    go
    gopls # Go language server
    gofumpt # Better gofmt
    golangci-lint # Linter
    protobuf # protoc compiler
    buf # popular linter and formatter
    go-protobuf # protoc-gen-go

    # node and js
    nodejs
    nodePackages.typescript
    nodePackages.ts-node

    # python
    python3
    python3Packages.python-lsp-server # pyls form (popular)
    python3Packages.black # Formatter
    python3Packages.pylint # Linter

    # haskell
    haskell.compiler.ghc96 # or ghc98 for the latest stable
    haskellPackages.cabal-install # cabal
    haskellPackages.stack # stack (optional)
    haskell-language-server # optional, for editor support

    # Cloud and container tools
    awscli2
    google-cloud-sdk
    kubectl
    k9s
    helm
    docker
    docker-compose
  ];

  programs.git = {
    enable = true;

    userName = username;
    userEmail = email;

    extraConfig = {
      init.defaultBranch = "main";
      i18n.commitEncoding = "utf-8";
      i18n.logOutputEncoding = "utf-8";
      core.quotepath = false;

      alias.lg =
        "log --graph --pretty=format:'%C(yellow)%h%Creset - %C(cyan)%an%Creset - %s %Cgreen(%cr)%Creset' --abbrev-commit --all";
    };
  };

  #home.activation.installNodeGlobalTools =
  #  lib.hm.dag.entryAfter [ "writeBoundary" ] ''
  #    export NPM_GLOBAL_DIR=$HOME/.npm-global
  #    mkdir -p $NPM_GLOBAL_DIR
  #    ${pkgs.nodejs}/bin/npm config set prefix "$NPM_GLOBAL_DIR"
  #    export PATH="$NPM_GLOBAL_DIR/bin:$PATH"
  #
  #    ${pkgs.nodejs}/bin/npm install -g protobufjs ts-proto
  #  '';

  programs.vscode = {
    enable = true;
    profiles = {
      default = {
        extensions = with pkgs.vscode-extensions; [
          # Themes
          dracula-theme.theme-dracula

          # Language extensions
          jnoortheen.nix-ide
          brettm12345.nixfmt-vscode
          ms-python.python
          ms-python.vscode-pylance
          golang.go
          zxh404.vscode-proto3
          hashicorp.terraform
          redhat.vscode-yaml
          redhat.vscode-xml
          ms-azuretools.vscode-docker

          # Tools
          #microsoft.intellicode
          #marclipovsky.string-manipulation
          #neptunedesign.vs-sequential-number
          #snyk-security.snyk
          #jebbs.plantuml
          #waderyan.gitblame
          #ow.vscode-subword-navigation
        ];
        userSettings = {
          "workbench.colorTheme" = "Dracula Theme Soft";

          # Global defaults
          "editor.formatOnSave" = true;

          # Nix
          "[nix]" = { "editor.defaultFormatter" = "jnoortheen.nix-ide"; };
          "nix.serverPath" = "nil";

          # Python config
          "[python]" = { "editor.defaultFormatter" = "ms-python.python"; };
          "python.languageServer" = "Pylance"; # or "Pylsp" if you prefer OSS
          "python.formatting.provider" = "black";
          "python.linting.enabled" = true;
          "python.linting.pylintEnabled" = true;
          "python.linting.flake8Enabled" = false;

          # Go config
          "[go]" = { "editor.defaultFormatter" = "golang.go"; };
          "gopls" = {
            "ui.completion.usePlaceholders" = true;
            "staticcheck" = true;
          };
          "go.toolsManagement.autoUpdate" = true;
          "go.useLanguageServer" = true;

          # proto

          # 1. Disable tab switching MCU behavior (aka preview tabs)
          "workbench.editor.enablePreview" = false;

          # 2. Keybindings for move line up/down
          "editor.action.moveLinesUpAction" = "ctrl+up";
          "editor.action.moveLinesDownAction" = "ctrl+down";

          # 4. Search excludes and ignore behavior
          "search.useGlobalIgnoreFiles" = true;
          "search.useIgnoreFiles" = true;
          "search.smartCase" = true;
          "files.exclude" = {
            "**/.git" = true;
            "**/.hg" = true;
            "**/.svn" = true;
            "**/.DS_Store" = true;
            "**/node_modules" = true;
            "**/dist" = true;
            "**/build" = true;
            "**/__pycache__" = true;
            "**/*.pyc" = true;
            "**/vendor" = true;
            "**/.terraform" = true;
            "**/charts" = true;
          };

          # 5. Trim and add newline on save
          "files.insertFinalNewline" = true;
          "files.trimTrailingWhitespace" = true;

          # 6. File associations
          "files.associations" = {
            "*.tfvars" = "terraform";
            "Dockerfile*" = "dockerfile";
            "*.env*" = "dotenv";
            "Chart.yaml" = "helm";
            "values.yaml" = "helm";
            "Makefile*" = "makefile";
          };

          # 7. Update imports on file move
          "javascript.updateImportsOnFileMove.enabled" = "always";
          "typescript.updateImportsOnFileMove.enabled" = "always";
        };
        keybindings = [
          {
            "key" = "ctrl+shift+d";
            "command" = "editor.action.copyLinesDownAction";
            "when" = "editorTextFocus && !editorReadonly";
          }
          {
            "key" = "ctrl+shift+alt+down";
            "command" = "-editor.action.copyLinesDownAction";
            "when" = "editorTextFocus && !editorReadonly";
          }
          {
            "key" = "ctrl+up";
            "command" = "editor.action.moveLinesUpAction";
            "when" = "editorTextFocus && !editorReadonly";
          }
          {
            "key" = "alt+up";
            "command" = "-editor.action.moveLinesUpAction";
            "when" = "editorTextFocus && !editorReadonly";
          }
          {
            "key" = "ctrl+down";
            "command" = "editor.action.moveLinesDownAction";
            "when" = "editorTextFocus && !editorReadonly";
          }
          {
            "key" = "alt+down";
            "command" = "-editor.action.moveLinesDownAction";
            "when" = "editorTextFocus && !editorReadonly";
          }
          {
            "key" = "ctrl+tab";
            "command" = "workbench.action.nextEditorInGroup";
          }
          {
            "key" = "ctrl+shift+tab";
            "command" = "workbench.action.previousEditorInGroup";
          }
          {
            "key" = "f8";
            "command" = "editor.action.goToDeclaration";
            "when" =
              "editorHasDefinitionProvider && editorTextFocus && !isInEmbeddedEditor";
          }
          {
            "key" = "f12";
            "command" = "-editor.action.goToDeclaration";
            "when" =
              "editorHasDefinitionProvider && editorTextFocus && !isInEmbeddedEditor";
          }
          {
            "key" = "ctrl+j";
            "command" = "editor.action.commentLine";
            "when" = "editorTextFocus && !editorReadonly";
          }
          {
            "key" = "ctrl+shift+7";
            "command" = "-editor.action.commentLine";
            "when" = "editorTextFocus && !editorReadonly";
          }
          {
            "key" = "ctrl+shift+j";
            "command" = "editor.action.blockComment";
            "when" = "editorTextFocus && !editorReadonly";
          }
          {
            "key" = "ctrl+shift+a";
            "command" = "-editor.action.blockComment";
            "when" = "editorTextFocus && !editorReadonly";
          }
          {
            "key" = "ctrl+k ctrl+e";
            "command" = "workbench.view.extensions";
          }
          {
            "key" = "ctrl+shift+x";
            "command" = "-workbench.view.extensions";
          }
          {
            "key" = "ctrl+k ctrl+i";
            "command" = "workbench.action.selectIconTheme";
          }
          {
            "key" = "ctrl+k ctrl+a";
            "command" = "workbench.action.toggleActivityBarVisibility";
          }
          {
            "key" = "ctrl+k ctrl+b";
            "command" = "workbench.action.toggleSidebarVisibility";
          }
          {
            "key" = "ctrl+b";
            "command" = "-workbench.action.toggleSidebarVisibility";
          }
          {
            "key" = "ctrl+m";
            "command" = "editor.action.jumpToBracket";
          }
          {
            "key" = "alt+left";
            "command" = "subwordNavigation.cursorSubwordLeft";
            "when" = "editorTextFocus";
          }
          {
            "key" = "alt+right";
            "command" = "subwordNavigation.cursorSubwordRight";
            "when" = "editorTextFocus";
          }
          {
            "key" = "alt+shift+left";
            "command" = "subwordNavigation.cursorSubwordLeftSelect";
            "when" = "editorTextFocus";
          }
          {
            "key" = "alt+shift+right";
            "command" = "subwordNavigation.cursorSubwordRightSelect";
            "when" = "editorTextFocus";
          }
          {
            "key" = "alt+backspace";
            "command" = "subwordNavigation.deleteSubwordLeft";
            "when" = "editorTextFocus";
          }
          {
            "key" = "alt+delete";
            "command" = "subwordNavigation.deleteSubwordRight";
            "when" = "editorTextFocus";
          }
          {
            "key" = "ctrl+shift+alt+i";
            "command" = "java.intellicode.completion";
          }
          {
            "key" = "ctrl+shift+alt+e";
            "command" =
              "workbench.action.quickOpenNavigatePreviousInFilePicker";
            "when" = "inFilesPicker && inQuickOpen";
          }
          {
            "key" = "ctrl+shift+e";
            "command" =
              "-workbench.action.quickOpenNavigatePreviousInFilePicker";
            "when" = "inFilesPicker && inQuickOpen";
          }
          {
            "key" = "ctrl+k ctrl+[Period]";
            "command" = "workbench.action.splitEditor";
          }
          {
            "key" = "ctrl+b ctrl+left";
            "command" = "workbench.action.focusLeftGroup";
          }
          {
            "key" = "ctrl+k ctrl+left";
            "command" = "-workbench.action.focusLeftGroup";
          }
          {
            "key" = "ctrl+b left";
            "command" = "workbench.action.moveActiveEditorGroupLeft";
          }
          {
            "key" = "ctrl+k left";
            "command" = "-workbench.action.moveActiveEditorGroupLeft";
          }
          {
            "key" = "ctrl+b ctrl+right";
            "command" = "workbench.action.focusRightGroup";
          }
          {
            "key" = "ctrl+k ctrl+right";
            "command" = "-workbench.action.focusRightGroup";
          }
          {
            "key" = "ctrl+b right";
            "command" = "workbench.action.moveActiveEditorGroupRight";
          }
          {
            "key" = "ctrl+k right";
            "command" = "-workbench.action.moveActiveEditorGroupRight";
          }
          {
            "key" = "ctrl+b down";
            "command" = "workbench.action.moveActiveEditorGroupDown";
          }
          {
            "key" = "ctrl+k down";
            "command" = "-workbench.action.moveActiveEditorGroupDown";
          }
          {
            "key" = "ctrl+b up";
            "command" = "workbench.action.moveActiveEditorGroupUp";
          }
          {
            "key" = "ctrl+k up";
            "command" = "-workbench.action.moveActiveEditorGroupUp";
          }
          {
            "key" = "ctrl+k up";
            "command" = "workbench.action.splitEditorUp";
          }
          {
            "key" = "ctrl+k down";
            "command" = "workbench.action.splitEditorDown";
          }
          {
            "key" = "ctrl+k left";
            "command" = "workbench.action.splitEditorLeft";
          }
          {
            "key" = "ctrl+k right";
            "command" = "workbench.action.splitEditorRight";
          }
          {
            "key" = "shift+alt+d";
            "command" = "editor.action.showDefinitionPreviewHover";
          }
          {
            "key" = "ctrl+shift+alt+i";
            "command" = "python.sortImports";
          }
          {
            "key" = "ctrl+shift+y";
            "command" = "workbench.action.terminal.toggleTerminal";
          }
          {
            "key" = "ctrl+shift+[Equal]";
            "command" = "-workbench.action.terminal.toggleTerminal";
          }
          {
            "key" = "ctrl+shift+d";
            "command" = "-workbench.view.debug";
          }
          {
            "key" = "ctrl+j";
            "command" = "-workbench.action.togglePanel";
          }
          {
            "key" = "f4";
            "command" = "testing.runAtCursor";
            "when" = "editorTextFocus";
          }
          {
            "key" = "ctrl+shift+[Comma] c";
            "command" = "-testing.runAtCursor";
            "when" = "editorTextFocus";
          }
          {
            "key" = "ctrl+shift+f4";
            "command" = "goToNextReference";
            "when" = "inReferenceSearchEditor || referenceSearchVisible";
          }
          {
            "key" = "f4";
            "command" = "-goToNextReference";
            "when" = "inReferenceSearchEditor || referenceSearchVisible";
          }
          {
            "key" = "ctrl+e";
            "command" = "-workbench.action.quickOpen";
          }
          {
            "key" = "ctrl+e";
            "command" = "-workbench.action.quickOpenNavigateNextInFilePicker";
            "when" = "inFilesPicker && inQuickOpen";
          }
          {
            "key" = "ctrl+e";
            "command" = "-editor.action.toggleScreenReaderAccessibilityMode";
            "when" = "accessibilityHelpIsShown";
          }
        ];
      };
    };
  };

  home.activation.installExercism = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    export PATH=${lib.makeBinPath [ pkgs.gzip pkgs.curl pkgs.gnutar ]}:$PATH
    if [ ! -f "${appsDir}/exercism/exercism" ]; then
      echo "Installing Exercism CLI to ${appsDir}/exercism..."
      mkdir -p "${appsDir}/exercism"
      tmpdir=$(mktemp -d)

      curl -L \
        https://github.com/exercism/cli/releases/download/v3.5.7/exercism-3.5.7-linux-x86_64.tar.gz \
        -o "$tmpdir/exercism.tar.gz"
      tar -xzf "$tmpdir/exercism.tar.gz" -C "$tmpdir"
      mv "$tmpdir/exercism" "${appsDir}/exercism/"
      mv "$tmpdir/shell" "${appsDir}/exercism/"
      rm -rf "$tmpdir"
      mkdir -p $HOME/.local/bin
      ln -sf $HOME/Apps/exercism/exercism $HOME/.local/bin/exercism
    fi
  '';

  programs.zsh.initContent = ''
    if [ -d "${appsDir}/exercism/shell" ]; then
      fpath=("${appsDir}/exercism/shell" $fpath)
    fi
  '';

  # haskell stack
  home.activation.stackConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    export PATH=${lib.makeBinPath [ pkgs.haskellPackages.stack ]}:$PATH
    # Ensure Stack is installed and config directory exists
    mkdir -p ~/.stack

    # Configure Stack to ignore Nix and use its own GHC
    stack config set system-ghc --global true
    stack config set install-ghc --global true
    if ! grep -q '^notify-if-nix-on-path:' ~/.stack/config.yaml; then
      echo 'notify-if-nix-on-path: false' >> ~/.stack/config.yaml
    fi
  '';
}
