# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ lib, pkgs, ... }:
{
  imports = lib.flatten [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    ./modules/system.nix
    ./modules/nuget-server.nix

    (map lib.custom.relativeToRoot [
      #
      # ========== Required Configs ==========
      #
      "hosts/core"

      #
      # ========== Non-Primary Users to Create ==========
      #

      #
      # ========== Optional Configs ==========
      #
    ])
  ];

  boot = {
    loader = {
      systemd-boot.enable = true;
      systemd-boot.configurationLimit = 5;
      efi.canTouchEfiVariables = true;
    };
  };

  nix = {
    settings.auto-optimise-store = true;
    settings.experimental-features = [
      "nix-command"
      "flakes"
    ];
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };
  };

  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone. time.timeZone = "Asia/Taipei";
  time.timeZone = "Asia/Taipei";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "zh_TW.UTF-8";
    LC_IDENTIFICATION = "zh_TW.UTF-8";
    LC_MEASUREMENT = "zh_TW.UTF-8";
    LC_MONETARY = "zh_TW.UTF-8";
    LC_NAME = "zh_TW.UTF-8";
    LC_NUMERIC = "zh_TW.UTF-8";
    LC_PAPER = "zh_TW.UTF-8";
    LC_TELEPHONE = "zh_TW.UTF-8";
    LC_TIME = "zh_TW.UTF-8";
  };

  nixpkgs.config.allowUnfree = true;

  networking.nameservers = [
    "163.22.21.44"
    "163.22.2.1"
    "163.22.2.2"
  ];

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.05"; # Did you read the comment?

  users.groups.gitlab-runner-frontend = { };
  users.groups.gitlab-runner-dotnet = { };

  users.users.gitlab-runner-frontend = {
    isSystemUser = true;
    uid = 2101;
    group = "gitlab-runner-frontend";

    home = "/var/lib/gitlab-runner-frontend";
    createHome = true;

    shell = pkgs.bashInteractive;

    linger = true;

    subUidRanges = [
      {
        startUid = 200000;
        count = 65536;
      }
    ];

    subGidRanges = [
      {
        startGid = 200000;
        count = 65536;
      }
    ];
  };

  users.users.gitlab-runner-dotnet = {
    isSystemUser = true;
    uid = 2102;
    group = "gitlab-runner-dotnet";

    home = "/var/lib/gitlab-runner-dotnet";
    createHome = true;

    shell = pkgs.bashInteractive;

    linger = true;

    subUidRanges = [
      {
        startUid = 300000;
        count = 65536;
      }
    ];

    subGidRanges = [
      {
        startGid = 300000;
        count = 65536;
      }
    ];
  };

  users.groups.nuget-server = { };

  users.users.nuget-server = {
    isSystemUser = true;
    group = "nuget-server";

    home = "/var/lib/nuget-server";
    createHome = true;
  };
}
