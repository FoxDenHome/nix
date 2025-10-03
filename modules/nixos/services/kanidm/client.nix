{ pkgs, ... } :
{
  services.kanidm = {
    enableClient = true;

    package = pkgs.kanidm_1_6; # TODO: 1.7 once 25.11

    clientSettings = {
      uri = "https://auth.foxden.network";
      verify_ca = true;
      verify_hostnames = true;
    };
  };
}
