{ config, pkgs, lib, ... } :
let
  idents = config.security.polkit.adminIdentities;

  identChecks = lib.concatStringsSep " || " (map (ident: "subject.isInGroup('${lib.strings.removePrefix "unix-group:" ident}')") idents);

  polkitRules = pkgs.writers.writeText "05-foxden.rules" ''
    polkit.addAdminRule(function(action, subject) {
      if (${identChecks}) {
        return ["unix-user:"+subject.user];
      } else {
        return [polkit.Result.NO];
      }
    });
  '';
in
{
  config = {
    systemd.services.polkit.restartTriggers = [ polkitRules.path ];
    environment.etc."polkit-1/rules.d/05-foxden.rules".source = polkitRules;
  };
}
