defmodule FarmbotExt.API.Preloader do
  @moduledoc """
  Task to ensure Farmbot has synced:
    * FarmbotCore.Asset.Device
    * FarmbotCore.Asset.FbosConfig
    * FarmbotCore.Asset.FirmwareConfig
  """

  FarmbotExt.fetch_impl!(__MODULE__, :preloader_impl)

  @callback preload_all :: :ok | :error

  def preload_all do
    FarmbotExt.fetch_impl!(__MODULE__, :preloader_impl).preload_all()
  end
end
