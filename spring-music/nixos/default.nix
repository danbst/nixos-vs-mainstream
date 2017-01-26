let
  pkgs = import <nixpkgs> {};

in {
	shell = pkgs.stdenv.mkDerivation {
      name = "shell";
      buildInputs = with pkgs; [ nixops qemu ];
	};
}