{ pkgs, config, ... }: {
  systemd.services.ping-tracker = {
    serviceConfig = {
      Environment = "PATH=/run/wrappers/bin";
      ExecStart = [
        "${pkgs.python3.interpreter} ${./ping_tracker.py} ${config.krops.secrets."ping-tracker.json".path}"
        ''
          ${pkgs.nur.repos.mic92.healthcheck}/bin/healthcheck \
            --service ping-tracker --password-file ${config.krops.secrets."healthcheck-ping-tracker".path}
        ''
      ];
      Type = "oneshot";
      SupplementaryGroups = [ "keys" ];
      User = "ping-tracker";
    };
  };

  systemd.timers.ping-tracker = {
    description = "Update home-assistant location status";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnUnitActiveSec = "5min";
      OnBootSec = "5min";
    };
  };

  users.users.ping-tracker.group = "ping-tracker";
  users.groups.ping-tracker = {};

  krops.secrets."ping-tracker.json".owner = "ping-tracker";
  krops.secrets."healthcheck-ping-tracker".owner = "ping-tracker";

  security.wrappers.fping.source = "${pkgs.fping}/bin/fping";
}
