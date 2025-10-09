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

  serviceList = map (svc: svc.name) svcConfig.services;

  mkProxyTo = (clientSvc: if clientSvc.proxy then (lib.mkMerge [
    (services.make {
      name = "mysql-${clientSvc.targetService}";
      overrideHost = config.foxDen.services.${clientSvc.targetService}.host;
      inherit svcConfig pkgs config;
    }).config
    {
      systemd.services."mysql-${clientSvc.targetService}" = {
        wantedBy = [ "multi-user.target" ];

        serviceConfig = {
          DynamicUser = true;
          Type = "simple";
          ExecStart = [
            "${pkgs.socat}/bin/socat TCP-LISTEN:3306,bind=127.0.0.1,reuseaddr,fork UNIX-CLIENT:$MYSQL_SOCKET"
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
        initialDatabases = lib.attrsets.genAttrs serviceList (name: {
          inherit name;
        });
        ensureUsers = lib.attrsets.genAttrs serviceList (name: let
          clientSvc = svcConfig.services.${name};
        in
        {
          name = if clientSvc.proxy then "mysql-${name}" else name;
          ensurePermissions = {
            "${name}.*" = "ALL PRIVILEGES";
          };
        });
      };

      systemd.service.mysql = {
        serviceConfig = {
          DynamicUser = true;
          StateDirectory = "mysql";
        };
      };
    }
    {
      systemd.services = lib.attrsets.listToAttrs map (mySvc: let
        svcName = if mySvc.proxy then "mysql-${mySvc.name}" else mySvc.targetService;
      in
      {
        name = svcName;
        value = {
          requires = [ "mysql.service" ];
          after = [ "mysql.service" ];
          serviceConfig = {
            BindReadOnlyPaths = [
              "/run/mysql"
            ];
            Environment = [
              "MYSQL_SOCKET=/run/mysql/mysql.sock"
            ];
          };
        };
      }) (lib.attrsets.attrsToList svcConfig.services);
    }
    {
      systemd.services = lib.attrsets.listToAttrs map (mySvc: let
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
            ];
          };
        };
      }) (lib.attrsets.attrsToList svcConfig.services);
    }
    (map mkProxyTo svcConfig.services)
  ]);
}