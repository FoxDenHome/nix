{ nixpkgs, foxDenLib, ... }:
let
  lib = nixpkgs.lib;
  util = foxDenLib.util;
  mkHost = foxDenLib.global.dns.mkHost;
  globalConfig = foxDenLib.global.config;

  mkForGateway = gateway: allHosts: let
    hosts = lib.lists.filter (val: val.gateway == gateway) allHosts;

    renderMatchers = (cfgName: varName: nixpkgs.lib.concatStringsSep "\n" (nixpkgs.lib.flatten (
      map (host: let
        portCfg = host.${cfgName};
        name = "${cfgName}_${nixpkgs.lib.lists.head host.names}";
      in if portCfg.host != null then (map (hostName:
        "  acl acl_${name} ${varName} -i ${hostName}"
      ) host.names) ++ [
        "  use_backend be_${name} if acl_${name}"
      ] else []) hosts)));

    renderBackends = (cfgName: mode: options: nixpkgs.lib.concatStringsSep "\n" (
      map (host: let
        portCfg = host.${cfgName};
        name = "${cfgName}_${nixpkgs.lib.lists.head host.names}";
        flags = if portCfg.proxyProtocol then ["send-proxy-v2"] else [];
      in if portCfg.host != null then ''
        backend be_${name}
          mode ${mode}
        ${if options != [] then nixpkgs.lib.concatStringsSep "\n" (map (opt: "  option ${opt}") options) else ""}
          server srv_main ${portCfg.host}:${builtins.toString portCfg.port} ${nixpkgs.lib.concatStringsSep " " flags}
      '' else "") hosts
    ));
  in ''
    global
      log stdout format raw local0 info

    defaults
      log global
      timeout client 30s
      timeout server 30s
      timeout connect 5s
      option dontlognull

    frontend fe_https
      bind :443
      mode tcp
      option tcplog
      tcp-request inspect-delay 5s
      tcp-request content accept if { req_ssl_hello_type 1 }
    ${renderMatchers "https" "req.ssl_sni"}

    frontend fe_http
      bind :80
      mode http
      option httplog
    ${renderMatchers "http" "hdr(host)"}

    ${renderBackends "http" "http" ["forwardfor"]}

    ${renderBackends "https" "tcp" ["ssl-hello-chk"]}

  '';
in
{
  nixosModule = { config, ... } : let
    protoCfgType = defPort: with lib.types; submodule {
      options = {
        host = lib.mkOption {
          type = nullOr str;
          default = null;
        };
        proxyProtocol = lib.mkOption {
          type = bool;
          default = true;
        };
        port = lib.mkOption {
          type = ints.u16;
          default = defPort;
        };
      };
    };

    hostType = with lib.types; submodule {
      options = {
        names = lib.mkOption {
          type = listOf str;
        };
        http = lib.mkOption {
          type = protoCfgType 80;
          default = {};
        };
        https = lib.mkOption {
          type = protoCfgType 443;
          default = {};
        };
        gateway = lib.mkOption {
          type = str;
          default = config.foxDen.hosts.gateway;
        };
      };
    };

    renderInterface = (hostName: ifaceObj: let
      iface = ifaceObj.value;
      privateIPv4 = lib.findFirst (ip: let
        ipNoCidr = util.removeIPCidr ip;
      in (util.isIPv4 ipNoCidr) && (util.isPrivateIP ipNoCidr)) "" iface.addresses;
      host = util.removeIPCidr privateIPv4;
    in lib.mkIf (privateIPv4 != "" && iface.webservice.enable) {
      inherit (iface) gateway;
      names = map mkHost ([iface.dns] ++ iface.cnames);
      http = {
        inherit host;
        inherit (iface.webservice) proxyProtocol;
        port = iface.webservice.httpPort;
      };
      https = {
        inherit host;
        inherit (iface.webservice) proxyProtocol;
        port = iface.webservice.httpsPort;
      };
    });

    renderHost = { name, value }: map (iface: renderInterface name iface) (lib.attrsets.attrsToList value.interfaces);
  in
  {
    options.foxDen.haproxy.hosts = with lib.types; lib.mkOption {
      type = listOf hostType;
      default = {};
    };
    config.foxDen.haproxy.hosts = lib.flatten (map renderHost (nixpkgs.lib.attrsets.attrsToList config.foxDen.hosts.hosts));
  };

  getForGateway = config: gateway: mkForGateway gateway config.foxDen.haproxy;

  make = nixosConfigurations: let
    hosts = globalConfig.getList ["foxDen" "haproxy" "hosts"] nixosConfigurations;
    gateways = foxDenLib.global.hosts.getGateways nixosConfigurations;
  in lib.attrsets.genAttrs gateways (gateway:
    mkForGateway gateway hosts
  );
}
