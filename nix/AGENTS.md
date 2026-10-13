# Repository agent guidance

This is a Nix / home-manager dotfiles repository for an Arch Linux
workstation. Configuration entry point: `main.nix` (imported by `flake.nix`
or `home.nix` depending on entrypoint).

## How the user applies changes

`update` (alias) -> `sudo -v && home-manager switch -b "backup-<ts>"`.

The `sudo -v` keeps activation sudo calls (group setup, `setcap`, system
symlink repair) unattended. Run `home-manager build` from the agent's shell
first to catch eval and shellcheck errors before asking the user to `update`.

## Operational rules

See:

- [.cursor/rules/nix-debugging-discipline.mdc](.cursor/rules/nix-debugging-discipline.mdc)
  — always-on; how to debug system-level changes safely and stay within an
  iteration budget (hard 3-iteration cap per session).

## Defaults

When in doubt, prefer reproducible Nix changes over imperative shell. Any
imperative debug experiment must be undone by an idempotent Nix-defined
wrapper before the session ends.
