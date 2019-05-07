defmodule FarmbotExt.API.Preloader do
  @moduledoc """
  Task to ensure Farmbot has synced:
    * FarmbotCore.Asset.Device
    * FarmbotCore.Asset.FbosConfig
    * FarmbotCore.Asset.FirmwareConfig
  """
  Application.get_env(:farmbot_ext, __MODULE__)[:preloader_impl] ||
    Mix.raise("""
    No default preloader implementation was provided. 

      config :farmbot_ext, FarmbotExt.API.Preloader, [
        preloader_impl: FarmbotExt.API.Preloader.HTTP
      ]
    """)

  @callback preload_all :: :ok | :error

  def preload_all do
    Application.get_env(:farmbot_ext, __MODULE__)[:preloader_impl].preload_all()
  end
end
