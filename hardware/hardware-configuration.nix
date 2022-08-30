{ config, lib, pkgs, modulesPath, settings, ... }:
{
  imports =
    [ (modulesPath + "/installer/scan/not-detected.nix")
    ];
  
  nix.settings.system-features = [ "nixos-test" "benchmark" "big-parallel" "kvm" ]
    ++ settings.features;

  boot.initrd.availableKernelModules = [ "nvme" "ahci" "xhci_pci" "usb_storage" "usbhid" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.extraModulePackages = [ ];

  fileSystems."/" =
    { device = "/dev/disk/by-label/NIXROOT";
      fsType = "ext4";
    };

  fileSystems."/home" =
    { device = "/dev/disk/by-label/NIXHOME";
      fsType = "ext4";
    };

  fileSystems."/boot/efi" =
    { device = "/dev/disk/by-label/WINBOOT";
      fsType = "vfat";
    };

  swapDevices = [
    { device = "/.swapfile"; size = 4069; }
  ];

  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
