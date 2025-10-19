{ foxDenLib, ... } :
{
  foxDen.firewall.rules = map (rule: rule // {
    table = "filter";
    chain = "forward";
    action = "accept";
    destination = if foxDenLib.util.isIPv4 rule.source then "10.99.0.0/16" else "fd2c:f4cb:63be::a64:0/112";
  }) (foxDenLib.firewall.templates.trusted "s2s-network");
}
