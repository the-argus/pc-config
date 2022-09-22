{
  audio-plugins,
  nixpkgs,
  nixpkgs-unstable,
  master-config,
  ...
}: rec {
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
      src = super.linuxPackages_xanmod_latest.kernel.src;
      version = "5.19.1";
      override = nixpkgs.lib.attrsets.recursiveUpdate;
    in {
      linuxKernel = override super.linuxKernel {
        kernels = override super.linuxKernel.kernels {
          linux_xanmod_latest = super.linuxKernel.manualConfig {
            stdenv = super.gccStdenv;
            inherit src version;
            modDirVersion = "${version}-xanmod1-${super.lib.strings.toUpper hostname}";
            inherit (super) lib;
            configfile = super.callPackage ./hardware/kernelconfig.nix {
              inherit hostname;
            };
            allowImportFromDerivation = true;
          };
        };
      };
    })
  ];
  hardwareConfiguration = [./hardware];
  packageSelections = {
    remotebuild = [
      # "linuxPackages_latest"
      # "linuxPackages_zen"
      # "linuxPackages_xanmod_latest"
      "grub"
      "plymouth"
      "starship"
    ];
    unstable = [
      "alejandra"
      "wl-color-picker"
      "heroic"
      "solo2-cli"
      "ani-cli"
      "ungoogled-chromium"
      "firefox"
      "OVMFFull"
      "kitty"
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
  remotebuildOverrides = {
    optimization = {
      useMusl = true;
      useFlags = true;
      useClang = true;
    };
  };
  unstableOverrides = {};
}
