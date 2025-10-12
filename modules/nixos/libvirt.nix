{ hostName, pkgs, lib, nixpkgs-unstable, systemArch, ... } :
let
  nixpkgsUnstable = (import nixpkgs-unstable {
    system = systemArch;
    config = {
      allowUnfree = true;
    };
  });

  vmDirPath = ../../vms/${hostName};

  vmNames = let
    vmDir = if (builtins.pathExists vmDirPath) then (builtins.readDir vmDirPath) else {};
  in lib.attrsets.attrNames vmDir;

  vms = lib.attrsets.genAttrs vmNames (name: {
    inherit name;
    # TODO: Validate this somehow
    config = import (vmDirPath+"/${name}/config.nix");
    libvirtXml = vmDirPath+"/${name}/libvirt.xml";
  });

  setupVMScript = vm: pkgs.writeShellScript "setup-vm" (''
    #!${pkgs.bash}/bin/bash
    set -euo pipefail

    if [ ! -f /var/lib/libvirt/images/${vm.name}.qcow2 ]; then
      echo "Creating root disk for ${vm.name}"
      ${pkgs.qemu-utils}/bin/qemu-img create -f qcow2 /var/lib/libvirt/images/${vm.name}.qcow2 ${vm.config.rootDiskSize}
    fi
    ${pkgs.coreutils}/bin/chown -h qemu-libvirtd:qemu-libvirtd /var/lib/libvirt/images/${vm.name}.qcow2
    ${pkgs.libvirt}/bin/virsh define ${vm.libvirtXml}
    ${pkgs.libvirt}/bin/virsh autostart ${if vm.config.autostart then "" else "--disable"} ${vm.name}
  '' + (if vm.config.autostart then "\n${pkgs.libvirt}/bin/virsh start ${vm.name} || true\n" else ""));
in
{
  config = lib.mkIf ((lib.length vmNames) > 0) {
    virtualisation.libvirtd = {
      enable = true;
      qemu = {
        package = pkgs.qemu_kvm;
        runAsRoot = false;
        swtpm.enable = true;
        ovmf = {
          enable = true;
          packages = [(pkgs.OVMF.override {
            secureBoot = true;
            tpmSupport = true;
          }).fd];
        };
      };
    };
    # TODO: 25.11: virtualisation.useSecureBoot = true;

    systemd.services.libvirt-autocreator = {
      description = "Libvirt AutoCreator Service";
      after = [ "libvirtd.service" ];
      requires = [ "libvirtd.service" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStartPre = "${pkgs.coreutils}/bin/mkdir -p /var/lib/libvirt/images";
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

    foxDen.hosts.hosts = lib.attrsets.genAttrs vmNames (name: {
      interfaces.default = {
        driver = "null";
      } // (vms.${name}.config.interface);
    });
  };
}
