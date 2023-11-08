{ pkgs, ... }: {
    programs.helix = {
      enable = true;
      settings = {
        theme = "monokai";
        editor.soft-wrap = {
          enable = true;
          max-wrap = 25; # increase value to reduce forced mid-word wrapping
          max-indent-retain = 0;
          wrap-indicator = "";  # set wrap-indicator to "" to hide it
        };
      };
      languages.language = [
        {
          name = "nix";
          language-servers = [ "nil" ];
        }
        {
          name = "rust";
          language-servers = [ "rust-analyzer" ];
        }
      ];
      languages.language-server = {
        nil = {
          command = "${pkgs.nil}/bin/nil";
        };
        rust-analyzer = {
          command = "${pkgs.rust-analyzer}/bin/rust-analyzer";
          config = {
            cargo = {
              buildScripts = {
                enable = true;
              };
            };
            procMacro = {
              enable = true;
            };
          };
        };
      };
      # languages.language = [
      #   {
      #     name = "latex";
      #     config.texlab = {
      #       build = {
      #         onSave = true;
      #         args = ["-xelatex" "-interaction=nonstopmode" "-synctex=1" "%f"];
      #         #executable = "tectonic";
      #         #args = [
      #           #"-X"
      #           #"compile"
      #           #"%f"
      #           #"--synctex"
      #           #"--keep-logs"
      #           #"--keep-intermediates"
      #         #];
      #       };
      #     };
      #   }
      # ];
    };
}
