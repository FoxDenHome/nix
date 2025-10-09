{ hostName, lib, ... } :
let
  vmNames = lib.attrsets.attrNames (builtins.readDir ../../vms/${hostName});

  vms = lib.attrsets.genAttrs vmNames (name: {
    inherit name;
    # TODO: Validate this somehow
    config = import ../../vms/${hostName}/${name}/config.nix;
    libvirtXml = ../../vms/${hostName}/${name}/libvirt.xml;
  });

  setupVMScript = (vm: pkgs.writeShellScriptBin "setup-vm" ''
    #!${pkgs.bash}/bin/bash
    set -euo pipefail

    if [ ! -f /var/lib/libvirt/images/${vm.name}.qcow2 ]; then
      echo "Creating root disk for ${vm.name}"
      qemu-img create -f qcow2 /var/lib/libvirt/images/${vm.name}.qcow2 ${vm.config.rootDiskSize}
    fi
    virsh define ${vm.libvirtXml}
  '');
in
{
  config = {
    virtualisation.libvirtd.qemu.runAsRoot = false;
    virtualisation.libvirtd.enable = true;

    systemd.services.libvirtd-autocreator = {
      description = "Libvirt Auto Creator Service";
      after = [ "libvirtd.service" ];
      requires = [ "libvirtd.service" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = (map setupVMScript (lib.attrsets.attrValues vms));
        RemainAfterExit = true;
      };
      wantedBy = [ "multi-user.target" ];
    };

    environment.persistence."/nix/persist/libvirt" = {
      hideMounts = true;
      directories = [
        { directory = "/var/lib/libvirt"; user = "qemu-libvirtd"; group = "qemu-libvirtd"; mode = "u=rwx,g=,o="; }
      ];
    };

    security.polkit.extraConfig = ''
      polkit.addRule(function(action, subject) {
        if (action.id == "org.libvirt.unix.manage" &&
          subject.isInGroup("superadmins")) {
          return polkit.Result.YES;
        }
      });
    '';
  };
}
