let
  filebeatModule = { lib, config, pkgs, ...}:
    let cfg = config.services.filebeat;
        realConfig = ''
            ${lib.optionalString (cfg.logstashHost != null) ''
            output:
              logstash:
                enabled: true
                hosts:
                  - ${cfg.logstashHost}
                timeout: 15
                tls:
                  certificate_authorities:
                  - ${./logstash-beats.crt}
            ''}
            ${cfg.extraConfig}
        '';
        filebeat = pkgs.callPackage ./filebeat.nix {};
  in with lib; {
      options.services.filebeat = {
         enable = mkOption {};
         logstashHost = mkOption {};
         extraConfig = mkOption {};
      };
      config = mkIf cfg.enable {
          environment.etc."filebeat.yml".text = realConfig;
        systemd.services.filebeat = {
            wantedBy = [ "multi-user.target" ];
            after = [ "network.target" ];
            serviceConfig.ExecStart =
              "${filebeat}/bin/filebeat -c ${pkgs.writeText "filebeat.yml" realConfig}";
        };
    };
  };

in {
    vm =
      let elk_ip = "192.168.0.2";
          nginx_ip = "192.168.0.3";
    in { pkgs, ...}: {
        deployment.targetEnv = "libvirtd";
        deployment.libvirtd.headless = true;

        networking.bridges.br0.interfaces = [];
        networking.interfaces.br0.ip4 = [{ address = "192.168.0.1"; prefixLength = 24; }];

        nixpkgs.config.packageOverrides = super: {
            filebeat = pkgs.callPackage ./filebeat.nix {};
            logstash-input-journald = pkgs.callPackage ./logstash-plugin.nix {};
        };

        containers.nginx = {
            autoStart = true;
            privateNetwork = true;
            hostBridge = "br0";
            localAddress = "${nginx_ip}/24";
            config = { config, ... }: {

                imports = [ filebeatModule ];

                services.nginx.enable = true;

                services.filebeat.enable = true;
                services.filebeat.logstashHost = "${elk_ip}:5044";
                services.filebeat.extraConfig = ''
                    filebeat:
                      prospectors:
                        -
                          paths:
                            - "${config.services.nginx.stateDir}/*.log"
                          document_type: nginx-access
                  '';

                services.logstash.enable = true;
                services.logstash.plugins = with pkgs; [ logstash-input-journald ];
                services.logstash.inputConfig = ''
                     journald {
                       wait_timeout => 1000000
                       lowercase => true
                       seekto => "head"
                       thisboot => true
                       type => "systemd"
                     }
                '';
                services.logstash.filterConfig = ''mutate{}'';
                services.logstash.outputConfig = ''
                    file {
                        path => "/tmp/journal.log"
                        codec => line
                    }
                '';
              };
        };

         containers.elk = {
          autoStart = true;
          privateNetwork = true;
          hostBridge = "br0";
          localAddress = "192.168.0.2/24";

           config = { pkgs, ...}: {
             networking.firewall.allowedTCPPorts = [
               5601
               9200
               5044
               5000
             ];
            services.logstash = {
                enable = true;
                plugins = [ pkgs.logstash-contrib ];
                inputConfig = ''
                  stdin {}
                '';

                filterConfig = ''
                   mutate {}
                '';

                outputConfig = ''
                   stdout {}
                '';
            };
            services.elasticsearch = {
                enable = false;
            };
            services.kibana = {
                enable = true;
                listenAddress = "192.168.0.2";
            };
           };
         };
    };
}