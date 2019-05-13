defmodule FarmbotExt.API.Preloader do
  @moduledoc """
  Task to ensure Farmbot has synced:
    * FarmbotCore.Asset.Device
    * FarmbotCore.Asset.FbosConfig
    * FarmbotCore.Asset.FirmwareConfig
  """

  @callback preload_all :: :ok | :error

  def preloader_impl() do
    FarmbotExt.fetch_impl!(
      __MODULE__,
      :preloader_impl,
      FarmbotExt.API.Preloader.HTTP
    )
  end

  def preload_all do
    preloader_impl().preload_all()
  end
end
