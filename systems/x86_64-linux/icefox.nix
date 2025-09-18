{
  nixosModules.system = { lib,  ... }:
  {
    system.stateVersion = "25.05";

    networking.hostId = "49434546";

    # TODO: Most of this file

    foxDen.hosts = [
      {
        name = "icefox";
        internal = {
          ipv4 = "192.168.1.99";
          records = [
            {
              type = "TXT";
              value = "hello";
            }
          ];
        };
        external = {
          ipv4 = "dyn";
        };
      }
      {
        name = "dummy";
        internal = {
          ipv4 = "192.168.1.100";
        };
        external = {
          ipv4 = "dyn";
        };
      }
    ];
  };
}
