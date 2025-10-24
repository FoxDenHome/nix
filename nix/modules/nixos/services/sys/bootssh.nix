{ lib, config, pkgs, ... } :
{
  options.foxDen.services.bootssh = {
    enable = lib.mkEnableOption "bootssh";
  };
  config = lib.mkIf config.foxDen.services.bootssh.enable {
    boot.initrd.network.ssh = {
      enable = true;
      authorizedKeys.keys = [
        "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBN/lwUU7uvM/G/4HdEg4SJ2YaEq2SK8mwMcdPmRZBQ6w4+RykvUAJi3cVLBeI8Ng3vW3faDIW2HU2P4qF4y+kDM= doridian@fennec"
        "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBNhmxwlcA26Dee8lNV3rSDxZeC+Q8xDC80iwLDO9d9smSZ4qBAcLGZrjV4mRyVI0omNG/VyB10VCQrS52E+QqrQ= doridian@capefox"
      ];
      hostKeys = [
        # ssh-keygen -t rsa -N "" -f /nix/persist/foxden/bootssh/ssh_host_rsa_key
        "/nix/persist/foxden/bootssh/ssh_host_rsa_key"
        # ssh-keygen -t ed25519 -N "" -f /nix/persist/foxden/bootssh/ssh_host_ed25519_key
        "/nix/persist/foxden/bootssh/ssh_host_ed25519_key"
      ];
    };

    boot.initrd.extraUtilsCommands = ''
      copy_bin_and_libs ${pkgs.fish}/bin/fish
    '';
    boot.initrd.systemd.users.root.shell = "/bin/fish";
  };
}
