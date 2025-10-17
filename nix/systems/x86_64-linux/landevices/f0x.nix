{ ... } :
{
  config.foxDen.dns.records = [
    {
      zone = "f0x.es";
      name = "c0de";
      type = "CNAME";
      ttl = 3600;
      value = "c0defox.es.";
      horizon = "*";
    }
  ];
}
