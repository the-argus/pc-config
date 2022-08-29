{

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-22.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs?ref=nixos-unstable";

    audio-plugins = {
      url = "github:the-argus/audio-plugins-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    master-config = {
      url = "github:the-argus/nixsys";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { self
    , nixpkgs
    , nixpkgs-unstable
    , audio-plugins
    , master-config
    }@inputs: 
    let
      homeconfigs = (import ./settings.nix {
          inherit audio-plugins nixpkgs nixpkgs-unstable master-config;
        }).home-manager;
      nixconfigs = (import ./settings.nix {
          inherit audio-plugins nixpkgs nixpkgs-unstable master-config;
        }).nixos;
    in
    {
      nixosConfigurations = master-config.createNixosConfiguration nixconfigs;
      homeConfigurations.${homeconfigs.username} = (master-config.createHomeConfigurations homeconfigs);
      devShell."x86_64-linux" = nixconfigs.pkgs.mkShell { };
    };
}
