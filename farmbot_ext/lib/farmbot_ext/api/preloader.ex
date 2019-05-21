defmodule FarmbotExt.API.Preloader do
  @moduledoc """
  Task to ensure Farmbot has synced:
    * FarmbotCore.Asset.Device
    * FarmbotCore.Asset.FbosConfig
    * FarmbotCore.Asset.FirmwareConfig
  """

  @callback preload_all :: :ok | :error
  def preload_all do
    preloader_impl().preload_all()
  end

  defp preloader_impl() do
    mod = Application.get_env(:farmbot_ext, __MODULE__) || []
    Keyword.get(mod, :preloader_impl, FarmbotExt.API.Preloader.HTTP)
  end
end
