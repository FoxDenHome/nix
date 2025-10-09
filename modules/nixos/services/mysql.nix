{ foxDenLib, pkgs, lib, config, ... }:
let
  services = foxDenLib.services;

  svcConfig = config.foxDen.services.mysql;
in
{
  options.foxDen.services.mysql = services.mkOptions { svcName = "mysql"; name = "MySQL"; } // {
    users = with lib.types; lib.mkOption {
      type = attrsOf userType;
    };
    services = with lib.types; lib.mkOption {
      type = listOf str;
      default = [ ];
      description = "List of systemd services connecting to MySQL";
    };
    dbUsers = with lib.types; lib.mkOption {
      type = listOf str;
      default = [ ];
      description = "List of users connecting to MySQL";
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
        initialDatabases = lib.attrsets.genAttrs svcConfig.dbUsers (name: {
          inherit name;
        });
        ensureUsers = lib.attrsets.genAttrs svcConfig.dbUsers (name: {
          inherit name;
          ensurePermissions = {
            "${name}.*" = "ALL PRIVILEGES";
          };
        });
      };

      systemd.service.mysql = {
        serviceConfig = {
          DynamicUser = true;
          StateDirectory = "mysql";
        }
      }
    }
    {
      systemd.services = lib.attrsets.genAttrs svcConfig.services (svc: {
        requires = [ "mysql.service" ];
        after = [ "mysql.service" ];
        serviceConfig = {
          BindReadOnlyPaths = [
            "/run/mysql"
          ];
          Environment = [
            "MYSQL_SOCKET=/run/mysql/mysql.sock"
            "MYSQL_DATABASE=${svc}"
            "MYSQL_USERNAME=${svc}"
          ];
        };
      });
    }
  ]);
}