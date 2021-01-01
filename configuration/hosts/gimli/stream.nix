{ config, pkgs, lib, ... }:

let

nginxCfg = pkgs.writeText "nginx.conf" ''
  daemon off;
  pid /var/lib/rtmp/nginx.pid;
  events {
    use epoll;
    worker_connections  128;
  }
  error_log stderr info;
  http {
    client_body_temp_path /var/lib/rtmp/nginx_cache_client_body;
    proxy_temp_path /var/lib/rtmp/nginx_cache_proxy;
    fastcgi_temp_path /var/lib/rtmp/nginx_cache_fastcgi;
    uwsgi_temp_path /var/lib/rtmp/nginx_cache_uwsgi;
    scgi_temp_path /var/lib/rtmp/nginx_cache_scgi;

    server {
      listen 8080;
      root /var/lib/rtmp;
      access_log stderr;
      error_log stderr;

      # This URL provides RTMP statistics in XML
      location /stat {
        rtmp_stat all;
      }

      location /hls {
        # Serve HLS fragments
        types {
          application/vnd.apple.mpegurl m3u8;
          video/mp2t ts;
        }
        root /var/lib/rtmp/tmp;
        add_header Cache-Control no-cache;

        # CORS setup
        add_header 'Access-Control-Allow-Origin' '*' always;
        add_header 'Access-Control-Expose-Headers' 'Content-Length';

        # Allow CORS preflight requests
        if ($request_method = 'OPTIONS') {
          add_header 'Access-Control-Allow-Origin' '*';
          add_header 'Access-Control-Max-Age' 1728000;
          add_header 'Content-Type' 'text/plain charset=UTF-8';
          add_header 'Content-Length' 0;
          add_header X-Content-Type-Options "nosniff";
          add_header X-Frame-Options "SAMEORIGIN";
          add_header X-Xss-Protection "1; mode=block";
          return 204;
        }
      }

      location /dash {
        # Serve DASH fragments
        types {
          application/dash+xml mpd;
          video/mp4 mp4;
        }
        root /tmp;
        add_header Cache-Control no-cache;

        # CORS setup
        add_header 'Access-Control-Allow-Origin' '*' always;
        add_header 'Access-Control-Expose-Headers' 'Content-Length';

        # Allow CORS preflight requests
        if ($request_method = 'OPTIONS') {
          add_header 'Access-Control-Allow-Origin' '*';
          add_header 'Access-Control-Max-Age' 1728000;
          add_header 'Content-Type' 'text/plain charset=UTF-8';
          add_header 'Content-Length' 0;
          add_header X-Content-Type-Options "nosniff";
          add_header X-Frame-Options "SAMEORIGIN";
          add_header X-Xss-Protection "1; mode=block";
          return 204;
        }
      }

      location "/dash.all.min.js" {
        default_type "text/javascript";
        alias ${pkgs.fetchurl {
          url = "http://cdn.dashjs.org/v3.2.0/dash.all.min.js";
          sha256 = "16f0b40gdqsnwqi01s5sz9f1q86dwzscgc3m701jd1sczygi481c";
        }};
      }

      location /player {
        default_type "text/html";
        alias ${pkgs.writeText "player.html" ''
          <!DOCTYPE html>
          <html lang="en">
            <head>
              <meta charset="utf-8">
              <title>kloenk livestream</title>
            </head>
            <body>
              <div>
                <video id="player" controls></video>
                </video>
              </div>
              <script src="/dash.all.min.js"></script>
              <script>
                (function(){
                  var url = "http://gimli.kloenk.dev:8080/dash/nixos.mpd";
                  var player = dashjs.MediaPlayer().create();
                  player.initialize(document.querySelector("#player"), url, true);
                })();
              </script>
            </body>
          </html>
        ''};
      }

      location /records {
        autoindex on;
        root /var/lib/rtmp;
      }
    }
  }

  rtmp {
    server {
      access_log stderr;
      listen 1935;
      ping 30s;
      notify_method get;

      application stream {
        live on;

        hls on;
        hls_path /var/lib/rtmp/tmp/hls;
        hls_fragment 1;
        hls_playlist_length 10;

        dash on;
        dash_path /var/lib/rtmp/tmp/dash;
      }
    }
  }
'';

