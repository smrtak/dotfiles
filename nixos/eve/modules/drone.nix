{ pkgs, config, ... }:

let
  droneserver = config.users.users.droneserver.name;
in {
  systemd.services.drone-server = {
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      EnvironmentFile = [
        config.sops.secrets.drone.path
      ];
      Environment = [
        "DRONE_DATABASE_DATASOURCE=postgres:///droneserver?host=/run/postgresql"
        "DRONE_DATABASE_DRIVER=postgres"
        "DRONE_SERVER_PORT=:3030"
        "DRONE_USER_CREATE=username:Mic92,admin:true"
      ];
      ExecStart = "${pkgs.drone}/bin/drone-server";
      User = droneserver;
      Group = droneserver;
    };
  };

  services.postgresql = {
    ensureDatabases = [ droneserver ];
    ensureUsers = [{
      name = droneserver;
      ensurePermissions = {
        "DATABASE ${droneserver}" = "ALL PRIVILEGES";
      };
    }];
  };

  services.nginx.virtualHosts."drone.thalheim.io" = {
    useACMEHost = "thalheim.io";
    forceSSL = true;
    locations."/".extraConfig = ''
      proxy_pass http://localhost:3030;
    '';
  };

  systemd.services.drone-runner-exec = {
    wantedBy = [ "multi-user.target" ];
    # might break deployment
    restartIfChanged = false;
    confinement.enable = true;
    confinement.packages = [
      pkgs.git
      pkgs.gnutar
      pkgs.bash
      pkgs.nix
      pkgs.gzip
    ];
    serviceConfig = {
      Environment = [
        "DRONE_RUNNER_CAPACITY=10"
        "CLIENT_DRONE_RPC_HOST=127.0.0.1:3030"
      ];
      BindPaths = [
        "/nix/var/nix/daemon-socket/socket"
      ];
      BindReadOnlyPaths = [
        "/nix/var/nix/profiles/system/etc/nix:/etc/nix"
        "/var/lib/drone/nix-build"
        "${config.environment.etc."ssl/certs/ca-certificates.crt".source}:/etc/ssl/certs/ca-certificates.crt"
        "/etc/machine-id"
        # channels are dynamic paths in the nix store, therefore we need to bind mount the whole thing
        "/nix/store"
      ];
      EnvironmentFile = [ config.sops.secrets.drone.path ];
      ExecStart = "${pkgs.nur.repos.mic92.drone-runner-exec}/bin/drone-runner-exec";
      User = "drone-runner-exec";
      Group = "drone-runner-exec";
    };
  };
  users.users.drone-runner-exec = {
    isSystemUser = true;
    group = "drone-runner-exec";
  };
  users.groups.drone-runner-exec = {};

  users.users.droneserver = {
    isSystemUser = true;
    createHome = true;
    group = droneserver;
  };
  users.groups.droneserver = {};

  sops.secrets.drone = { };
}
