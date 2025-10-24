{ lib, config, pkgs, ... } :
{
  options.foxDen.services.bootssh = {
    enable = lib.mkEnableOption "bootssh";
  };
  config = lib.mkIf config.foxDen.services.bootssh.enable {
    boot.initrd.network.ssh.enable = true;
    boot.initrd.network.ssh.authorizedKeys.keys = [
      "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBN/lwUU7uvM/G/4HdEg4SJ2YaEq2SK8mwMcdPmRZBQ6w4+RykvUAJi3cVLBeI8Ng3vW3faDIW2HU2P4qF4y+kDM= doridian@fennec"
      "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBNhmxwlcA26Dee8lNV3rSDxZeC+Q8xDC80iwLDO9d9smSZ4qBAcLGZrjV4mRyVI0omNG/VyB10VCQrS52E+QqrQ= doridian@capefox"
    ];

    boot.initrd.extraUtilsCommands = ''
      copy_bin_and_libs ${pkgs.fish}/bin/fish
    '';
    boot.initrd.systemd.users.root.shell = "/bin/fish";
  };
}
