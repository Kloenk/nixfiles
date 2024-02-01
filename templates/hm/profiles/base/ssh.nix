{ lib, ... }:

let
  params = {
    Ciphers = [
      "chacha20-poly1305@openssh.com"
      "aes256-gcm@openssh.com"
      "aes128-gcm@openssh.com"
      "aes256-ctr"
      "aes192-ctr"
      "aes128-ctr"
    ];
    KexAlgorithms = [
      "curve25519-sha256"
      "curve25519-sha256@libssh.org"
      "diffie-hellman-group16-sha512"
      "diffie-hellman-group18-sha512"
      "diffie-hellman-group-exchange-sha256"
      "diffie-hellman-group14-sha256"
    ];
    Macs = [
      "hmac-sha2-256-etm@openssh.com"
      "hmac-sha2-512-etm@openssh.com"
      "umac-128-etm@openssh.com"
    ];
    HostKeyAlgorithms = [
      "ssh-ed25519"
      "ssh-ed25519-cert-v01@openssh.com"
      "sk-ssh-ed25519@openssh.com"
      "sk-ssh-ed25519-cert-v01@openssh.com"
      "rsa-sha2-256"
      "rsa-sha2-256-cert-v01@openssh.com"
      "rsa-sha2-512"
      "rsa-sha2-512-cert-v01@openssh.com"
    ];
  };
in {
  services.openssh = {
    enable = true;
    ports = [ 22 ];
    settings = {
      PasswordAuthentication = lib.mkDefault false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = lib.mkDefault "prohibit-password";
      inherit (params) Ciphers Macs KexAlgorithms;
      HostKeyAlgorithms = lib.concatStringsSep "," params.HostKeyAlgorithms;
    };

    hostKeys = [{
      path = "/persist/data/openssh/ed25519_key";
      type = "ed25519";
    }];

    extraConfig = ''
      StreamLocalBindUnlink yes
    '';
  };

  programs.ssh = {
    ciphers = params.Ciphers;
    macs = params.Macs;
    kexAlgorithms = params.KexAlgorithms;
    hostKeyAlgorithms = params.HostKeyAlgorithms;
    pubkeyAcceptedKeyTypes = [
      "sk-ssh-ed25519@openssh.com"
      "ssh-ed25519"
      # Slightly less secure options:
      # - RSA is weakening
      "ssh-rsa"
      # - NIST P-256 curve may or may not be backdoored
      "ecdsa-sha2-nistp256"
    ];
    extraConfig = ''
      ControlMaster auto
      ControlPath ~/.ssh/%r@%h.sock
      ControlPersist 5m
    '';
  };

  programs.ssh.knownHosts = {
    cyberchaos = {
      hostNames = [ "cyberchaos.dev" ];
      publicKey =
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIB994/Dz2G4vKDYeC1PQ445OKaaJLWdM6I+PBvHRDLa5";
    };

    # well known hosts
    "aarch64.nixos.community" = {
      publicKey =
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMUTz5i9u5H2FHNAmZJyoJfIGyUm/HfGhfwnc142L3ds";
    };
    "gitlab.com" = {
      publicKey =
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAfuCHKVTjquxvt6CM6tdG4SLp1Btn/nOeHHE5UOzRdf";
    };
    "github.com" = {
      publicKey =
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl";
    };
    "git.sr.ht" = {
      publicKey =
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMZvRd4EtM7R+IHVMWmDkVU3VLQTSwQDSAvW0t2Tkj60";
    };
  };

  sops.age.sshKeyPaths = [ "/persist/data/openssh/ed25519_key" ];
}
