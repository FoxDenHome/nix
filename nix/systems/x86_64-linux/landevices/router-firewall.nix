{ ... } :
{
  foxDen.firewall.rules = [
    {
      source = "10.0.0.0/8";
      destination = "!10.0.0.0/8";
      action = "masquerade";
      table = "nat";
      chain = "postrouting";
    }
    {
      source = "172.17.0.0/16";
      destination = "!172.17.0.0/16";
      action = "masquerade";
      table = "nat";
      chain = "postrouting";
    }
    {
      destination = "127.0.0.1";
      action = "jump";
      table = "nat";
      chain = "prerouting";
      jumpTarget = "port-forward";
      comment = "Hairpin";
    }
    {
      destination = "127.0.0.2";
      action = "jump";
      table = "nat";
      chain = "prerouting";
      jumpTarget = "port-forward";
      comment = "Hairpin fallback";
    }
  ];
}
