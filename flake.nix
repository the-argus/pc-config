{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-22.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs?ref=nixos-unstable";

    master-config = {
      url = "github:the-argus/nixsys";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.nixpkgs-unstable.follows = "nixpkgs-unstable";
      inputs.audio-plugins.url = "github:the-argus/audio-plugins-nix";
    };
  };

  outputs = {
    self,
    nixpkgs,
    nixpkgs-unstable,
    master-config,
  }: let
    settings = import ./settings.nix {
      inherit nixpkgs nixpkgs-unstable master-config;
    };
  in {
    nixosConfigurations = master-config.createNixosConfiguration settings;
    homeConfigurations = {
      "${settings.username}" =
        master-config.createHomeConfigurations settings;
    };
    devShell."x86_64-linux" =
      (master-config.finalizeSettings settings).pkgs.mkShell {};
  };
}
