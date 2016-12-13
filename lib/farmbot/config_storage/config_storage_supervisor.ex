defmodule Farmbot.ConfigStorage.Supervisor do
  @moduledoc """
      Supervises config storage
  """
  @state_path Application.get_env(:farmbot, :state_path)

  use Supervisor
  require Logger
  def start_link(args), do: Supervisor.start_link(__MODULE__, args)
  def init(_args) do
    path = setup_path
    children = []
    opts = [strategy: :one_for_one, name: __MODULE__]
    supervise(children, opts)
  end

  # Returns the path to the default configuration file.
  @spec default_file :: String.t
  defp default_file,
    do: "#{:code.priv_dir(:farmbot)}/static/default_config.json"

  defp setup_path do
    case File.read(@state_path) do
      {:ok, _} -> @state_path
      _ -> do_setup
    end
  end

  def do_setup do
    
  end
end
