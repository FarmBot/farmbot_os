defmodule FarmbotTelemetry.NetworkClass do
  @moduledoc """
  Classification of events pertaining to a network interface, not network
  software errors. This includes:

  * WiFi errors
  * ip address configuration errors
  """

  @behaviour FarmbotTelemetry.Class

  @impl FarmbotTelemetry.Class
  def matrix(),
    do: [
      access_point: [:disconnect, :connect, :eap_error, :assosiate_error, :assosiate_timeout],
      ip_address: [:dhcp_lease, :dhcp_renew, :dhcp_lease_fail, :dhcp_renew_fail]
    ]
end
