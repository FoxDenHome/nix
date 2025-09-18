{
  nixosModules.system = { lib,  ... }:
  {
    system.stateVersion = "25.05";

    networking.hostId = "49434546";

    # TODO: Most of this file

    foxDen.dnsRecords = [
      {
        name = "icefox";
        type = "A";
        value = "192.168.1.100";
      }
    ];
  };
}
