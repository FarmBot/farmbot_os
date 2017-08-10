defmodule Farmbot.Bootstrap.Supervisor do
  @moduledoc "Supervises Bootstrap services."

  @behaviour Supervisor

  error_msg """
  Please configure an authorization module!
  """
  @auth_manager Application.get_env(:farmbot, :behaviour, :authorization) || Mix.raise(error_msg)

  @doc "Start Bootstrap services."
  def start_link(args, opts \\ []) do
    Supervisor.start_link(__MODULE__, args, opts)
  end

  def init(args) do
    # get a token
    children = [
      Farmbot.Bootstrap.Authorization.child_spec(@auth_manager, [name: @auth_manager])
      supervisor(Farmbot.HTTP.Supervisor, [token, [name: Farmbot.HTTP.Supervisor]]),
      supervisor(Farmbot.Transport.Supervisor, [token, [name: Farmbot.Transport.Supervisor]])
    ]
    opts = [strategy: :one_for_all]
  end
end
