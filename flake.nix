{
  description = "FoxDen NixOS config";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    impermanence.url = "github:nix-community/impermanence";
    lanzaboote.url = "github:nix-community/lanzaboote";
    lanzaboote.inputs.nixpkgs.follows = "nixpkgs";
    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";

    uds-proxy.url = "github:Doridian/uds-proxy";
    uds-proxy.inputs.nixpkgs.follows = "nixpkgs";
    fadumper.url = "github:Doridian/fadumper";
    fadumper.inputs.nixpkgs.follows = "nixpkgs";
    gitbackup.url = "github:Doridian/gitbackup";
    gitbackup.inputs.nixpkgs.follows = "nixpkgs";
    superfan.url = "github:Doridian/superfan";
    superfan.inputs.nixpkgs.follows = "nixpkgs";
    foxingress.url = "github:Doridian/foxIngress";
    foxingress.inputs.nixpkgs.follows = "nixpkgs";
    e621dumper.url = "github:FoxDenHome/e621dumper";
    e621dumper.inputs.nixpkgs.follows = "nixpkgs";
    backupmgr.url = "github:FoxDenHome/backupmgr";
    backupmgr.inputs.nixpkgs.follows = "nixpkgs";
    oauth-jit-radius.url = "github:Doridian/oauth-jit-radius";
    oauth-jit-radius.inputs.nixpkgs.follows = "nixpkgs";
    njs-mirror-nginx.url = ./modules/flakes/nginx/mirror;
    njs-mirror-nginx.inputs.nixpkgs.follows = "nixpkgs";
    doridian-website.url = ./modules/flakes/doridian-website;
    doridian-website.inputs.nixpkgs.follows = "nixpkgs";
    spaceage-api.url = "github:SpaceAgeMP/space_age_api";
    spaceage-api.inputs.nixpkgs.follows = "nixpkgs";
    spaceage-website.url = "github:SpaceAgeMP/website";
    spaceage-tts.url = "github:SpaceAgeMP/TTS";
    spaceage-tts.inputs.nixpkgs.follows = "nixpkgs";
    tapemgr.url = "github:FoxDenHome/tapemgr";
    tapemgr.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = (inputs: import ./outputs.nix inputs);
}
