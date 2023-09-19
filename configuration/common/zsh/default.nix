{ lib, pkgs, config, ... }:

{
  environment.pathsToLink = [ "/share/zsh" ];

  environment.systemPackages = with pkgs; [ fzf eza ripgrep direnv ];

  programs.zsh = {
    enable = true;
    interactiveShellInit = ''
      function use {
        packages=()
        packages_fmt=()
        while [ "$#" -gt 0 ]; do
          i="$1"; shift 1
          packages_fmt+=$(echo $i | ${pkgs.gnused}/bin/sed 's/[a-zA-Z]*#//')
          [[ $i =~ [a-zA-Z]*#[a-zA-Z]* ]] || i="kloenk#$i"
          packages+=$i
        done
        env prompt_sub="%F{blue}($packages_fmt) %F{white}$PROMPT" nix shell $packages
      }
      PROMPT=''${prompt_sub:=$PROMPT}

      source ${pkgs.fzf}/share/fzf/completion.zsh
      source ${pkgs.fzf}/share/fzf/key-bindings.zsh

      fzf-store() {
        find /nix/store -maxdepth 1 -mindepth 1 -type d  | fzf -m --preview-window right:50% --preview 'nix-store -q --tree {}'
      }

      # completion foo
      function _nix() {
        local ifs_bk="$IFS"
        local input=("''${(Q)words[@]}")
        IFS=$'\n'
        local res=($(NIX_GET_COMPLETIONS=$((CURRENT - 1)) "$input[@]"))
        IFS="$ifs_bk"
        local tpe="$res[1]"
        local suggestions=(''${res:1})
        if [[ "$tpe" == filenames ]]; then
          compadd -fa suggestions
        else
          compadd -a suggestions
        fi
      }
      compdef _nix nix

      eval "$(direnv hook zsh)"
    '';
    syntaxHighlighting.enable = true;
    enableCompletion = true;
    autosuggestions.enable = true;
    setOptions = [ "AUTO_CD" ];
    ohMyZsh = {
      enable = true;
      theme = "fishy";
      plugins = [
        #"git"
        "sudo"
        "ripgrep"
      ];
    };
    shellAliases = {
      ls = "eza";
      l = "eza -a";
      ll = "eza -lgh";
      la = "eza -lagh";
      lt = "eza -T";
      lg = "eza -lagh --git";
    };
  };
}
