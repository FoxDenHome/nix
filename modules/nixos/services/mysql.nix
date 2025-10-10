{ foxDenLib, pkgs, lib, config, ... }:
let
  services = foxDenLib.services;

  svcConfig = config.foxDen.services.mysql;

  serviceType = with lib.types; submodule {
    options = {
      name = lib.mkOption {
        type = str;
      };
      proxy = lib.mkEnableOption "Enable MySQL proxy for 127.0.0.1 access";
      targetService = lib.mkOption {
        type = str;
      };
    };
  };

  mkProxyTo = (clientSvc: if clientSvc.proxy then (lib.mkMerge [
    (services.make {
      name = "mysql-${clientSvc.name}";
      overrideHost = config.foxDen.services.${clientSvc.name}.host;
      inherit svcConfig pkgs config;
    }).config.systemd.services
    {
      "mysql-${clientSvc.name}" = {
        wantedBy = [ "multi-user.target" ];

        serviceConfig = {
          Type = "simple";
          User = clientSvc.name;
          Group = clientSvc.name;
          ExecStart = [
            "${pkgs.socat}/bin/socat TCP-LISTEN:3306,bind=127.0.0.1,reuseaddr,fork UNIX-CLIENT:/run/mysqld/mysqld.sock"
          ];
        };
      };
    }
  ]) else {});
in
{
  options.foxDen.services.mysql = services.mkOptions { svcName = "mysql"; name = "MySQL"; } // {
    services = with lib.types; lib.mkOption {
      type = listOf serviceType;
      default = [ ];
      description = "List of systemd services connecting to MySQL";
    };
  };

  config = lib.mkIf svcConfig.enable (lib.mkMerge [
    (services.make {
      name = "mysql";
      inherit svcConfig pkgs config;
    }).config
    {
      foxDen.services.mysql.host = "mysql";

      foxDen.hosts.hosts = {
        mysql.interfaces = {};
      };

      services.mysql = {
        enable = true;
        package = pkgs.mariadb;
        settings = {
          mysqld = {
            skip-networking = true;
          };
        };
        initialDatabases = map (svc: {
          inherit (svc) name;
        }) svcConfig.services;
        ensureUsers = map (svc: {
          name = if svc.proxy then "mysql-${svc.name}" else svc.targetService;
          ensurePermissions = {
            "${svc.name}.*" = "ALL PRIVILEGES";
          };
        }) svcConfig.services;
      };

      systemd.services.mysql = {
        serviceConfig = {
          PrivateUsers = false;
          StateDirectory = "mysql";
          BindReadOnlyPaths = [
            "/etc/my.cnf"
          ];
        };
      };

      environment.persistence."/nix/persist/mysql" = {
        hideMounts = true;
        directories = [
          { directory = "/var/lib/mysql"; user = config.services.mysql.user; group = config.services.mysql.group; mode = "u=rwx,g=rx,o="; }
        ];
      };
    }
    {
      systemd.services = lib.attrsets.listToAttrs (map (mySvc: let
        svcName = if mySvc.proxy then "mysql-${mySvc.name}" else mySvc.targetService;
      in
      {
        name = svcName;
        value = {
          requires = [ "mysql.service" ];
          after = [ "mysql.service" ];
          serviceConfig = {
            BindReadOnlyPaths = [
              "/run/mysqld"
            ];
            Environment = [
              "MYSQL_SOCKET=/run/mysqld/mysqld.sock"
            ];
          };
        };
      }) svcConfig.services);
    }
    {
      systemd.services = lib.attrsets.listToAttrs (map (mySvc: let
        svcName = if mySvc.proxy then "mysql-${mySvc.name}" else mySvc.targetService;
      in
      {
        name = mySvc.targetService;
        value = let
          deps = if mySvc.proxy then ["${svcName}.service"] else [];
        in {
          requires = deps;
          after = deps;
          serviceConfig = {
            Environment = [
              "MYSQL_DATABASE=${mySvc.name}"
              "MYSQL_USERNAME=${svcName}"
            ] ++ (if mySvc.proxy then [
              "MYSQL_HOST=127.0.0.1"
              "MYSQL_PORT=3306"
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
