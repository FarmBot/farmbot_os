defmodule FarmbotOS.Configurator.ConfigDataLayer do
  @behaviour FarmbotOS.Configurator.DataLayer
  require FarmbotCore.Logger
  alias FarmbotCore.Config
  alias FarmbotOS.FileSystem

  @impl FarmbotOS.Configurator.DataLayer
  def load_last_reset_reason() do
    file_path = Path.join(FileSystem.data_path(), "last_reset_reason")

    case File.read(file_path) do
      {:ok, data} -> data
      _ -> nil
    end
  end

  @impl FarmbotOS.Configurator.DataLayer
  def load_email() do
    Config.get_config_value(:string, "authorization", "email")
  end

  @impl FarmbotOS.Configurator.DataLayer
  def load_password() do
    Config.get_config_value(:string, "authorization", "password")
  end

  @impl FarmbotOS.Configurator.DataLayer
  def load_server() do
    Config.get_config_value(:string, "authorization", "server")
  end

  @impl FarmbotOS.Configurator.DataLayer
  def dump_logs() do
    FarmbotCore.Logger.error(1, "FIXME log db not working")
    []
  end

  @impl FarmbotOS.Configurator.DataLayer
  def dump_log_db() do
    FarmbotCore.Logger.error(1, "FIXME log db not working")
    {:error, :enent}
  end
end
