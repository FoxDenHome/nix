{ ... }:
{
  mkHostService = ({ name, ... }:
    {
      host = ({ config, ... }: config.foxDen.hosts.${name});
      enabled = ({ config, ... }: (config.foxDen.hosts.${name} or null) != null);
    });
}
