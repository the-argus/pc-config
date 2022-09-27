{override, hostname, ...}: (self: super: let
  basekernelsuffix = "xanmod_latest";
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
  basekernel = "linux_${basekernelsuffix}";
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
          configfile = super.callPackage ./kernelconfig.nix {
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
