defmodule Farmbot.PinBinding.Handler do
  @moduledoc "Behaviour for PinBinding handlers to implement."

  @doc "Start the handler."
  @callback start_link :: GenServer.on_start()

  @doc "Register a pin."
  @callback register_pin(integer) :: :ok | {:error, term}

  @doc "Unregister a pin."
  @callback unregister_pin(integer) :: :ok | {:error, term}
end
