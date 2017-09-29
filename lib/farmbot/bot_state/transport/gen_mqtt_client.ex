defmodule Farmbot.Transport.GenMQTTClient do
  use GenMQTT
  require Logger
  @token "eyJhbGciOiJSUzI1NiJ9.eyJzdWIiOiJhZG1pbkBhZG1pbi5jb20iLCJpYXQiOjE1MDY3MDQ5MzUsImp0aSI6IjViYzlmYTcyLTc2NDYtNDJhMi04ZjM5LTRlMjJhNGExOTBhMCIsImlzcyI6Ii8vMTkyLjE2OC44Ni4xMTA6MzAwMCIsImV4cCI6MTUxMDE2MDkzNSwibXF0dCI6IjE5Mi4xNjguODYuMTEwIiwib3NfdXBkYXRlX3NlcnZlciI6Imh0dHBzOi8vYXBpLmdpdGh1Yi5jb20vcmVwb3MvZmFybWJvdC9mYXJtYm90X29zL3JlbGVhc2VzL2xhdGVzdCIsImZ3X3VwZGF0ZV9zZXJ2ZXIiOiJodHRwczovL2FwaS5naXRodWIuY29tL3JlcG9zL0Zhcm1ib3QvZmFybWJvdC1hcmR1aW5vLWZpcm13YXJlL3JlbGVhc2VzL2xhdGVzdCIsImJvdCI6ImRldmljZV8yIn0.nYQ9QohmEiLM5OeNuTk8a_9XVUALTjM05K6ki2hsGJw6S0Rc2i0ZpYHobK8du3pZFG-0-CC0YSHx8H9B4QPhs0HpF6gQIGg-3SPCtHoZz3abaQ_mocyVAyGv8CSsDQXVOkZIIeOzxN9yhhtRMTbJinjfPvmZccQ3qcR-_rOmoJETHB22IPUzE1oW0KdhQFwzK9m87TJk56vyyQeBAIyvHMHzgSwPQlzj9uOV3Id8nwjTBJ9fZ8q0737A3wK2Girv506l_7kk-5z_6LqI0yPV-6IBtCeyVtyWiOo7Feq1CFlQWIdQH7VdsvxphwarDqFHjj7Nofz8NeFjlIb9YGCH9w"

  @device "device_2"

  def start_link do
    GenMQTT.start_link(__MODULE__, [], [
      reconnect_timeout: 10_000,
      username:          @device,
      password:          @token,
      timeout:           10_000,
      host:              "localhost"
    ])
  end

  def init(_) do
    {:ok, %{connected: false}}
  end

  def on_connect_error(:invalid_credentials, state) do
    msg = """
    Failed to authenticate with the message broker!
    This is likely a problem with your server/broker configuration.
    """
    Logger.error ">> #{msg}"
    Farmbot.System.factory_reset(msg)
    {:ok, state}
  end

  def on_connect_error(reason, state) do
    Logger.error ">> Failed to connect to mqtt: #{inspect reason}"
    {:ok, state}
  end

  def on_connect(state) do
    GenMQTT.subscribe(self(), [{bot_topic(@device), 0}])
    Logger.info ">> Connected!"
    {:ok, %{state | connected: true}}
  end

  def on_publish(["bot", _bot, "from_clients"], msg, state) do
    Logger.warn "not implemented yet: #{inspect msg}"
    {:ok, state}
  end

  def handle_info({:bot_state, bs}, state) do
    Logger.info "Got bot state update"
    json = Poison.encode!(bs)
    GenMQTT.publish(self(), status_topic(@device), json, 0, false)
    {:noreply, state}
  end

  defp frontend_topic(bot), do: "bot/#{bot}/from_device"
  defp bot_topic(bot),      do: "bot/#{bot}/from_clients"
  defp status_topic(bot),   do: "bot/#{bot}/status"
  defp log_topic(bot),      do: "bot/#{bot}/logs"
end
