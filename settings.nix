{
  audio-plugins,
  nixpkgs,
  nixpkgs-unstable,
  master-config,
  ...
}: let
  override = nixpkgs.lib.attrsets.recursiveUpdate;
in rec {
  system = "x86_64-linux";
  username = "argus";
  hostname = "mutant";
  # unfree packages that i explicitly use
  allowedUnfree = [
    "spotify-unwrapped"
    "reaper"
    "slack"
    "steam"
    "steam-original"
    "discord"
    "ue4"
  ];
  allowBroken = false;
  plymouth = let
    name = "circuit";
  in {
    themeName = name;
    themePath = "pack_1/${name}";
  };
  extraExtraSpecialArgs = {inherit (audio-plugins) mpkgs;};
  extraSpecialArgs = {};
  additionalModules = [audio-plugins.homeManagerModule];
  additionalUserPackages = [
    "steam"
    "jre8"
  ]; # will be evaluated later
  additionalOverlays = [
    (self: super: let
      basekernelsuffix = "5_19";
      dirVersionNames = {
        xanmod_latest = "xanmod";
        "5_15" = "";
        "5_19" = "";
      };
      dirVersionName =
        if builtins.hasAttr basekernelsuffix dirVersionNames
        then
          (
            if dirVersionNames.${basekernelsuffix} == ""
            then ""
            else "-${dirVersionNames.${basekernelsuffix}}1"
          )
        else basekernelsuffix;
      basekernel = "linux${
        if basekernelsuffix == ""
        then ""
        else "_"
      }${basekernelsuffix}";
      src = super.linuxKernel.kernels.${basekernel}.src;
      version = super.linuxKernel.kernels.${basekernel}.version;
    in {
      linuxKernel = override super.linuxKernel {
        kernels = override super.linuxKernel.kernels {
          ${basekernel} =
            (super.linuxKernel.manualConfig {
              stdenv = super.gccStdenv;
              inherit src version;
              modDirVersion = "${version}${dirVersionName}-${super.lib.strings.toUpper hostname}";
              inherit (super) lib;
              configfile = super.callPackage ./hardware/kernelconfig.nix {
                inherit hostname;
              };
              allowImportFromDerivation = true;
            })
            .overrideAttrs (oa: {
              nativeBuildInputs = (oa.nativeBuildInputs or []) ++ [super.lz4];
            });
        };
      };
    })
  ];
  hardwareConfiguration = [./hardware];
  packageSelections = {
    remotebuild = [
      "starship"
      "dash"
      "grub"
      "plymouth"
      "coreutils-full"
    ];
    unstable = [
      "linuxPackages_latest"
      "linuxPackages_zen"
      "linuxPackages_xanmod_latest"
      "linuxPackages_xanmod"

      "alejandra"
      "wl-color-picker"
      "heroic"
      "solo2-cli"
      "ani-cli"
      "ungoogled-chromium"
      "firefox"
      "OVMFFull"
    ];
    localbuild = [
      "gnome-shell"
      "gdm"
      "qtile"
      "zsh"
      "zplug"
      "kitty"
      "xorg"
      "systemd"
    ];
  };
  terminal = "kitty";
  usesWireless = false; # install and autostart nm-applet
  usesBluetooth = false; # install and autostart blueman applet
  usesMouse = true; # enables xmousepasteblock for middle click
  hasBattery = false; # battery widget in tiling WMs
  usesEthernet = true;
  optimization = {
    arch = "znver1";
    useMusl = false; # use musl instead of glibc
    useFlags = false; # use USE
    useClang = false; # cland stdenv
    useNative = false; # native march
    # what optimizations to use (check https://github.com/fortuneteller2k/nixpkgs-f2k/blob/ca75dc2c9d41590ca29555cddfc86cf950432d5e/flake.nix#L237-L289)
    USE = [
      "-O3"
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
  };
  nix = {
    distributedBuilds = true;
    buildMachines = [
      {
        hostName = "rpmc.duckdns.org";
        systems = ["aarch64-linux"];
        sshUser = "servers";
        sshKey = "/home/argus/.ssh/id_ed25519";
        supportedFeatures = ["big-parallel"];
        maxJobs = 4;
        speedFactor = 2;
      }
    ];
  };
  additionalSystemPackages = [];
  name = "pkgs";
  remotebuildOverrides = {
    optimization = {
      useMusl = true;
      useFlags = true;
      useClang = true;
    };
    name = "remotebuild";
  };
  unstableOverrides = {
    name = "unstable";
  };
  localbuildOverrides = override remotebuildOverrides {
    optimization = {
      useMusl = false;
      useFlags = true;
      useClang = true;
    };
    name = "localbuild";
  };
}
