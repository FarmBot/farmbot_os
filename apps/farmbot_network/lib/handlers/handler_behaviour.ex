defmodule Farmbot.Network.Handler do
  @moduledoc """
    A behaviour for managing networking.
  """

  @type ret_val :: :ok | {:error, atom}
  @callback manager :: {:ok, pid}
end
