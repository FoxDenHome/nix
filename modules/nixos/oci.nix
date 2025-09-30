{ ... }:
{
  environment.persistence."/nix/persist/oci" = {
    directories = [
      "/var/lib/containers"
    ];
  };

  virtualisation.oci-containers.backend = "podman";
}
