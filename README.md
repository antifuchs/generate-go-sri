# generate-go-sri - a https://flake.parts module for making buildGoModule easier in flakes

The flake module exposed here builds on top of [tailscale's nardump](https://github.com/tailscale/tailscale/tree/main/cmd/nardump) program, which makes it easier to build the kind of fixed-output derivations that nixpkgs's `buildGoModule` expects.

## How to use this flake module

Here's a minimal development flake.nix:

```nix
{
  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    generate-go-sri.url = "github:antifuchs/generate-go-sri"; # <- this repo
 };

  outputs = inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        # Use the module to define the `go-sri-hashes` per-system configuration:
        inputs.generate-go-sri.flakeModules.default
      ];
      systems = [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" "x86_64-darwin" ];
      perSystem = { ... }: {
        # define a `generate-sri-default` flake app:
        go-sri-hashes.default = {};
      };
    };
}
```

This defines a flake app that you can invoke with `nix run .#generate-sri-default`. If you run this in a source checkout containing a `go.mod` and `go.sum` file, it then generates a `default.sri` file in the current directory.

## Using the generated `default.sri` file

In nix, with that default.sri file above checked in, you'll build a go module like so:

```nix
pkgs.buildGo1Module {
  pname = "myPackage";
  version = "0.0.0";
  vendorHash = builtins.readFile ./default.sri;
  src = lib.sourceFilesBySuffices (lib.sources.cleanSource ./.) [".go" ".mod" ".sum"];
  subPackages = ["cmd/foo"];
  ldflags = ["-s" "-w"];
  meta.mainProgram = builtins.baseNameOf "foo";
}
```
