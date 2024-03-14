{
  description = "Regenerate go module vendorHashes from inputs.";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  inputs.flake-utils.url = "github:numtide/flake-utils";
  inputs.tailscale.url = "github:tailscale/tailscale";

  outputs = inputs @ {flake-parts, ...}:
    flake-parts.lib.mkFlake {inherit inputs;} ({
      withSystem,
      flake-parts-lib,
      ...
    }: let
      inherit (flake-parts-lib) importApply;
    in {
      systems = ["x86_64-linux" "aarch64-linux" "aarch64-darwin" "x86_64-darwin"];

      perSystem = {
        config,
        self',
        inputs',
        pkgs,
        ...
      }: {
        formatter = pkgs.alejandra;

        packages = {
          default = config.packages.nardump;
          nardump = pkgs.buildGoPackage rec {
            pname = "nardump";
            version = inputs.tailscale.rev;
            src = "${inputs.tailscale}/cmd/nardump";
            goPackagePath = "github.com/tailscale/tailscale/cmd/nardump";
          };
        };
      };
      flake = {
        flakeModules.default = ./flake-module.nix;
      };
    });
}
