{
  description = "Flake to develop llvm toolchain";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem ( system:
    let
      pkgs = import nixpkgs { inherit system; };
    in {

      devShell = pkgs.mkShell {
        name = "llvm-env";
        buildInputs = with pkgs; [
          llvmPackages_21.clangWithLibcAndBasicRtAndLibcxx
        ];
      };

    });
}

