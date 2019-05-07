defmodule FarmbotExt.API.Preloader do
  @moduledoc """
  Task to ensure Farmbot has synced:
    * FarmbotCore.Asset.Device
    * FarmbotCore.Asset.FbosConfig
    * FarmbotCore.Asset.FirmwareConfig
  """
  @callback preload_all :: :ok | :error

  def preload_all do
    Application.get_env(:farmbot_ext, __MODULE__)[:preloader_impl].preload_all()
  end
end
