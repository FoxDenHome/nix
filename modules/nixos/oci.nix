{ ... }:
{
  services.podman.enable = true;
  environment.persistence."/nix/persist/oci" = {
    directories = [
      "/var/lib/containers"
    ];
  };
}
