{ audio-plugins, nixpkgs, nixpkgs-unstable, master-config, ... }:
let
  hardware = "laptop";

  # unfree packages that i explicitly use
  allowedUnfree = [
    "spotify-unwrapped"
    "reaper"
    "slack"
    # "steam"
    # "steam-original"
  ];


  system = "x86_64-linux";
  username = "argus";
  hostname = "evil";

  plymouth = let name = "rings"; in
    {
      themeName = name;
      themePath = "pack_4/${name}";
    };

  # use musl instead of glibc
  useMusl = false;
  # compile everything from source
  useFlags = false;
  # what optimizations to use (check https://github.com/fortuneteller2k/nixpkgs-f2k/blob/ca75dc2c9d41590ca29555cddfc86cf950432d5e/flake.nix#L237-L289)
  USE = [
    # "-O3"
    "-O2"
    "-pipe"
    "-ffloat-store"
    "-fexcess-precision=fast"
    "-ffast-math"
    "-fno-rounding-math"
    "-fno-signaling-nans"
    "-fno-math-errno"
    "-funsafe-math-optimizations"
    "-fassociative-math"
    "-freciprocal-math"
    "-ffinite-math-only"
    "-fno-signed-zeros"
    "-fno-trapping-math"
    "-frounding-math"
    "-fsingle-precision-constant"
    # not supported on clang 14 yet, and isn't ignored
    # "-fcx-limited-range"
    # "-fcx-fortran-rules"
  ];

  # optimizations --------------------------------------------------------
  # architechtures include:
  # x86-64-v2 x86-64-v3 x86-64-v4 tigerlake
  arch = {
    gcc = {
      arch = "tigerlake";
      tune = "tigerlake";
    };
  };
  optimizedStdenv = pkgsToOptimize:
    let
      mkStdenv = march: stdenv:
        # adds -march flag to the global USE flags and creates stdenv
        pkgsToOptimize.withCFlags
          (USE ++ [ "-march=${march}" "-mtune=${march}" ])
          stdenv;

      # same thing but use -march=native
      mkNativeStdenv = stdenv:
        pkgsToOptimize.impureUseNativeOptimizations
          (pkgsToOptimize.stdenvAdapters.withCFlags USE stdenv);

      optimizedStdenv = mkStdenv arch.gcc.arch pkgsToOptimize.stdenv;
      optimizedClangStdenv =
        mkStdenv arch.gcc.arch pkgsToOptimize.llvmPackages_14.stdenv;

      optimizedNativeClangStdenv =
        pkgs.lib.warn "using native optimizations, \
                forfeiting reproducibility"
          mkNativeStdenv
          pkgsToOptimize.llvmPackages_14.stdenv;
      optimizedNativeStdenv =
        pkgs.lib.warn "using native optimizations, \
                forfeiting reproducibility"
          mkNativeStdenv
          pkgsToOptimize.stdenv;
    in
    optimizedStdenv;

  pkgsInputs =
    {
      config = {
        allowBroken = true;
        allowUnfreePredicate =
          pkg: builtins.elem (pkgs.lib.getName pkg) allowedUnfree;
      };
      localSystem = {
        inherit system;
      } // (if useMusl then {
        libc = "musl";
        config = "x86_64-unknown-linux-musl";
      } else { })
      // (if useFlags then arch else { });

      overlays = [
        (self: super: {
          plymouth-themes-package = import (master-config + "/packages/plymouth-themes.nix") ({
            pkgs = super;
          } // plymouth);
        })
      ] ++ (if useFlags then [
        (self: super: {
          stdenv = optimizedStdenv super;
        })
      ] else [ ]);
    };

  pkgs = import nixpkgs pkgsInputs;
  unstable = import nixpkgs-unstable pkgsInputs;

  additionalPackages = with pkgs; [
    # steam
  ];
in

{
  nixos = {
    inherit system hostname pkgs;
    extraSpecialArgs = {
      inherit hardware unstable plymouth useMusl useFlags hostname username;
    };
  };
  home-manager = {
    inherit system pkgs username;
    extraExtraSpecialArgs = {
      inherit (audio-plugins) mpkgs;
      inherit hardware unstable useMusl useFlags username;
      inherit additionalPackages;
    };
    additionalModules = [ audio-plugins.homeManagerModule ];
  };
}
