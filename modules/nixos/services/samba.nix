{ nixpkgs, pkgs, lib, config, ... }:
let
  services = import ../../services.nix { inherit nixpkgs; };
  svcConfig = config.foxDen.services.samba;
in
{
  options.foxDen.services.samba = services.mkOptions { name = "Samba for SMB"; };

  config = lib.mkIf svcConfig.enable (lib.mkMerge [
    (services.make {
      inherit svcConfig pkgs config;
      host = "samba";
    })
    {
      users.users.guest = {
        isSystemUser = true;
        group = "share";
      };

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
          "guest account" = "guest";
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
        homes = {
          "comment" = "Home Directories";
          "browseable" = "no";
          "guest ok" = "no";
          "writable" = "yes";
          "create mask" = "0600";
          "directory mask" = "0700";
          "path" = "/home/%u";
          "follow symlinks" = "no";
          "wide links" = "no";
        };
      };

      systemd.services.samba.serviceConfig = {
        ReadWritePaths = [
          "/var/lib/samba/private"
          "/var/cache/samba"
          "/etc/samba/private"
        ];
      };

      environment.persistence."/nix/persist/samba" = {
        hideMounts = true;
        directories = [
          "/var/lib/samba/private"
          "/var/cache/samba"
          "/etc/samba/private"
        ];
      };
    }
  ]);
}
