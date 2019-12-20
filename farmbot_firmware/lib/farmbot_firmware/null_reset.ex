defmodule FarmbotFirmware.NullReset do
  @moduledoc """
  Does nothing in reference to resetting the firmware port
  """
  @behaviour FarmbotFirmware.Reset
  use GenServer

  @impl FarmbotFirmware.Reset
  def reset(), do: :ok

  @impl GenServer
  def init(_args) do
    {:ok, %{}}
  end
end
