{
  nixosModules.system = { lib,  ... }:
  {
    system.stateVersion = "25.05";

    networking.hostId = "42474c46";

    # TODO: Most of this file
  };
}