defmodule Farmbot.Bootstrap.Supervisor do
  @moduledoc "Supervises Bootstrap services."

  use Supervisor

  error_msg = """
  Please configure an authorization module!
  """
  @auth_task Application.get_env(:farmbot, :behaviour, :authorization) || Mix.raise(error_msg)

  @doc "Start Bootstrap services."
  def start_link(args, opts \\ []) do
    Supervisor.start_link(__MODULE__, args, opts)
  end

  def init(args) do
    email  = Application.get_env(:farmbot, :authorization, :email)
    pass   = Application.get_env(:farmbot, :authorization, :password)
    server = Application.get_env(:farmbot, :authorization, :server)
    with  ensured_email  when is_binary(ensured_email)  <- email,
          ensured_pass   when is_binary(ensured_pass)   <- pass,
          ensured_server when is_binary(ensured_server) <- server,
          do: actual_init(args, email, pass, server)
  end

  defp actual_init(args, email, pass, server) do
    # get a token
    case @auth_task.authorize(email, password, server) do
      {:ok, token} ->
        children = [
          supervisor(Farmbot.HTTP.Supervisor,      [token, [name: Farmbot.HTTP.Supervisor]]),
          supervisor(Farmbot.Transport.Supervisor, [token, [name: Farmbot.Transport.Supervisor]])
        ]
        opts = [strategy: :one_for_all]
        supervise(children, opts)
      {:error, reason} -> {:shutdown, reason}
    end
  end
end
