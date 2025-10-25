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
      gccForLibs = pkgs.stdenv.cc.cc;
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
        outputHashAlgo = "sha256";
        outputHash = "";

        src = pkgs.fetchgit {
          url = "https://github.com/OpenXiangShan/XiangShan.git";
          rev = "0fb84f8ddbfc9480d870f72cc903ac6453c888c9";
          fetchSubmodules = true;
          leaveDotGit = true;
          sha256 = "sha256-AVrgI/IV2ah1/s2q766XxpRmjdOxoF9Q+vKLs/yet/Q=";
        };

        nativeBuildInputs = with pkgs; [
          mill
          circt # for firtool
          time
          git
          espresso
        ];

        buildInputs = with pkgs; [
          verilator
          sqlite.dev
          zlib.dev
          zstd.dev
        ];

        buildPhase = ''
          # export NOOP_HOME=$out/src
          # echo src = $src
          # echo NOOP_HOME = $NOOP_HOME
          # mkdir -p $NOOP_HOME
          # cp -r $src/* $NOOP_HOME
          # make -C $NOOP_HOME emu

          export NOOP_HOME=$src
          make emu
        '';
        installPhase = ''
          cp -r build/* $out
        '';
      };

      devShell = (defaultPackage.overrideAttrs (oldAttrs: {
        name = "llvm-env";
        buildInputs = oldAttrs.buildInputs ++ (with pkgs; [ verilator ]);
      }));


    });
}

