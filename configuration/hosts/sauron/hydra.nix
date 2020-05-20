{ config, pkgs, ... }:

{

  fileSystems."/var/lib/hydra" = {
    device = "/persist/data/hydra";
    fsType = "none";
    options = [ "bind" ];
  };

  services.hydra = {
    enable = true;
    package = pkgs.hydra-patched;
    port = 3015;
    listenHost = "0.0.0.0";
    notificationSender = "hydra@kloenk.de";

    hydraURL = "hydra.kloenk.de";
  };
  nix.trustedUsers = [ "hydra" ];

  services.nginx.virtualHosts."hydra.kloenk.de" = {
    enableACME = true;
    forceSSL = true;
    locations."/".proxyPass = "http://127.0.0.1:3015";
  };

  nix.buildMachines = [{
    hostName = "lycus.yougen.de";
    sshUser = "buildfarm";
    sskKey = config.krops.secrets.files."buildkey".path;
    system = "x86_64-linux";
    maxJobs = 8;
    speedFactor = 1;
    supportedFeatures = [ "kvm" "nixos-test" "benchmark" "big-parallel" ];
  }];
  krops.secrets.files."buildkey".owner = "root";
}