locals {
  archived_repositores = {
    accounts-client               = {}
    BarAPI                        = {}
    BungeeFailover                = {}
    ChatLinkRouter                = {}
    ChatLinkRouter_Java           = {}
    collectivization-maven-plugin = {}
    config-dependency             = {}
    DependencyBuilder             = {}
    DiscordLink                   = {}
    dynmap                        = {}
    FBoxLiHTTPd                   = {}
    fox-bukkit-chat               = {}
    fox-bukkit-lua                = {}
    fox-bukkit-lua-modules        = {}
    fox-bukkit-permissions        = {}
    FoxBukkitBadge                = {}
    FoxBukkitChatLink             = {}
    FoxBukkitCheckoff             = {}
    FoxBukkitScoreboard           = {}
    FoxBukkitSlackLink            = {}
    FoxBungee                     = {}
    FoxelBoxAndroid               = {}
    FoxelBoxAPI                   = {}
    FoxelBoxChatForge             = {}
    FoxelBoxClient                = {}
    FoxelLog                      = {}
    iOS                           = {}
    LogBlock                      = {}
    LowSecurity                   = {}
    MultiBukkit                   = {}
    Organization                  = {}
    packages                      = {}
    plexus-compiler-luaj          = {}
    RavenBukkit                   = {}
    redis-dependency              = {}
    Remote-Entities               = {}
    RestartIfEmpty                = {}
    SpigotPatcher                 = {}
    StaticWorld                   = {}
    TechnicServerPlatform         = {}
    TechnicSolder                 = {}
    threading-dependency          = {}
    VoidGenerator                 = {}
    zOLD_BungeeAntiProxy          = {}
    zOLD_BungeeReloader           = {}
    zOLD_FoxBukkit                = {}
    zOLD_MCSecurityManager        = {}
  }
}

module "archived_repo" {
  source = "../modules/repo/archived"

  for_each = local.archived_repositores

  repository = merge({
    name = each.key

    visibility = "public"
  }, each.value)
}
