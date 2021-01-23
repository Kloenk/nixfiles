{ pkgs, config, ... }:

{
  services.engelsystem = {
    enable = true;
    domain = "punkte.kloenk.de";
    config = {
      maintenance = false;
      database.username = "engelsystem";
      email = {
        driver = "smtp";
        from.address = "noreply-punkte@kloenk.de";
        from.name = "Abi 2021 Punktesystem";
        encryption = "tls";
        username = "noreply-punkte@kloenk.de";
        password._secret = config.petabyte.secrets."es_mail_password".path;
      };
      autoarrive = true;
      min_password_length = 6;
      enable_dect = false;
      enable_user_name = true;
      enable_planned_arrival = false;
      night_shifts.enabled = false;
      default_locale = "de_DE";
    };
  };

  petabyte.secrets."es_mail_password".owner = "engelsystem";

  services.nginx.virtualHosts."punkte.kloenk.de" = {
    enableACME = true;
    forceSSL = true;
  };
}
