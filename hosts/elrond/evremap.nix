{ ... }:

{
  programs.evremap = {
    enable = true;
    devices."Das Keyboard" = {
      device_name = "Metadot - Das Keyboard DK5QS";
      remap = [
        {
          input = [ "KEY_LEFTALT" ];
          output = [ "KEY_LEFTMETA" ];
        }
        {
          input = [ "KEY_LEFTMETA" ];
          output = [ "KEY_LEFTALT" ];
        }
      ];
    };
  };
}
