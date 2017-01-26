let
  nixpkgsPath = "${builtins.toPath <root>}/lib/nixpkgs-channels";
  nixopsCommit = "fc43d9c97b4f16574c5b1940d8a4d129372df790";

  overrides =

in with import nixpkgsPath { };
rec {
    shell = stdenv.mkDerivation {
        name = "lib-shell";

        buildInputs = [ nixopsLatest ];

        shellHook = ''
          export NIX_PATH='nixpkgs=${nixpkgsPath}:root=${builtins.toPath <root>}'
        '';
    };

    nixopsLatest =
      let src = builtins.fetchTarball "https://github.com/NixOS/nixops/archive/${nixopsCommit}.tar.gz";
          release = import "${src}/release.nix" {};
      in release.build.${builtins.currentSystem};

    overrides = {
        nixpkgs.config.packageOverrides = super: {
        };
    };
}