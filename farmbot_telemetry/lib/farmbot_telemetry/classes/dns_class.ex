defmodule FarmbotTelemetry.DNSClass do
  @moduledoc """
  Classification of events pertaining to dns resolution accross the various
  networked systems in the application including:

  * ntp
  * Farmbot http token fetching
  * Farmbot http rest interface
  * Farmbot AMQP interface
  """

  @behaviour FarmbotTelemetry.Class

  @impl FarmbotTelemetry.Class
  def matrix(),
    do: [
      ntp: [:nxdomain],
      http: [:nxdomain],
      token: [:nxdomain],
      amqp: [:nxdomain]
    ]
end
