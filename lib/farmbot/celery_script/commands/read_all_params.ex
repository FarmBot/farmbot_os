defmodule Farmbot.CeleryScript.Command.ReadAllParams do
  @moduledoc """
    ReadAllParams
  """

  alias Farmbot.CeleryScript.Command
  alias Farmbot.CeleryScript.Ast
  alias Farmbot.Serial.Handler, as: UartHan
  @behaviour Command
  require Logger

  @doc ~s"""
    Reads all mcu_params
      args: %{},
      body: []
  """
  @spec run(%{}, [], Ast.context) :: Ast.context
  def run(%{}, [], context) do
    do_thing(context)
    context
  end

  defp do_thing(context, tries \\ 0)

  defp do_thing(_context, tries) when tries > 5 do
    Logger.info ">> Could not read params. Firmware not responding!", type: :warn
    {:error, :to_many_retries}
  end

  defp do_thing(context, tries) do
    Logger.info ">> read all params try #{tries + 1}"
    UartHan.write context, "F83"
    results = case UartHan.write(context, "F20") do
      :timeout -> do_thing(tries + 1)
      other -> other
    end

    unless match?({:error, _}, results) do
      Logger.info ">> Read all params", type: :success
    end
  end

end
