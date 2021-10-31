defmodule FarmbotOS.Bootstrap.DropPasswordTask do
  @moduledoc """
  Task to make sure the plaintext password is dropped form
  the sqlite database.
  """
  require FarmbotOS.Logger

  alias FarmbotOS.Bootstrap.{
    Authorization,
    DropPasswordSupport
  }

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
    drop_password(DropPasswordSupport.get_credentials(), state)
  end

  def drop_password(%{password: nil}, state) do
    {:noreply, state, :hibernate}
  end

  def drop_password(%{email: email, password: password, server: server}, state) do
    case Authorization.authorize_with_password_v2(email, password, server) do
      {:ok, {_, secret}} ->
        DropPasswordSupport.set_secret(secret)
        {:noreply, state, :hibernate}

      {:error, _} ->
        timer = FarmbotOS.Time.send_after(self(), :checkup, state.backoff)
        {:noreply, %{state | backoff: state.backoff + 1000, timer: timer}}
    end
  end
end
