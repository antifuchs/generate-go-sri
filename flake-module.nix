{
  self,
  config,
  lib,
  flake-parts-lib,
  ...
}: let
  inherit (flake-parts-lib) mkPerSystemOption;
  inherit (lib) mkOption types;
in {
  options = {
    perSystem = mkPerSystemOption ({
      config,
      pkgs,
      ...
    }: {
      options.go-sri-hashes = mkOption {
        description = ''
          Automatically regenerate a nix package SRI hash for a go.mod.

          This flake module uses the nardump program from
          tailscale's flake to generate a subresource integrity hash
          that can be used as a vendorHash parameter in a
          buildGoModule invocation.

          Each entry in this attrset is the basename of a .sri file,
          giving options for how to prepare a vendorHash.
        '';

        type = types.lazyAttrsOf (types.submodule {
          options = {
            subdir = mkOption {
              type = types.str;
              description = "Relative pathname under which to find the go.mod file.";
              default = ".";
            };
          };
        });
        default = {};
      };
    });
  };
  config = {
    perSystem = {
      config,
      self',
      inputs',
      pkgs,
      lib,
      ...
    }: {
      apps =
        lib.mapAttrs' (name: {subdir}: {
          name = "generate-sri-${name}";
          value.program = pkgs.writeShellApplication {
            name = "generate-go-sri-${name}";
            runtimeInputs = [inputs'.generate-go-sri.packages.nardump pkgs.coreutils];
            text = ''
              set -x
              temp="$(mktemp -d)"
              generated="$(mktemp -p . -t .generate-sri-${name}-XXXXXXX)";
              cleanup() {
                if [ -d "$temp" ] ; then rm -rf "$temp" ; fi
                if [ -f "$generated" ] ; then rm -f "$generated" ; fi
              }
              trap 'cleanup' EXIT
              cd ${lib.escapeShellArg subdir} && go mod vendor -o "$temp"
              nardump -sri "$temp" >"$generated"
              mv "$generated" ${lib.escapeShellArg name}.sri
            '';
          };
        })
        config.go-sri-hashes;
    };
  };
}
