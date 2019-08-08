defmodule FarmbotOS.Platform.Target.Configurator.VintageNetworkLayer do
  @behaviour FarmbotOS.Configurator.NetworkLayer

  @impl FarmbotOS.Configurator.NetworkLayer
  def list_interfaces() do
    VintageNet.all_interfaces()
    |> Kernel.--(["usb0", "lo"])
    |> Enum.map(fn ifname ->
      [{["interface", ^ifname, "mac_address"], mac_address}] =
        VintageNet.get_by_prefix(["interface", ifname, "mac_address"])

      {ifname, %{mac_address: mac_address}}
    end)
  end

  @impl FarmbotOS.Configurator.NetworkLayer
  def scan(ifname) do
    _ = VintageNet.scan(ifname)
    [{_, aps}] = VintageNet.get_by_prefix(["interface", ifname, "wifi", "access_points"])

    Enum.map(aps, fn %{bssid: bssid, ssid: ssid, signal_percent: signal, flags: flags} ->
      %{
        ssid: ssid,
        bssid: bssid,
        level: signal,
        security: flags_to_security(flags)
      }
    end)
    |> Enum.uniq_by(fn %{ssid: ssid} -> ssid end)
    |> Enum.sort(fn
      %{level: level1}, %{level: level2} -> level1 >= level2
    end)
    |> Enum.filter(fn %{ssid: ssid} ->
      String.length(to_string(ssid)) > 0
    end)
  end

  defp flags_to_security([:wpa2_psk_ccmp | _]), do: "WPA-PSK"
  defp flags_to_security([:wpa2_psk_ccmp_tkip | _]), do: "WPA-PSK"
  defp flags_to_security([:wpa_psk_ccmp | _]), do: "WPA-PSK"
  defp flags_to_security([:wpa_psk_ccmp_tkip | _]), do: "WPA-PSK"
  defp flags_to_security([:wpa2_eap_ccmp | _]), do: "WPA-EAP"
  defp flags_to_security([_ | rest]), do: flags_to_security(rest)
  defp flags_to_security([]), do: "NONE"
end
