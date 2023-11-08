{ lib, pkgs, tomlFormat, ... }:

let inherit (lib) mkOption mkEnableOption types literalExpression;
in {
  enable = mkEnableOption "helix text editor";

  package = mkOption {
    type = types.package;
    default = pkgs.helix;
    defaultText = literalExpression "pkgs.helix";
    description = "The package to use for helix.";
  };

  extraPackages = mkOption {
    type = with types; listOf package;
    default = [ ];
    example = literalExpression "[ pkgs.marksman ]";
    description = "Extra packages available to hx.";
  };

  defaultEditor = mkOption {
    type = types.bool;
    default = false;
    description = ''
      Whether to configure {command}`hx` as the default
      editor using the {env}`EDITOR` environment variable.
    '';
  };

  settings = mkOption {
    type = tomlFormat.type;
    default = { };
    example = literalExpression ''
      {
        theme = "base16";
        editor = {
          line-number = "relative";
          lsp.display-messages = true;
        };
        keys.normal = {
          space.space = "file_picker";
          space.w = ":w";
          space.q = ":q";
          esc = [ "collapse_selection" "keep_primary_selection" ];
        };
      }
    '';
    description = ''
      Configuration written to
      {file}`$XDG_CONFIG_HOME/helix/config.toml`.

      See <https://docs.helix-editor.com/configuration.html>
      for the full list of options.
    '';
  };

  languages = mkOption {
    type = with types;
      coercedTo (listOf tomlFormat.type) (language:
        lib.warn ''
          The syntax of programs.helix.languages has changed.
          It now generates the whole languages.toml file instead of just the language array in that file.

          Use
          programs.helix.languages = { language = <languages list>; }
          instead.
        '' { inherit language; }) (addCheck tomlFormat.type builtins.isAttrs);
    default = { };
    example = literalExpression ''
      {
        # the language-server option currently requires helix from the master branch at https://github.com/helix-editor/helix/
        language-server.typescript-language-server = with pkgs.nodePackages; {
          command = "''${typescript-language-server}/bin/typescript-language-server";
          args = [ "--stdio" "--tsserver-path=''${typescript}/lib/node_modules/typescript/lib" ];
        };

        language = [{
          name = "rust";
          auto-format = false;
        }];
      }
    '';
    description = ''
      Language specific configuration at
      {file}`$XDG_CONFIG_HOME/helix/languages.toml`.

      See <https://docs.helix-editor.com/languages.html>
      for more information.
    '';
  };

  themes = mkOption {
    type = types.attrsOf tomlFormat.type;
    default = { };
    example = literalExpression ''
      {
        base16 = let
          transparent = "none";
          gray = "#665c54";
          dark-gray = "#3c3836";
          white = "#fbf1c7";
          black = "#282828";
          red = "#fb4934";
          green = "#b8bb26";
          yellow = "#fabd2f";
          orange = "#fe8019";
          blue = "#83a598";
          magenta = "#d3869b";
          cyan = "#8ec07c";
        in {
          "ui.menu" = transparent;
          "ui.menu.selected" = { modifiers = [ "reversed" ]; };
          "ui.linenr" = { fg = gray; bg = dark-gray; };
          "ui.popup" = { modifiers = [ "reversed" ]; };
          "ui.linenr.selected" = { fg = white; bg = black; modifiers = [ "bold" ]; };
          "ui.selection" = { fg = black; bg = blue; };
          "ui.selection.primary" = { modifiers = [ "reversed" ]; };
          "comment" = { fg = gray; };
          "ui.statusline" = { fg = white; bg = dark-gray; };
          "ui.statusline.inactive" = { fg = dark-gray; bg = white; };
          "ui.help" = { fg = dark-gray; bg = white; };
          "ui.cursor" = { modifiers = [ "reversed" ]; };
          "variable" = red;
          "variable.builtin" = orange;
          "constant.numeric" = orange;
          "constant" = orange;
          "attributes" = yellow;
          "type" = yellow;
          "ui.cursor.match" = { fg = yellow; modifiers = [ "underlined" ]; };
          "string" = green;
          "variable.other.member" = red;
          "constant.character.escape" = cyan;
          "function" = blue;
          "constructor" = blue;
          "special" = blue;
          "keyword" = magenta;
          "label" = magenta;
          "namespace" = blue;
          "diff.plus" = green;
          "diff.delta" = yellow;
          "diff.minus" = red;
          "diagnostic" = { modifiers = [ "underlined" ]; };
          "ui.gutter" = { bg = black; };
          "info" = blue;
          "hint" = dark-gray;
          "debug" = dark-gray;
          "warning" = yellow;
          "error" = red;
        };
      }
    '';
    description = ''
      Each theme is written to
      {file}`$XDG_CONFIG_HOME/helix/themes/theme-name.toml`.
      Where the name of each attribute is the theme-name (in the example "base16").

      See <https://docs.helix-editor.com/themes.html>
      for the full list of options.
    '';
  };
}
