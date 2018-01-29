use Farmbot.Logger
alias Farmbot.System.ConfigStorage
import ConfigStorage, only: [get_config_value: 3, update_config_value: 4]
Logger.debug 1, "Skipping configurator"

email = "replaceme@this_needs_to_be_fixed.com"
password = "password123"
server = "http://localhost:3000"
ssid = "SUPER_SECRET_SSID"
psk = "SUPER_SECRET_PSK"

Application.put_env(:farmbot, :authorization, [
  email: email,
  password: password,
  server: server
])

update_config_value(:bool, "settings", "first_boot", false)
update_config_value(:string, "authorization", "email", email)
update_config_value(:string, "authorization", "password", password)
update_config_value(:string, "authorization", "server", server)


%ConfigStorage.NetworkInterface{
  name: "wlan0",
  type: "wireless",
  ssid: ssid,
  psk: psk,
  security: "WPA-PSK",
  ipv4_method: "dhcp"
} |> ConfigStorage.insert!()
