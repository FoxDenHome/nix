{ ... } :
{
  config = {
    virtualisation.libvirtd.qemu.runAsRoot = false;
    virtualisation.libvirtd.enable = true;

    environment.persistence."/nix/persist/libvirt" = {
      hideMounts = true;
      directories = [
        { directory = "/var/lib/libvirt"; user = "libvirt-qemu"; group = "libvirt-qemu"; mode = "u=rwx,g=,o="; }
      ];
    };
  };
}