in {

  services.nginx = {
    enable = true;
    virtualHosts."gimli.kloenk.dev" = {
      enableACME = true;
      addSSL = true;
      locations."/hls".extraConfig = ''
        # Serve HLS fragments
        types {
          application/vnd.apple.mpegurl m3u8;
          video/mp2t ts;
        }
        root /var/lib/rtmp/tmp;

        # Allow CORS preflight requests
        if ($request_method = 'OPTIONS') {
          add_header 'Access-Control-Allow-Origin' '*';
          add_header 'Access-Control-Max-Age' 1728000;
          add_header 'Content-Type' 'text/plain charset=UTF-8';
          add_header 'Content-Length' 0;
          add_header X-Content-Type-Options "nosniff";
          add_header X-Frame-Options "SAMEORIGIN";
          add_header X-Xss-Protection "1; mode=block";
          return 204;
        }

        if ($request_method != 'OPTIONS') {
          add_header Cache-Control no-cache;

          # CORS setup
          add_header 'Access-Control-Allow-Origin' '*' always;
          add_header 'Access-Control-Expose-Headers' 'Content-Length';
          add_header X-Content-Type-Options "nosniff";
          add_header X-Frame-Options "SAMEORIGIN";
          add_header X-Xss-Protection "1; mode=block";
        }
      '';
      locations."/dash".extraConfig = ''
        # Serve DASH fragments
        types {
          application/dash+xml mpd;
          video/mp4 mp4;
        }
        root /var/lib/rtmp/tmp;

        # Allow CORS preflight requests
        if ($request_method = 'OPTIONS') {
          add_header 'Access-Control-Allow-Origin' '*';
          add_header 'Access-Control-Max-Age' 1728000;
          add_header 'Content-Type' 'text/plain charset=UTF-8';
          add_header 'Content-Length' 0;
          add_header X-Content-Type-Options "nosniff";
          add_header X-Frame-Options "SAMEORIGIN";
          add_header X-Xss-Protection "1; mode=block";
          return 204;
        }
        if ($request_method != 'OPTIONS') {
          add_header Cache-Control no-cache;

          # CORS setup
          add_header 'Access-Control-Allow-Origin' '*' always;
          add_header 'Access-Control-Expose-Headers' 'Content-Length';
          add_header X-Content-Type-Options "nosniff";
          add_header X-Frame-Options "SAMEORIGIN";
          add_header X-Xss-Protection "1; mode=block";
        }
      '';
      locations."= /dash.all.min.js".extraConfig = ''
        default_type "text/javascript";
        alias ${pkgs.fetchurl {
          url = "http://cdn.dashjs.org/v3.2.0/dash.all.min.js";
          sha256 = "16f0b40gdqsnwqi01s5sz9f1q86dwzscgc3m701jd1sczygi481c";
        }};
      '';
      locations."= /player".extraConfig = ''
        default_type "text/html";
        alias ${pkgs.writeText "player.html" ''
          <!DOCTYPE html>
          <html lang="en">
            <head>
              <meta charset="utf-8">
              <title>kloenk livestream</title>
            </head>
            <body>
              <div>
                <video id="player" controls></video>
                </video>
              </div>
              <script src="/dash.all.min.js"></script>
              <script>
                (function(){
                  var url = "/dash/nixos.mpd";
                  var player = dashjs.MediaPlayer().create();
                  player.initialize(document.querySelector("#player"), url, true);
                })();
              </script>
            </body>
          </html>
        ''};
      '';
      locations."/records".extraConfig = ''
        autoindex on;
        root /var/lib/rtmp;
      '';
    };
  };

  fileSystems."/var/lib/rtmp/tmp" = {
    device = "tmpfs";
    fsType = "tmpfs";
    options = [ "nosuid" "nodev" "noatime" ];
  };

  users.users.rtmp = {
    home = "/var/lib/rtmp";
    #uid = genid_uint31 "rtmp";
    isNormalUser = true;
    createHome = true;
    openssh = config.users.users.kloenk.openssh;
  };

  systemd.services.nginx-rtmp = {
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];
    restartIfChanged = true;
    script = ''
      ${pkgs.nginx.override {
        modules = [
          pkgs.nginxModules.rtmp
        ];
      }}/bin/nginx -c ${nginxCfg} -p /var/lib/rtmp
    '';
    serviceConfig = {
      ExecStartPre = pkgs.writers.writeDash "setup-rtmp" ''
        mkdir -p /var/lib/rtmp/tmp/hls
        mkdir -p /var/lib/rtmp/tmp/dash
        chown rtmp:users /var/lib/rtmp/tmp/hls
        chown rtmp:users /var/lib/rtmp/tmp/dash
        chmod 755 /var/lib/rtmp/tmp/hls
        chmod 755 /var/lib/rtmp/tmp/dash
      '';
      User = "rtmp";
    };
  };

  /*krebs.iptables.tables.filter.INPUT.rules = [
    { predicate = "-p tcp --dport 1935"; target = "ACCEPT"; }
    { predicate = "-p tcp --dport 8080"; target = "ACCEPT"; }
  ];*/
  networking.firewall.allowedTCPPorts = [
    1935
    8080
  ];
}