{
  nixpkgs,
  nixpkgs-unstable,
  ...
}: let
  override = nixpkgs.lib.attrsets.recursiveUpdate;
in rec {
  theme = "nordicWithGtkNix";
  system = "x86_64-linux";
  username = "argus";
  hostname = "mutant";
  useDvorak = false;
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
  extraExtraSpecialArgs = {};
  extraSpecialArgs = {};
  additionalModules = [./shared];
  additionalUserPackages = [
    "steam"
    "jre8"
    "aseprite"
    "godot_4_custombuild"
    {
      package = "ferium";
      set = "unstable";
    }
  ]; # will be evaluated later
  additionalOverlays = [
    (_: super: {
      steam = super.steam.override {
        extraLibraries = _: [super.mesa.drivers];
      };
      godot_4_custombuild = let
        unstable = import nixpkgs-unstable {
          localSystem = {inherit system;};
        };
      in
        unstable.godot_4.overrideAttrs (_: {
          src = super.fetchgit {
            url = "https://github.com/godotengine/godot";
            rev = "13f1d8096032bf572d5071c5bf9f61de0a055fed";
            sha256 = "0icgg7mk0icc5qrcrnbifnv9z2dg34rg543dymp8sffks4nhaaba";
          };
        });
    })
  ];
  hardwareConfiguration = [./hardware ./shared];
  packageSelections = {
    remotebuild = [
      # "dash"
      # "grub"
    ];
    unstable = [
      # "linuxPackages_latest"
      # "linuxPackages_zen"
      "linuxPackages_xanmod_latest"
      # "linuxPackages_xanmod"
      {
        set1 = "linuxKernel";
        set2 = "kernel";
        set3 = "xanmod_latest";
      }

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
      "gnome"
      "plymouth"
      "gdm"
      "qtile"
      "zsh"
      "zplug"
      "kitty"
      # "xorg"
      # "systemd"
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
    additionalOverlays = let
      kernel = import ./hardware/kernel-overlay.nix {
        inherit override hostname;
        basekernelsuffix = "xanmod_latest";
      };
    in [
      # kernel
    ];
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
