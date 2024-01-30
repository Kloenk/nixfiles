{ pkgs, lib, ... }:

let
  ignore = [
    ".venv"
    ".idea"
    ".tmp"
    "*.iml"
    ".DS_Store"
    "target/"
    "result"
    "result-*"
    ".direnv/"
  ];
  ignoreFile = pkgs.writeText "gitignore" (lib.concatStringsSep "\n" ignore);
in {
  programs.git = {
    enable = true;
    config = {
      branch.sort = "-committerdate";
      core.excludesFile = ignoreFile;
      color.ui = true;
      init.defaultBranch = "main";
      user = {
        email = "me@kloenk.de";
        name = "Finn Behrens";
      };
      alias = { ls = "status"; };
      # feature.manyFiles = true;
      push.autoSetupRemote = true;
    };
  };
}
