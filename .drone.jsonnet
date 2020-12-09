local environment = {
  BUILDDIR: '/var/lib/drone/nix-build',
};

local build = {
  name: 'Build NixOS and home-manager',
  kind: 'pipeline',
  type: 'exec',
  steps: [{
    name: 'build',
    commands: [
      'rm -rf $BUILDDIR/gcroots.tmp && mkdir -p $BUILDDIR/gcroots.tmp',
      'nix shell nixpkgs#git nixpkgs#nix-build-uncached -c nix-build-uncached -build-flags "--out-link $BUILDDIR/gcroots.tmp/result" ./nixos/ci.nix',
      'rm -rf $BUILDDIR/gcroots && mv $BUILDDIR/gcroots.tmp $BUILDDIR/gcroots',
    ],
    environment: environment,
  }, {
    name: 'upload',
    commands: [
      "if stat -t $BUILDDIR/gcroots/result* >/dev/null 2>&1; then
        nix path-info --json -r $BUILDDIR/gcroots/result* > $BUILDDIR/path-info.json
        # only local built derivations
        nix shell 'nixpkgs#jq' -c jq -r 'map(select(.ca == null and .signatures == null)) | map(.path) | .[]' < $BUILDDIR/path-info.json > paths
        nix shell 'nixpkgs#cachix' -c cachix push --jobs 32 mic92 < paths
      fi",
    ],
    environment: environment {
      CACHIX_SIGNING_KEY: {
        from_secret: 'CACHIX_SIGNING_KEY',
      },
    },
    when: {
      event: { exclude: ['pull_request'] },
      status: ['failure', 'success'],
    },
  }, {
    name: 'send irc notification',
    environment: environment,
    commands: [
      'LOGNAME=drone nix run .#irc-announce -- irc.r 6667 drone "#xxx" "build $DRONE_SYSTEM_PROTO://$DRONE_SYSTEM_HOST/$DRONE_REPO/$DRONE_BUILD_NUMBER : $DRONE_BUILD_STATUS" || true'
    ],
    when: {
      event: { exclude: ['pull_request'] },
      status: ['failure', 'success'],
    },
  }],
  trigger: {
    event: {
      exclude: ['promote', 'rollback'],
    },
  },
};

local deploy(target) = {
  name: 'Deploy to ' + target,
  kind: 'pipeline',
  steps: [{
    name: 'deploy',
    commands: [
      'install -D /nix/var/nix/profiles/system/etc/ssh/ssh_known_hosts $HOME/.ssh/known_hosts',
      'echo "Host eve.thalheim.io\nForwardAgent yes" > $HOME/.ssh/config',
      'eval $(ssh-agent) && ' +
      'echo "$DEPLOY_SSH_KEY" | ssh-add - && ' +
      'nix run .#deploy.%s' % target,
    ],
    environment: environment {
      DEPLOY_SSH_KEY: { from_secret: 'DEPLOY_SSH_KEY' },
    },
  }],
  trigger: { event: ['promote', 'rollback'] },
};

[
  build,
  deploy('eve'),
  deploy('turingmachine'),
  deploy('eva'),
  deploy('rock'),
  deploy('joerg@turingmachine'),
  #deploy('eddie'),
  #deploy('joerg@eddie'),
  deploy('joerg@eve'),
]
