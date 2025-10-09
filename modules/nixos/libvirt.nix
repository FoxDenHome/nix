{ ... } :
{
  config = {
    virtualisation.libvirtd.qemu.runAsRoot = false;
    virtualisation.libvirtd.enable = true;

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
