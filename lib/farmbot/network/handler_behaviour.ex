defmodule Farmbot.Network.Handler do
  @moduledoc """
    A behaviour for managing networking.
  """

  @type ret_val :: :ok | {:error, atom}
  @callback init({pid, map}) :: {:ok, any}
  @callback manager :: {:ok, pid}
end
