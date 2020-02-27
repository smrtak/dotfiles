{ lib, ... }: with lib; {
  nix = {
    trustedUsers = ["joerg" "root"];
    useSandbox = true;
    buildCores = 0;
    gc.automatic = true;
    gc.dates = "03:15";

    # should be enough?
    nrBuildUsers = 32;

    # https://github.com/NixOS/nix/issues/719
    extraOptions = ''
      builders-use-substitutes = true
      max-jobs = auto
      gc-keep-outputs = true
      gc-keep-derivations = true
    '';

    nixPath = let
      kropsSources = filter (src: src != ".populate")
        (attrNames (builtins.readDir "/var/src"));
    in (map (entry: "${entry}=/var/src/${entry}") kropsSources) ++ [
      "/nix/var/nix/profiles/per-user/root/channels"
    ];
  };

  imports = [ ./builder.nix ];

  nixpkgs.config.allowUnfree = true;
}
