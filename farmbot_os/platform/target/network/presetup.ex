defmodule FarmbotOS.Platform.Target.Network.PreSetup do
  @behaviour VintageNet.Technology

  alias VintageNet.Interface.RawConfig

  @impl true
  def normalize(config), do: {:ok, config}

  @impl true
  def to_raw_config(ifname, config \\ %{}, _opts \\ []) do
    {:ok,
     %RawConfig{
       ifname: ifname,
       type: __MODULE__,
       source_config: config,
       require_interface: false
     }}
  end

  @impl true
  def ioctl(_ifname, _command, _args) do
    {:error, :unsupported}
  end

  @impl true
  def check_system(_opts), do: :ok
end
