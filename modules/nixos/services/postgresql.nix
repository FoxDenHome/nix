{ foxDenLib, pkgs, lib, config, ... }:
let
  services = foxDenLib.services;

  svcConfig = config.foxDen.services.postgresql;

  serviceType = with lib.types; submodule {
    options = {
      name = lib.mkOption {
        type = str;
      };
      proxy = lib.mkEnableOption "Enable PostgreSQL proxy for 127.0.0.1 access";
      targetService = lib.mkOption {
        type = str;
      };
    };
  };

  mkProxyTo = (clientSvc: if clientSvc.proxy then (lib.mkMerge [
    (services.make {
      name = "postgresql-${clientSvc.name}";
      overrideHost = config.foxDen.services.${clientSvc.name}.host;
      inherit svcConfig pkgs config;
    }).config.systemd.services
    {
      "postgresql-${clientSvc.name}" = {
        wantedBy = [ "multi-user.target" ];

        serviceConfig = {
          Type = "simple";
          User = clientSvc.name;
          Group = clientSvc.name;
          ExecStart = [
            "${pkgs.socat}/bin/socat TCP-LISTEN:5432,bind=127.0.0.1,reuseaddr,fork UNIX-CLIENT:/run/postgresql/.s.PGSQL.5432"
          ];
        };
      };
    }
  ]) else {});
in
{
  options.foxDen.services.postgresql = services.mkOptions { svcName = "postgresql"; name = "PostgreSQL"; } // {
    services = with lib.types; lib.mkOption {
      type = listOf serviceType;
      default = [ ];
      description = "List of systemd services connecting to PostgreSQL";
    };
  };

  config = lib.mkIf ((lib.length svcConfig.services) > 0) (lib.mkMerge [
    (services.make {
      name = "postgresql";
      inherit svcConfig pkgs config;
    }).config
    {
      foxDen.services.postgresql.host = "postgresql";
      foxDen.services.postgresql.enable = true;

      foxDen.hosts.hosts = {
        postgresql.interfaces = {};
      };

      services.postgresql = {
        enable = true;
        package = pkgs.postgresql_17;
        enableTCPIP = false;
        ensureDatabases = map (svc: svc.name) svcConfig.services;
        ensureUsers = map (svc: {
          inherit (svc) name;
          ensureDBOwnership = true;
        }) svcConfig.services;
        identMap = lib.concatStringsSep "\n" (map (svc: ''
          postgres ${svc.targetService} ${svc.name}
          postgres postgresql-${svc.name} ${svc.name}
        '') svcConfig.services);
      };

      systemd.services.postgresql = {
        serviceConfig = {
          PrivateUsers = false;
        };
      };

      environment.persistence."/nix/persist/postgresql" = {
        hideMounts = true;
        directories = [
          { directory = "/var/lib/postgresql"; user = "postgresql"; group = "postgresql"; mode = "u=rwx,g=rx,o="; }
        ];
      };
    }
    {
      systemd.services = lib.attrsets.listToAttrs (map (pgSvc: let
        svcName = if pgSvc.proxy then "postgresql-${pgSvc.name}" else pgSvc.targetService;
      in
      {
        name = svcName;
        value = {
          requires = [ "postgresql.service" ];
          after = [ "postgresql.service" ];
          serviceConfig = {
            BindReadOnlyPaths = [
              "/run/postgresql"
            ];
            Environment = [
              "POSTGRESQL_SOCKET=/run/postgresql/.s.PGSQL.5432"
            ];
          };
        };
      }) svcConfig.services);
    }
    {
      systemd.services = lib.attrsets.listToAttrs (map (pgSvc: let
        svcName = if pgSvc.proxy then "postgresql-${pgSvc.name}" else pgSvc.targetService;
      in
      {
        name = pgSvc.targetService;
        value = let
          deps = if pgSvc.proxy then ["${svcName}.service"] else [];
        in {
          requires = deps;
          after = deps;
          serviceConfig = {
            Environment = [
              "POSTGRESQL_DATABASE=${pgSvc.name}"
              "POSTGRESQL_USERNAME=${svcName}"
            ] ++ (if pgSvc.proxy then [
              "POSTGRESQL_HOST=127.0.0.1"
              "POSTGRESQL_PORT=5432"
            ] else []);
          };
        };
      }) svcConfig.services);
    }
    {
      systemd.services = lib.mkMerge (map mkProxyTo svcConfig.services);
    }
  ]);
}
