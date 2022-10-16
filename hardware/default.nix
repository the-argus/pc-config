{
  config,
  pkgs,
  plymouth,
  hostname,
  username,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
  ];

  /*
  nix.package = pkgs.nixVersions.nix_2_7;
  */
  nix.package = pkgs.nixFlakes;

  hardware.steam-hardware.enable = true;

  boot = {
    kernelPackages = pkgs.linuxPackages_xanmod_latest;
    kernelParams = ["nordrand" "quiet" "systemd.show_status=0" "loglevel=4" "rd.systemd.show_status=auto" "rd.udev.log-priority=3"];
    loader = {
      efi = {
        efiSysMountPoint = "/boot/efi";
        canTouchEfiVariables = true;
      };
      systemd-boot.enable = true;

      # efi-only grub
      grub = {
        enable = false;
        version = 2;
        device = "nodev";
        efiSupport = true;
        useOSProber = true;
        extraEntries = ''
          menuentry "Reboot" {
          	  reboot
          }
          menuentry "Poweroff" {
           halt
          }
        '';
      };
    };

    initrd = {
      #enable = false;
      verbose = false;
      systemd.enable = true;
      services.swraid.enable = false;
    };

    plymouth = {
      enable = true;
      themePackages = [pkgs.plymouth-themes-package];
      theme = plymouth.themeName;
    };
  };

  # makes plymouth wait 5 seconds while playing
  # systemd.services.plymouth-quit.serviceConfig.ExecStartPre = "${pkgs.coreutils-full}/bin/sleep 5";

  # desktops ------------------------------------------------------------------
  # programs.ssh.askPassword = pkgs.lib.mkForce "${pkgs.gnome.seahorse.out}/libexec/seahorse/ssh-askpass";
  desktops = {
    enable = true;
    # sway.enable = true;
    # awesome.enable = true;
    # ratpoison.enable = true;
    qtile.enable = true;
    # i3gaps.enable = true;
    gnome.enable = true;
    # plasma.enable = true;
  };

  virtualization = {
    enable = true;
    containers = {
      podman.enable = true;
      docker.enable = false;
    };
  };

  services.xserver.displayManager.startx.enable = true;

  services.pipewire.package =
    (import (pkgs.fetchgit {
      url = "https://github.com/K900/nixpkgs";
      rev = "092f4eb681a6aee6b50614eedac74629cb48db23";
      sha256 = "1vx4fn4x32m0q91776pww8b9zqlg28x732ghj47lcfgzqdhwbdh4";
    }) {system = "x86_64-linux";})
    .pipewire;

  # networking ----------------------------------------------------------------
  networking.interfaces.enp39s0.useDHCP = true;
  networking.hostName = hostname; # Define your hostname.
  networking.wireless.enable = false;

  services.openssh = {
    enable = false;
    permitRootLogin = "no";
  };
  users.users.${username}.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJt9P8Vba+rp/5Rw/BmP1LcUGV03QlFaH8Wf6wKwqEuV i.mcfarlane2002@gmail.com"
  ];

  # display -------------------------------------------------------------------
  hardware.opengl = {
    driSupport = true;
    driSupport32Bit = true;
    extraPackages = with pkgs; [
    ];
    extraPackages32 = with pkgs.pkgsi686Linux;
      [libva libvdpau-va-gl vaapiVdpau]
      ++ lib.optionals config.services.pipewire.enable [pipewire];
  };
  hardware.pulseaudio.support32Bit = config.hardware.pulseaudio.enable;

  #	services.xserver.videoDrivers = [ "amdgpu" ];
  services.xserver = {
    videoDriver = "amdgpu";

    config = ''
      Section "ServerFlags"
          Option      "AutoAddDevices"         "false"
      EndSection
    '';
  };
  # hardware ------------------------------------------------------------------
  hardware.openrazer.enable = true;

  environment.systemPackages = with pkgs; [
    razergenie
  ];

  system.stateVersion = "22.05"; # Did you read the comment?
}
