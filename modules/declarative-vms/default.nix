{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.virtualisation.proxmox;
in

{
  meta.maintainers = with lib.maintainers; [
    julienmalka
    camillemndn
  ];

  options.virtualisation.proxmox = (import ./options.nix { inherit config lib; }).options // {
    node = lib.mkOption {
      type = lib.types.str;
      description = "The cluster node name.";
    };

    name = lib.mkOption {
      type = lib.types.str;
      default = config.networking.hostName;
      description = "Set a name for the VM. Only used on the configuration web interface.";
    };

    autoInstall = lib.mkEnableOption "Automatically install the NixOS configuration on the VM";

    iso = lib.mkOption {
      default = null;
      type = lib.types.package;
      description = "Iso that will be inserted into the VM. Not compatible with the autoInstall option";
    };

  };

  config = lib.mkIf cfg.autoInstall {
    virtualisation.proxmox.iso =
      let
        isoConfig = import ./iso.nix config.system.build;
      in
      (pkgs.nixos isoConfig).config.system.build.isoImage;
  };

}
