{
  services.resolved.enable = true;
  services.netbird = {
    useRoutingFeatures = "server";
    clients.default = {
      name = "netbird";
      port = 51820;
      interface = "wt0";
      hardened = false;
      openFirewall = true;
      openInternalFirewall = true;
    };
  };
}
