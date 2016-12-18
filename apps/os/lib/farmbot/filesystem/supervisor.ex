defmodule Farmbot.FileSystem.Supervisor do
  @moduledoc """
      Supervises the filesystem storage
  """
  use Supervisor
  require Logger
  alias Farmbot.FileSystem.ConfigStorage
  alias Farmbot.FileSystem.StateStorage

  def start_link({env, target}), do: Supervisor.start_link(__MODULE__, {env, target})
  def init({env, target}) do
    children = [
      worker(Farmbot.FileSystem, [{env, target}], restart: :permanent),
      worker(ConfigStorage, [], restart: :permanent)
    ]
    opts = [strategy: :one_for_one, name: __MODULE__]
    supervise(children, opts)
  end
end
