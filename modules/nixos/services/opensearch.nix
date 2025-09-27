{ foxDenLib, uds-proxy, pkgs, lib, config, ... }:
let
  services = foxDenLib.services;

  svcConfig = config.foxDen.services.opensearch;

  udsProxyPkg = uds-proxy.packages.${config.nixpkgs.hostPlatform.system}.default;
in
{
  options.foxDen.services.opensearch = services.mkOptions { svcName = "opensearch"; name = "OpenSearch"; };

  config = lib.mkIf svcConfig.enable (lib.mkMerge [
    (services.make {
      name = "opensearch";
      inherit svcConfig pkgs config;
    }).config
    (services.make {
      name = "opensearch-uds";
      inherit svcConfig pkgs config;
    }).config
    {
      services.opensearch.enable = true;

      systemd.services.opensearch-uds = {
        serviceConfig = {
          DynamicUser = true;
          Type = "simple";
          RuntimeDirectory = "opensearch";
          ExecStart = ["${udsProxyPkg}/bin/uds-proxy -socket /run/opensearch/opensearch.sock -socket-mode 0777 -force-remote-host 127.0.0.1:9200"];
        };
      };

      environment.systemPackages = [
        udsProxyPkg
      ];
    }
  ]);
}
