{
  pkgs,
  lib,
  config,
  inputs,
  ...
}: let
  pkgs-unstable = import inputs.nixpkgs-unstable {system = pkgs.stdenv.system;};
in {
  packages =
    (with pkgs; [
      git
      just
    ])
    ++ (with pkgs-unstable; [
      dart-sass
      hugo
    ]);

  languages.go.enable = true;

  pre-commit.hooks.shellcheck.enable = true;
}
