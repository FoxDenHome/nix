{ foxDenLib, pkgs, lib, config, ... }:
let
  services = foxDenLib.services;

  svcConfig = config.foxDen.services.immich;

  hostCfg = foxDenLib.hosts.getByName config svcConfig.host;
  primaryInterface = lib.lists.head (lib.attrsets.attrValues hostCfg.interfaces);
  hostName = foxDenLib.global.dns.mkHost primaryInterface.dns;
  proto = if svcConfig.tls then "https" else "http";
in
{
  options.foxDen.services.immich = {
    mediaDir = lib.mkOption {
      type = lib.types.path;
      description = "Directory to store Immich media";
    };
  } // services.http.mkOptions { svcName = "immich"; name = "Immich image server"; };

  config = lib.mkIf svcConfig.enable (lib.mkMerge [
    (services.make {
      name = "immich";
      gpu = true;
      inherit svcConfig pkgs config;
    }).config
    (services.http.make {
      inherit svcConfig pkgs config;
      name = "caddy-immich";
      target = "reverse_proxy http://127.0.0.1:${builtins.toString config.services.immich.port}";
    }).config
    {
      foxDen.services.immich.oAuth.overrideService = true;
    
      foxDen.services.kanidm.oauth2 = lib.mkIf svcConfig.oAuth.enable {
        ${svcConfig.oAuth.clientId} =
          (services.http.mkOauthConfig {
            inherit svcConfig config;
            oAuthCallbackUrl = "/redirect";
          }) // {
          preferShortUsername = true;
          public = true;
          scopeMaps.login-users = ["preferred_username" "email" "openid" "profile"];
        };
      };

      foxDen.services.mysql.services = [
        {
          name = "immich";
          targetService = "immich-server";
        }
        {
          name = "immich";
          targetService = "immich-machine-learning";
        }
      ];

      systemd.services = let
        cfg = {
          serviceConfig = {
            BindPaths = [
              "${svcConfig.mediaDir}"
            ];
          };
        };
      in
      {
        immich-server = cfg;
        immich-machine-learning = cfg;
      };
  
      services.immich = {
        host = "127.0.0.1";
        enable = true;
        accelerationDevices = null;
        mediaLocation = svcConfig.mediaDir;
        database = {
          createDB = false;
        };
        settings = {
          ffmpeg = {
            crf = 23;
            threads = 0;
            preset = "ultrafast";
            targetVideoCodec = "h264";
            acceptedVideoCodecs = ["h264"];
            targetAudioCodec = "aac";
            acceptedAudioCodecs = ["aac" "mp3" "libopus" "pcm_s16le"];
            acceptedContainers = ["mov" "ogg" "webm"];
            targetResolution = "720";
            maxBitrate = "0";
            bframes = -1;
            refs = 0;
            gopSize = 0;
            temporalAQ = false;
            cqMode = "auto";
            twoPass = false;
            preferredHwDevice = "auto";
            transcode = "required";
            tonemap = "hable";
            accel = "disabled";
            accelDecode = false;
          };
          backup = {
            database = {
              enabled = true;
              cronExpression = "0 02 * * *";
              keepLastAmount = 14;
            };
          };
          job = {
            backgroundTask = {
              concurrency = 5;
            };
            smartSearch = {
              concurrency = 2;
            };
            metadataExtraction = {
              concurrency = 5;
            };
            faceDetection = {
              concurrency = 2;
            };
            search = {
              concurrency = 5;
            };
            sidecar = {
              concurrency = 5;
            };
            library = {
              concurrency = 5;
            };
            migration = {
              concurrency = 5;
            };
            thumbnailGeneration = {
              concurrency = 3;
            };
            videoConversion = {
              concurrency = 1;
            };
            notifications = {
              concurrency = 5;
            };
          };
          logging = {
            enabled = true;
            level = "log";
          };
          machineLearning = {
            enabled = false;
            urls = [ "http://127.0.0.1:3003" ];
            clip = {
              enabled = true;
              modelName = "ViT-B-32__openai";
            };
            duplicateDetection = {
              enabled = true;
              maxDistance = 0.01;
            };
            facialRecognition = {
              enabled = true;
              modelName = "buffalo_l";
              minScore = 0.7;
              maxDistance = 0.5;
              minFaces = 3;
            };
          };
          map = {
            enabled = true;
            lightStyle = "https://tiles.immich.cloud/v1/style/light.json";
            darkStyle = "https://tiles.immich.cloud/v1/style/dark.json";
          };
          reverseGeocoding = {
            enabled = true;
          };
          metadata = {
            faces = {
              import = false;
            };
          };
          oauth = {
            autoLaunch = false;
            autoRegister = true;
            buttonText = "Login with FoxDen";
            clientId = svcConfig.oAuth.clientId;
            clientSecret = "";
            defaultStorageQuota = 1 * 1024 * 1024 * 1024; # 1 GB
            enabled = true;
            issuerUrl = "";
            mobileOverrideEnabled = false;
            mobileRedirectUri = "";
            scope = "openid email profile";
            signingAlgorithm = "RS256";
            profileSigningAlgorithm = "none";
            storageLabelClaim = "preferred_username";
            storageQuotaClaim = "immich_quota";
          };
          passwordLogin = {
            enabled = true;
          };
          storageTemplate = {
            enabled = false;
            hashVerificationEnabled = true;
            template = "{{y}}/{{y}}-{{MM}}-{{dd}}/{{filename}}";
          };
          image = {
            thumbnail = {
              format = "webp";
              size = 250;
              quality = 80;
            };
            preview = {
              format = "jpeg";
              size = 1440;
              quality = 80;
            };
            colorspace = "p3";
            extractEmbedded = false;
          };
          newVersionCheck = {
            enabled = true;
          };
          trash = {
            enabled = true;
            days = 30;
          };
          theme = {
            customCss = "";
          };
          library = {
            scan = {
              enabled = true;
              cronExpression = "0 0 * * *";
            };
            watch = {
              enabled = false;
            };
          };
          server = {
            externalDomain = "${proto}://${hostName}";
            loginPageMessage = "";
          };
          notifications = {
            smtp = {
              enabled = false;
              from = "";
              replyTo = "";
              transport = {
                ignoreCert = false;
                host = "";
                port = 587;
                username = "";
                password = "";
              };
            };
          };
          user = {
            deleteDelay = 7;
          };
        };
      };
    }
  ]);
}
