defmodule Farmbot.System.GPIO.Handler do
  @moduledoc "Behaviour for GPIO handlers to implement."

  @doc "Start the handler."
  @callback start_link :: GenServer.on_start

  @doc "Register a pin."
  @callback register_pin(integer) :: :ok | {:error, term}
end
