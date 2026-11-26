{ pkgs, ... }:

let
  dotnet = pkgs.dotnetCorePackages.sdk_9_0-bin;

  appsettings = pkgs.writeText "nuget-server-appsettings.json" (
    builtins.toJSON {
      ApiKey = "";

      PackageDeletionBehavior = "Unlist";
      AllowPackageOverwrites = false;
      MaxPackageSizeGiB = 8;

      Database = {
        Type = "PostgreSql";
        ConnectionString = "";
      };

      Storage = {
        Type = "FileSystem";
        Path = "/var/lib/nuget-server/data";
      };

      Search = {
        Type = "Database";
      };

      Mirror = {
        Enabled = true;
        PackageSource = "https://api.nuget.org/v3/index.json";
      };

      Kestrel = {
        Endpoints = {
          Http = {
            # 刻意不是 localhost。
            # host.containers.internal 需要能連到 host 的 8080。
            Url = "http://0.0.0.0:8080";
          };
        };
      };

      Logging = {
        IncludeScopes = false;

        Console = {
          LogLevel = {
            "Microsoft.Hosting.Lifetime" = "Information";
            Default = "Warning";
          };
        };
      };

      HealthCheck = {
        Path = "/health";
      };

      Statistics = {
        EnableStatisticsPage = false;
        ListConfiguredServices = false;
      };
    }
  );

  startScript = pkgs.writeShellScript "nuget-server-start" ''
    set -euo pipefail

    export ApiKey="$(
      cat "$CREDENTIALS_DIRECTORY/ApiKey"
    )"

    export Database__ConnectionString="$(
      cat "$CREDENTIALS_DIRECTORY/DatabaseConnectionString"
    )"

    exec ${dotnet}/bin/dotnet \
      /opt/nuget-server/current/BaGetter.dll
  '';
in
{
  environment.systemPackages = with pkgs; [
    git
    gnumake
    dotnet
  ];

  users.groups.nuget-server = { };

  users.users.nuget-server = {
    isSystemUser = true;
    group = "nuget-server";

    home = "/var/lib/nuget-server";
    createHome = true;

    # 正式 service account 保持不可登入。
  };

  systemd.tmpfiles.rules = [
    "d /opt/nuget-server 0755 root root -"
    "d /opt/nuget-server/releases 0755 root root -"

    "d /var/lib/nuget-server 0750 nuget-server nuget-server -"
    "d /var/lib/nuget-server/data 0750 nuget-server nuget-server -"

    "d /var/lib/nuget-server-secrets 0700 root root -"
  ];

  environment.etc."nuget-server/appsettings.json".source = appsettings;

  systemd.services.nuget-server = {
    description = "Private NuGet and Symbol Server";

    wantedBy = [
      "multi-user.target"
    ];

    after = [
      "network-online.target"
      "postgresql.service"
    ];

    wants = [
      "network-online.target"
    ];

    requires = [
      "postgresql.service"
    ];

    unitConfig.ConditionPathExists = [
      "/opt/nuget-server/current/BaGetter.dll"
      "/var/lib/nuget-server-secrets/api-key"
      "/var/lib/nuget-server-secrets/db-connection-string"
    ];

    environment = {
      ASPNETCORE_ENVIRONMENT = "Production";

      DOTNET_CLI_TELEMETRY_OPTOUT = "1";
      DOTNET_NOLOGO = "1";
    };

    serviceConfig = {
      Type = "simple";

      User = "nuget-server";
      Group = "nuget-server";

      WorkingDirectory = "/opt/nuget-server/current";

      ExecStart = startScript;

      LoadCredential = [
        "ApiKey:/var/lib/nuget-server-secrets/api-key"
        "DatabaseConnectionString:/var/lib/nuget-server-secrets/db-connection-string"
      ];

      Restart = "on-failure";
      RestartSec = "5s";

      UMask = "0027";

      NoNewPrivileges = true;
      PrivateTmp = true;

      ProtectSystem = "strict";
      ProtectHome = true;

      ProtectKernelTunables = true;
      ProtectKernelModules = true;
      ProtectKernelLogs = true;
      ProtectControlGroups = true;

      RestrictSUIDSGID = true;
      LockPersonality = true;

      CapabilityBoundingSet = "";
      AmbientCapabilities = "";

      ReadWritePaths = [
        "/var/lib/nuget-server"
      ];
    };
  };
}
