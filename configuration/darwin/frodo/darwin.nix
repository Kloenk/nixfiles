{ config, lib, pkgs, ... }:

{
  imports = [
    ../../common/darwin.nix
  ];

  environment.systemPackages = with pkgs; [
    #pkgs.vim
  ];

  networking.hostName = "frodo";

  services.nix-daemon.enable = true;
  nix.package = pkgs.nix;
  nix.extraOptions = ''
    extra-platforms = x86_64-darwin aarch64-darwin
    system-features = benchmark big-parallel recursive-nix
  '';

  users.users.kloenk.packages = with pkgs; [
    elixir
    erlang

    # emacs language servers
    elixir_ls
    irony-server
    sbcl
    sops

    sqlite-web
  ];

  services.epmd.enable = true;
  services.telegraf = {
    enable = true;
    configUrl = "https://influx.kloenk.dev/api/v2/telegrafs/08e1104547058000";
    environmentFiles = [ "/etc/telegraf.env" ];
  };

}
