defmodule FarmbotExt.Bootstrap.DropPasswordTask do
  @moduledoc """
  Task to make sure the plaintext password is dropped form 
  the sqlite database.
  """
  import FarmbotCore.Config, only: [update_config_value: 4, get_config_value: 3]
  require FarmbotCore.Logger
  alias FarmbotExt.Bootstrap.Authorization

  use GenServer

  @doc false
  def start_link(args, opts \\ [name: __MODULE__]) do
    GenServer.start_link(__MODULE__, args, opts)
  end

  @impl GenServer
  def init(_args) do
    send(self(), :checkup)
    {:ok, %{backoff: 5000, timer: nil}}
  end

  @impl GenServer
  def handle_info(:checkup, state) do
    email = get_config_value(:string, "authorization", "email")
    password = get_config_value(:string, "authorization", "password")
    server = get_config_value(:string, "authorization", "server")
    # secret = get_config_value(:string, "authorization", "secret")
    if password do
      case Authorization.authorize_with_password_v2(email, password, server) do
        {:ok, {_, secret}} ->
          # Drop the password from the database
          update_config_value(:string, "authorization", "secret", secret)
          update_config_value(:string, "authorization", "password", nil)
          FarmbotCore.Logger.debug(3, "Successfully encoded secret")
          {:noreply, state, :hibernate}

        {:error, _} ->
          timer = Process.send_after(self(), :checkup, state.backoff)
          {:noreply, %{state | backoff: state.backoff + 1000, timer: timer}}
      end
    else
      {:noreply, state, :hibernate}
    end
  end
end
