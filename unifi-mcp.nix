{ config, lib, pkgs, ... }:

let
  copilotMcpSettings = builtins.toJSON {
    mcpServers = {
      unifi-network = {
        command = "uvx";
        args = [ "unifi-network-mcp@latest" ];
        env = {
          UNIFI_HOST = "192.168.11.4";
          UNIFI_PORT = "8443";
          UNIFI_USERNAME = "jonathany";
          UNIFI_VERIFY_SSL = "false";
        };
      };
    };
  };
in
{
  environment.systemPackages = [
    pkgs.uv
  ];

  # Deploy MCP server config for Copilot CLI
  # Note: UNIFI_PASSWORD must be set in the environment before launching copilot.
  # The settings.json may also contain other keys (e.g. logLevel) managed by the CLI itself.
  environment.etc."copilot-mcp-servers.json".text = copilotMcpSettings;
}
