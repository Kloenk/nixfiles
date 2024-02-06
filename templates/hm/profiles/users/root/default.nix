{ pkgs, ... }:

{
  users.users.root = {
    shell = pkgs.zsh;
    openssh.authorizedKeys.keys = [

    ];
  };
}
