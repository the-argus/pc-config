{ audio-plugins, nixpkgs, nixpkgs-unstable, master-config, ... }:
{
  system = "x86_64-linux";
  username = "argus";
  hostname = "mutant";
  # unfree packages that i explicitly use
  allowedUnfree = [
    "spotify-unwrapped"
    "reaper"
    "slack"
    "steam" "steam-original"
  ];
  plymouth = let name = "rings"; in
    {
      themeName = name;
      themePath = "pack_4/${name}";
    };
  extraExtraSpecialArgs = { inherit (audio-plugins) mpkgs; };
  extraSpecialArgs = { };
  additionalModules = [ audio-plugins.homeManagerModule ];
  additionalUserPackages = [
    "steam"
  ]; # will be evaluated later
  hardwareConfiguration = [ ./hardware ];
  usesWireless = false; # install and autostart nm-applet
  usesBluetooth = false; # install and autostart blueman applet
  usesMouse = true; # enables xmousepasteblock for middle click
  hasBattery = false; # battery widget in tiling WMs
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
}
