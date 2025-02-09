{
  description = "Regenerate go module vendorHashes from inputs.";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  inputs.tailscale.url = "github:tailscale/tailscale";
  inputs.tailscale.flake = false;

  outputs = {
    self,
    nixpkgs,
    tailscale,
  }: let
    systems = [
      "aarch64-darwin"
      "aarch64-linux"
      "riscv64-linux"
      "x86_64-darwin"
      "x86_64-linux"
    ];
    eachSystem = f:
      nixpkgs.lib.genAttrs systems (
        system:
          f rec {
            inherit system;
            pkgs = nixpkgs.legacyPackages.${system};
            devshell = import ./. {nixpkgs = pkgs;};
          }
      );
  in {
    formatter = eachSystem ({pkgs, ...}: pkgs.alejandra);

    packages = eachSystem ({
      system,
      pkgs,
      ...
    }: {
      default = self.packages.${system}.nardump;
      nardump = pkgs.buildGo123Module rec {
        pname = "nardump";
        version = tailscale.rev;
        src = "${tailscale}/cmd/nardump";
        vendorHash = null;

        # Fake up a go module inside the nardump dir, so we don't
        # have to download & cache the entirety of tailscale's
        # deps:
        prePatch = ''
          cat >go.mod <<EOF
          module github.com/tailscale/tailscale/cmd/nardump
          go 1.23.0
          require ()
          EOF
        '';
      };
    });
    flakeModules.default = ./flake-module.nix;
  };
}
