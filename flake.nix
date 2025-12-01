{
  description = "Flake to develop llvm toolchain";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    nixpkgs-circt.url = "github:NixOS/nixpkgs/nixos-25.05";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, nixpkgs-circt, flake-utils }:
    flake-utils.lib.eachDefaultSystem ( system:
    let
      pkgs = import nixpkgs { inherit system; config.allowUnfree = true; };
      circt = (import nixpkgs-circt { inherit system; }).circt;
      pkgsRV = pkgs.pkgsCross.riscv64;
      targetLlvmLibraries = pkgsRV.llvmPackages_21;
    in rec {

      defaultPackage = pkgs.stdenv.mkDerivation {
        name = "llvm";

        dontUnpack = true;

        buildInputs = with pkgs; [
          python3
          ninja
          cmake
        ];

        cmakeFlags = [
            "-DUSE_DEPRECATED_GCC_INSTALL_PREFIX=1"
            "-DGCC_INSTALL_PREFIX=${pkgs.gcc}"
            "-DC_INCLUDE_DIRS=${pkgs.stdenv.cc.libc.dev}/include"
            "-GNinja"
            "-DCMAKE_BUILD_TYPE=Release"
            # "-DCMAKE_INSTALL_PREFIX=../inst"
            "-DLLVM_INSTALL_TOOLCHAIN_ONLY=ON"
            "-DLLVM_ENABLE_PROJECTS=clang"
            "-DLLVM_ENABLE_RUNTIMES=libcxx"
            "-DLLVM_TARGETS_TO_BUILD=RISCV"
            "-DLIBCXXABI_USE_LLVM_UNWINDER=0"
            "-S ${self}/llvm"
        ];
      };

      packages.sim = pkgs.stdenv.mkDerivation {
        name = "fck-china-sim";
        # Floating derivation!!!
        __impure = true;

        src = pkgs.fetchgit {
          url = "https://github.com/OpenXiangShan/XiangShan.git";
          rev = "0fb84f8ddbfc9480d870f72cc903ac6453c888c9";
          fetchSubmodules = true;
          leaveDotGit = true;
          sha256 = "sha256-C+y//RJxI8FwYWCs8dmYLh8ZGVNCTAnRoiOVuY913Jg=";
          deepClone = false;
        };

        nativeBuildInputs = with pkgs; [
          mill
          time
          git
          espresso
          verilator
          python3
        ];

        buildInputs = with pkgs; [
          sqlite.dev
          zlib.dev
          zstd.dev
        ];

        buildPhase = ''
          runHook preBuild

          # Copy sources
          export NOOP_HOME=$out/src
          echo src = $src
          echo NOOP_HOME = $NOOP_HOME
          mkdir -p $NOOP_HOME
          cp -r $src/* $src/.* $NOOP_HOME

          # Patch shebangs
          chmod u+wx -R $NOOP_HOME
          patchShebangs --build $NOOP_HOME/scripts/

          # Build
          export _JAVA_OPTIONS="-XX:+UseZGC -XX:+ZUncommit -XX:ZUncommitDelay=30"
          FIRTOOL=${circt}/bin/firtool JVM_XMX=20G make -j8 -C $NOOP_HOME emu

          runHook postBuild
        '';

        installPhase = ''
          runHook preInstall

          mkdir -p $out/bin
          chmod u+x -R $out/src/build/
          cp $out/src/build/verilator-compile/emu $out/bin
          rm -rf $out/src

          runHook postInstall
        '';
      };

      devShell = (defaultPackage.overrideAttrs (oldAttrs: {
        name = "llvm-env";
        buildInputs = oldAttrs.buildInputs;
      }));


    });
}

