defmodule Farmbot.Network.Manager do
  @moduledoc """
    A behaviour for managing networking.
  """

  @type ret_val :: :ok | {:error, atom}
  @callback start_link(pid) :: {:ok, pid}
end



# I've identified 3 distinct modes of network operation.
# I've dubbed them 'virtual', 'lan', and 'wan'.
# wan being full on cloud-enabled, by virtue of wifi-client ethernet-client or 4g-lte-client.
# lan being local network only by virtue of wifi-client, wifi-host, ethernet-client, ethernet-host, or any to be determined client or host.
# Requisite • 1 min
# oh man that sentence just like clicked so much in my head
# 1 min
# Requisite Zero (requisite.zero@gmail.com)
# and virtual being host-only.
# Requisite • 1 min
# SHIT SON
# i know how to fix this now
# Now
# Requisite Zero (requisite.zero@gmail.com)
# You're welcome.
# Requisite • Now
# i was trying to see it all to specific
# Now
