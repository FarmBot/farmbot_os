defmodule Farmbot.CeleryScript.Command.ReadAllParams do
  @moduledoc """
    ReadAllParams
  """

  alias Farmbot.CeleryScript.Command
  alias Farmbot.Serial.Handler, as: UartHan
  @behaviour Command
  require Logger

  @doc ~s"""
    Reads all mcu_params
      args: %{},
      body: []
  """
  @spec run(%{}, []) :: no_return
  def run(%{}, []), do: do_thing()

  defp do_thing(tries \\ 0)

  defp do_thing(tries) when tries > 5 do
    Logger.info ">> Could not read params. Firmware not responding!", type: :warn
    {:error, :to_many_retries}
  end

  defp do_thing(tries) do
    Logger.info ">> read all params try #{tries + 1}"
    UartHan.write "F83"
    results = case UartHan.write("F20") do
      :timeout -> do_thing(tries + 1)
      other -> other
    end

    unless match?({:error, _}, results) do
      Logger.info ">> Read all params", type: :success
    end
  end

end
