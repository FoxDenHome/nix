{ nixpkgs, pkgs, lib, config, ... }:
let
  services = import ../../services.nix { inherit nixpkgs; };
  svcConfig = config.foxDen.services.samba;

  smbServices = ["samba-smbd" "samba-nmbd" "samba-winbindd"];

  smbPaths = [
    "/run/samba"
    "/var/log/samba"
    "/var/lib/samba"
    "/var/lib/samba/private"
    "/var/cache/samba"
    "/var/lock/samba"
  ];
in
{
  options.foxDen.services.samba = services.mkOptions { name = "Samba for SMB"; };

  config = lib.mkIf svcConfig.enable (lib.mkMerge (
    (map (name: (services.mkCustom {
      inherit svcConfig pkgs config;
      name = name;
      host = "samba";
    })) smbServices)
    ++ [
    {
      users.users.smbguest = {
        isSystemUser = true;
        group = "smbguest";
      };
      users.groups.smbguest = {};

      services.samba.enable = true;
      services.samba.settings = {
        global = {
          # basic setup
          "workgroup" = "WORKGROUP";
          "vfs objects" = "catia fruit streams_xattr io_uring";
          "min protocol" = "SMB3";

          # performance tuning
          "server multi channel support" = "yes";
          "aio read size" = "16384";
          "aio write size" = "16384";
          "read raw" = "yes";
          "write raw" = "yes";
          "use sendfile" = "yes";
          "socket options" = "TCP_NODELAY IPTOS_LOWDELAY IPTOS_THROUGHPUT SO_KEEPALIVE SO_RCVBUF=65536 SO_SNDBUF=65536";
          "strict locking" = "no";
          "strict sync" = "no";

          # disable printing
          "load printers" = "no";
          "disable spoolss" = "yes";

          # guest account
          "guest account" = "smbguest";
          "map to guest" = "Never";

          # macOS stuff
          "fruit:metadata" = "stream";
          "fruit:model" = "MacSamba";
          "fruit:posix_rename" = "yes";
          "fruit:veto_appledouble" = "yes";
          "fruit:wipe_intentionally_left_blank_rfork" = "yes";
          "fruit:delete_empty_adfiles" = "yes";
          "fruit:zero_file_id" = "yes";
          "spotlight" = "no";

          # security
          "allow insecure wide links" = "no";
        };

        # TODO: Remove this
        # homes = {
        #   "comment" = "Home Directories";
        #   "browseable" = "no";
        #   "guest ok" = "no";
        #   "writable" = "yes";
        #   "create mask" = "0600";
        #   "directory mask" = "0700";
        #   "path" = "/home/%u";
        #   "follow symlinks" = "no";
        #   "wide links" = "no";
        # };
      };

      systemd.services = (nixpkgs.lib.attrsets.genAttrs smbServices (name: {
        unitConfig = {
          JoinsNamespaceOf = lib.mkIf (name != "samba-smbd") "samba-smbd.service";
        };
        serviceConfig = {
          ReadWritePaths = smbPaths;
        };
      }));

      environment.persistence."/nix/persist/samba" = {
        hideMounts = true;
        directories = smbPaths;
      };
    }
  ]));
}
