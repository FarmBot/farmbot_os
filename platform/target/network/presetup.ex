defmodule FarmbotOS.Platform.Target.Network.PreSetup do
  @moduledoc """
  VintageNet technology responsible for doing nothing,
  but isn't the NULL technology
  """

  @behaviour VintageNet.Technology

  alias VintageNet.Interface.RawConfig

  @impl true
  def normalize(config), do: config

  @impl true
  def to_raw_config(ifname, config \\ %{}, _opts \\ []) do
    %RawConfig{
      ifname: ifname,
      type: __MODULE__,
      source_config: config,
      required_ifnames: []
    }
  end

  @impl true
  def ioctl(_ifname, _command, _args) do
    {:error, :unsupported}
  end

  @impl true
  def check_system(_opts), do: :ok
end
